import Combine
import Foundation

@MainActor
final class AppSettings: ObservableObject {
    @Published var musicEnabled: Bool {
        didSet { defaults.set(musicEnabled, forKey: musicKey) }
    }
    @Published var speechRate: Double {
        didSet { defaults.set(speechRate, forKey: rateKey) }
    }

    private let defaults: UserDefaults
    private let musicKey = "lpc.musicEnabled"
    private let rateKey = "lpc.speechRate"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.object(forKey: musicKey) == nil {
            musicEnabled = true
        } else {
            musicEnabled = defaults.bool(forKey: musicKey)
        }
        let stored = defaults.double(forKey: rateKey)
        speechRate = stored == 0 ? 0.42 : min(0.55, max(0.32, stored))
    }
}
