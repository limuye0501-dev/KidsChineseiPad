import Combine
import Foundation

/// Walks a script beat by beat. The SwiftUI player calls `startPlaying`; tests call
/// `begin`, `markPromptFinished`, `submit`, and `markBeatFinished` with no audio.
@MainActor
final class EpisodeSession: ObservableObject {
    let episode: Episode
    private let progress: ProgressStore
    private let engine = TimelineEngine()

    @Published private(set) var index: Int = 0
    @Published private(set) var phase: Phase = .idle
    @Published private(set) var feedback: QuizGrade?
    @Published private(set) var correctTaps: Int = 0

    private var generation = 0
    private var playTask: Task<Void, Never>?
    private var audio: (any AudioProvider)?
    private var answerWait: CheckedContinuation<String?, Never>?
    private var timeoutTask: Task<Void, Never>?

    enum Phase: Equatable {
        case idle
        case performing
        case awaitingAnswer
        case showingFeedback
        case finished
    }

    init(episode: Episode, progress: ProgressStore) {
        self.episode = episode
        self.progress = progress
    }

    var beat: Beat? {
        episode.beats.indices.contains(index) ? episode.beats[index] : nil
    }

    var stars: Int {
        let quizzes = episode.beats.filter { $0.kind == .quiz }.count
        return StarRating.stars(quizzes: quizzes, correctTaps: correctTaps)
    }

    var fraction: Double {
        guard !episode.beats.isEmpty else { return 0 }
        if phase == .finished { return 1 }
        return Double(index) / Double(episode.beats.count)
    }

    func begin() {
        index = 0
        correctTaps = 0
        feedback = nil
        phase = episode.beats.isEmpty ? .finished : .performing
        if phase == .finished {
            progress.record(episodeID: episode.id, stars: stars)
        }
    }

    func markPromptFinished() {
        guard phase == .performing, beat?.kind == .quiz else { return }
        phase = .awaitingAnswer
    }

    func submit(choiceID: String?) {
        guard phase == .awaitingAnswer, let beat else { return }
        guard let grade = engine.grade(beat: beat, choiceID: choiceID) else { return }
        if grade.childWasCorrect { correctTaps += 1 }
        feedback = grade
        phase = .showingFeedback
    }

    func markBeatFinished() {
        guard phase == .performing || phase == .showingFeedback else { return }
        feedback = nil
        if index + 1 >= episode.beats.count {
            phase = .finished
            progress.record(episodeID: episode.id, stars: stars)
        } else {
            index += 1
            phase = .performing
        }
    }

    /// Stable frame for screenshots. Does not speak or start the clock.
    func showPaused(beatID: String) {
        generation += 1
        playTask?.cancel()
        finishWait(with: nil)
        guard let found = episode.beats.firstIndex(where: { $0.id == beatID }) else { return }
        index = found
        feedback = nil
        correctTaps = 0
        phase = episode.beats[found].kind == .quiz ? .awaitingAnswer : .performing
    }

    func startPlaying(audio: any AudioProvider, music: Bool, rate: Float) {
        generation += 1
        let gen = generation
        playTask?.cancel()
        finishWait(with: nil)
        playTask = Task { await self.play(gen: gen, audio: audio, music: music, rate: rate) }
    }

    func stop() {
        generation += 1
        playTask?.cancel()
        finishWait(with: nil)
        audio?.stopAll()
    }

    func choose(_ id: String) {
        guard phase == .awaitingAnswer else { return }
        finishWait(with: id)
    }

    private func play(gen: Int, audio: any AudioProvider, music: Bool, rate: Float) async {
        guard gen == generation else { return }
        self.audio = audio
        audio.speechRate = rate
        audio.musicEnabled = music
        audio.prepare()
        begin()
        while gen == generation, !Task.isCancelled {
            guard let beat else { break }
            if beat.kind == .quiz {
                if let sfx = beat.sfx { audio.playEffect(sfx) }
                if let prompt = beat.prompt {
                    await audio.speak(clipID: beat.id, line: prompt)
                }
                guard gen == generation, !Task.isCancelled else { return }
                markPromptFinished()
                let choice = await waitForAnswer(seconds: beat.quizPause)
                guard gen == generation, !Task.isCancelled else { return }
                submit(choiceID: choice)
                if let grade = feedback {
                    audio.playEffect(grade.showCross ? .wrong : .ding)
                    await audio.speak(clipID: beat.id + "_feedback", line: grade.line)
                }
                guard gen == generation, !Task.isCancelled else { return }
                try? await Task.sleep(nanoseconds: 700_000_000)
                guard gen == generation, !Task.isCancelled else { return }
                markBeatFinished()
            } else {
                if let sfx = beat.sfx { audio.playEffect(sfx) }
                if let prompt = beat.prompt {
                    await audio.speak(clipID: beat.id, line: prompt)
                    let hold = UInt64(max(0, beat.hold) * 1_000_000_000)
                    if hold > 0 { try? await Task.sleep(nanoseconds: hold) }
                } else {
                    let ns = UInt64(max(0, beat.duration) * 1_000_000_000)
                    try? await Task.sleep(nanoseconds: ns)
                }
                guard gen == generation, !Task.isCancelled else { return }
                markBeatFinished()
            }
            if phase == .finished { break }
        }
    }

    private func waitForAnswer(seconds: TimeInterval) async -> String? {
        await withCheckedContinuation { (cont: CheckedContinuation<String?, Never>) in
            answerWait = cont
            timeoutTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                self?.finishWait(with: nil)
            }
        }
    }

    private func finishWait(with id: String?) {
        timeoutTask?.cancel()
        timeoutTask = nil
        guard let cont = answerWait else { return }
        answerWait = nil
        cont.resume(returning: id)
    }
}
