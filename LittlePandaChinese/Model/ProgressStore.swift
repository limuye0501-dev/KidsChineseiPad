import Combine
import Foundation

/// Stars live on this iPad only. Nothing is uploaded.
@MainActor
final class ProgressStore: ObservableObject {
    @Published private(set) var starsByEpisode: [String: Int] = [:]
    private let defaults: UserDefaults
    private let key = "lpc.episodeStars"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        starsByEpisode = Self.load(defaults, key: key)
    }

    func stars(for episodeID: String) -> Int {
        starsByEpisode[episodeID] ?? 0
    }

    /// Keeps the best score. Replaying a worse round does not erase stars.
    func record(episodeID: String, stars newValue: Int) {
        let clamped = min(3, max(0, newValue))
        let merged = max(starsByEpisode[episodeID] ?? 0, clamped)
        starsByEpisode[episodeID] = merged
        defaults.set(starsByEpisode, forKey: key)
    }

    func reset() {
        starsByEpisode = [:]
        defaults.removeObject(forKey: key)
    }

    private static func load(_ defaults: UserDefaults, key: String) -> [String: Int] {
        guard let raw = defaults.dictionary(forKey: key) else { return [:] }
        var out: [String: Int] = [:]
        for (id, value) in raw {
            if let number = value as? NSNumber {
                out[id] = number.intValue
            }
        }
        return out
    }
}
