import AVFoundation
import Combine
import Foundation

/// Swap the on-device voice for finished recordings without touching the player.
///
/// Drop files into `LittlePandaChinese/Resources/VoiceOver/` (they are copied to the
/// bundle root):
/// - `vo_<beatID>.m4a` speaks that beat's line. Example: `vo_q_red.m4a`.
/// - `vo_<beatID>_feedback.m4a` speaks a quiz reveal. Example: `vo_quiz_twist_feedback.m4a`.
///
/// Background music: `music_ukulele_loop.m4a` anywhere in the app resources replaces
/// the synthesized ukulele/xylophone loop. Until those files exist, speech is
/// `AVSpeechSynthesizer` with the zh-CN voice, and music/SFX are generated in code.
@MainActor
protocol AudioProvider: AnyObject {
    var speechRate: Float { get set }
    var musicEnabled: Bool { get set }
    func prepare()
    func speak(clipID: String, line: SpeechLine) async
    func playEffect(_ effect: SoundEffect)
    func stopAll()
}

@MainActor
final class AppAudio: ObservableObject, AudioProvider {
    var speechRate: Float = 0.42
    var musicEnabled: Bool = true {
        didSet { applyMusic() }
    }

    private let speaker = SpeechSpeaker()
    private var musicPlayer: AVAudioPlayer?
    private var voicePlayer: AVAudioPlayer?
    private var effectPlayers: [AVAudioPlayer] = []
    private var effectCache: [SoundEffect: Data] = [:]
    private var prepared = false

    func prepare() {
        if !prepared {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers])
            try? AVAudioSession.sharedInstance().setActive(true)
            prepared = true
        }
        if musicPlayer == nil {
            if let url = Bundle.main.url(forResource: "music_ukulele_loop", withExtension: "m4a") {
                musicPlayer = try? AVAudioPlayer(contentsOf: url)
            } else {
                musicPlayer = try? AVAudioPlayer(data: Synth.musicLoop())
            }
            musicPlayer?.numberOfLoops = -1
            musicPlayer?.volume = 0.16
            musicPlayer?.prepareToPlay()
        }
        applyMusic()
    }

    func speak(clipID: String, line: SpeechLine) async {
        let previous = musicPlayer?.volume ?? 0
        if musicEnabled { musicPlayer?.volume = 0.04 }
        defer { musicPlayer?.volume = musicEnabled ? 0.16 : 0 }
        if let url = bundledVoice(clipID) {
            await playFile(url)
            return
        }
        await speaker.speak(line.spoken, rate: speechRate, pitch: pitch(for: line.speaker))
    }

    func playEffect(_ effect: SoundEffect) {
        let data = effectCache[effect] ?? {
            let made = Synth.effect(effect)
            effectCache[effect] = made
            return made
        }()
        guard let player = try? AVAudioPlayer(data: data) else { return }
        player.volume = effect == .splash ? 0.55 : 0.7
        effectPlayers.removeAll { !$0.isPlaying }
        effectPlayers.append(player)
        player.play()
    }

    func stopAll() {
        speaker.stop()
        voicePlayer?.stop()
        musicPlayer?.stop()
        effectPlayers.forEach { $0.stop() }
        effectPlayers.removeAll()
    }

    private func applyMusic() {
        guard let musicPlayer else { return }
        if musicEnabled {
            if !musicPlayer.isPlaying { musicPlayer.play() }
            musicPlayer.volume = 0.16
        } else {
            musicPlayer.pause()
        }
    }

    private func bundledVoice(_ clipID: String) -> URL? {
        for ext in ["m4a", "caf", "wav"] {
            if let url = Bundle.main.url(forResource: "vo_\(clipID)", withExtension: ext) {
                return url
            }
        }
        return nil
    }

    private func playFile(_ url: URL) async {
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        voicePlayer = player
        player.play()
        let ns = UInt64(player.duration * 1_000_000_000)
        try? await Task.sleep(nanoseconds: max(ns, 200_000_000))
    }

    private func pitch(for speaker: Speaker) -> Float {
        switch speaker {
        case .panda: return 1.18
        case .animal: return 1.42
        case .narrator: return 1.05
        }
    }
}

final class SpeechSpeaker: NSObject, AVSpeechSynthesizerDelegate {
    private let synth = AVSpeechSynthesizer()
    private var continuation: CheckedContinuation<Void, Never>?
    private let lock = NSLock()

    override init() {
        super.init()
        synth.delegate = self
    }

    func speak(_ text: String, rate: Float, pitch: Float) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return }
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            lock.lock()
            continuation = cont
            lock.unlock()
            let utterance = AVSpeechUtterance(string: trimmed)
            utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
            utterance.rate = rate
            utterance.pitchMultiplier = pitch
            utterance.preUtteranceDelay = 0.05
            synth.speak(utterance)
            Task {
                try? await Task.sleep(nanoseconds: 12_000_000_000)
                self.finish()
            }
        }
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
        finish()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        finish()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        finish()
    }

    private func finish() {
        lock.lock()
        let cont = continuation
        continuation = nil
        lock.unlock()
        cont?.resume()
    }
}

enum Synth {
    private static let lcg: UInt64 = 6_364_136_223_846_793_005

    static func musicLoop() -> Data {
        let rate = 22_050.0
        let seconds = 8.0
        var samples = [Float](repeating: 0, count: Int(seconds * rate))
        // Ukulele-ish strums on a pentatonic, with a xylophone ping between them.
        let strums: [(Double, [Double])] = [
            (0.0, [261.63, 329.63, 392.00]),
            (2.0, [293.66, 392.00, 440.00]),
            (4.0, [329.63, 392.00, 523.25]),
            (6.0, [261.63, 329.63, 523.25])
        ]
        for (time, chord) in strums {
            for (index, freq) in chord.enumerated() {
                pluck(freq: freq, start: time + Double(index) * 0.018, seconds: 1.7, amp: 0.16, rate: rate, into: &samples)
            }
        }
        let pings: [(Double, Double)] = [
            (0.55, 523.25), (1.15, 659.25), (1.7, 783.99),
            (2.55, 587.33), (3.2, 659.25), (3.7, 523.25),
            (4.55, 783.99), (5.15, 659.25), (5.7, 523.25),
            (6.55, 440.00), (7.15, 523.25), (7.6, 659.25)
        ]
        for (time, freq) in pings {
            pluck(freq: freq, start: time, seconds: 0.7, amp: 0.11, rate: rate, into: &samples, brightness: 0.15)
        }
        return wav(samples, rate: Int(rate))
    }

    static func effect(_ effect: SoundEffect) -> Data {
        let rate = 22_050.0
        switch effect {
        case .pop:
            return wav(burst(rate: rate, seconds: 0.09, freq: 620, noise: 0.45), rate: Int(rate))
        case .boing:
            return wav(sweep(rate: rate, seconds: 0.22, from: 220, to: 640), rate: Int(rate))
        case .splash:
            return wav(noise(rate: rate, seconds: 0.38, amp: 0.45), rate: Int(rate))
        case .ding:
            var samples = [Float](repeating: 0, count: Int(0.55 * rate))
            pluck(freq: 1318.5, start: 0, seconds: 0.55, amp: 0.28, rate: rate, into: &samples, brightness: 0.2)
            pluck(freq: 1975.5, start: 0, seconds: 0.4, amp: 0.12, rate: rate, into: &samples, brightness: 0.05)
            return wav(samples, rate: Int(rate))
        case .wrong:
            return wav(burst(rate: rate, seconds: 0.28, freq: 196, noise: 0.05), rate: Int(rate))
        }
    }

    private static func pluck(freq: Double, start: Double, seconds: Double, amp: Double, rate: Double, into samples: inout [Float], brightness: Double = 0.35) {
        let i0 = max(0, Int(start * rate))
        let i1 = min(samples.count, Int((start + seconds) * rate))
        guard i0 < i1 else { return }
        for i in i0..<i1 {
            let t = Double(i) / rate - start
            let env = exp(-3.4 * t)
            let tone = sin(2 * Double.pi * freq * t) + brightness * sin(2 * Double.pi * freq * 2 * t)
            samples[i] += Float(tone * env * amp)
        }
    }

    private static func burst(rate: Double, seconds: Double, freq: Double, noise: Double) -> [Float] {
        var samples = [Float](repeating: 0, count: Int(seconds * rate))
        pluck(freq: freq, start: 0, seconds: seconds, amp: 0.55, rate: rate, into: &samples, brightness: 0.4)
        if noise > 0 {
            var state: UInt64 = 0x12345678
            for i in samples.indices {
                state = state &* Self.lcg &+ 1
                let n = Float(state % 10_000) / 5_000 - 1
                let env = exp(-18 * Double(i) / rate)
                samples[i] += n * Float(noise * env)
            }
        }
        return samples
    }

    private static func sweep(rate: Double, seconds: Double, from: Double, to: Double) -> [Float] {
        let count = Int(seconds * rate)
        var samples = [Float](repeating: 0, count: count)
        var phase = 0.0
        for i in 0..<count {
            let t = Double(i) / rate
            let freq = from + (to - from) * (t / seconds)
            phase += 2 * Double.pi * freq / rate
            let env = sin(Double.pi * t / seconds)
            samples[i] = Float(sin(phase) * env * 0.45)
        }
        return samples
    }

    private static func noise(rate: Double, seconds: Double, amp: Double) -> [Float] {
        let count = Int(seconds * rate)
        var samples = [Float](repeating: 0, count: count)
        var state: UInt64 = 0xabcdef
        var last: Float = 0
        for i in 0..<count {
            state = state &* Self.lcg &+ 1
            let n = Float(state % 10_000) / 5_000 - 1
            last = last * 0.82 + n * 0.18
            let t = Double(i) / rate
            let env = sin(Double.pi * min(1, t / seconds)) * exp(-2.2 * t)
            samples[i] = last * Float(amp * env)
        }
        return samples
    }

    private static func wav(_ samples: [Float], rate: Int) -> Data {
        var pcm = Data(count: samples.count * 2)
        pcm.withUnsafeMutableBytes { raw in
            let dst = raw.bindMemory(to: Int16.self)
            for i in samples.indices {
                let clamped = max(-1, min(1, samples[i]))
                dst[i] = Int16(clamped * 32_767)
            }
        }
        let dataSize = UInt32(pcm.count)
        var header = Data()
        header.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // RIFF
        header.append(le(36 + dataSize))
        header.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // WAVE
        header.append(contentsOf: [0x66, 0x6D, 0x74, 0x20]) // fmt
        header.append(le(UInt32(16)))
        header.append(le(UInt16(1)))
        header.append(le(UInt16(1)))
        header.append(le(UInt32(rate)))
        header.append(le(UInt32(rate * 2)))
        header.append(le(UInt16(2)))
        header.append(le(UInt16(16)))
        header.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // data
        header.append(le(dataSize))
        header.append(pcm)
        return header
    }

    private static func le(_ value: UInt32) -> Data {
        var v = value.littleEndian
        return Data(bytes: &v, count: 4)
    }

    private static func le(_ value: UInt16) -> Data {
        var v = value.littleEndian
        return Data(bytes: &v, count: 2)
    }
}
