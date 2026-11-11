import Foundation

enum PlaybackAccess: Equatable {
    case play
    case comingSoon
    case needsPurchase
}

struct ShelfEntry: Identifiable, Equatable {
    var id: String
    var number: Int
    var titleHanzi: String
    var titlePinyin: String
    var titleEnglish: String
    var isFree: Bool
    var episode: Episode?
}

struct EpisodeLibrary: Equatable {
    var freeThrough: Int
    var shelf: [ShelfEntry]

    static let empty = EpisodeLibrary(freeThrough: 2, shelf: [])

    var playable: [Episode] { shelf.compactMap(\.episode) }

    func playbackAccess(for entry: ShelfEntry, unlockedAll: Bool) -> PlaybackAccess {
        guard entry.episode != nil else { return .comingSoon }
        if entry.isFree || unlockedAll { return .play }
        return .needsPurchase
    }

    static func load(bundle: Bundle = .main) throws -> EpisodeLibrary {
        guard let url = resource(named: "catalog", bundle: bundle) else {
            throw LibraryError(message: "Missing catalog.json in the app bundle.")
        }
        let catalog = try JSONDecoder().decode(CatalogFile.self, from: Data(contentsOf: url))
        var shelf: [ShelfEntry] = []
        for item in catalog.shelf {
            if let name = item.episode {
                guard let episodeURL = resource(named: name, bundle: bundle) else {
                    throw LibraryError(message: "Missing \(name).json")
                }
                let episode = try JSONDecoder().decode(Episode.self, from: Data(contentsOf: episodeURL))
                shelf.append(ShelfEntry(
                    id: episode.id,
                    number: episode.number,
                    titleHanzi: episode.titleHanzi,
                    titlePinyin: episode.titlePinyin,
                    titleEnglish: episode.titleEnglish,
                    isFree: episode.isFree,
                    episode: episode
                ))
            } else {
                guard let number = item.number,
                      let hanzi = item.titleHanzi,
                      let pinyin = item.titlePinyin,
                      let english = item.titleEnglish,
                      let free = item.free else {
                    throw LibraryError(message: "A coming-soon shelf card is missing a title.")
                }
                shelf.append(ShelfEntry(
                    id: "soon-\(number)",
                    number: number,
                    titleHanzi: hanzi,
                    titlePinyin: pinyin,
                    titleEnglish: english,
                    isFree: free,
                    episode: nil
                ))
            }
        }
        return EpisodeLibrary(freeThrough: catalog.freeThrough, shelf: shelf)
    }

    private static func resource(named name: String, bundle: Bundle) -> URL? {
        bundle.url(forResource: name, withExtension: "json")
            ?? bundle.url(forResource: name, withExtension: "json", subdirectory: "Episodes")
    }
}

struct LibraryError: Error, Equatable {
    var message: String
}

private struct CatalogFile: Decodable {
    var freeThrough: Int
    var shelf: [Item]

    struct Item: Decodable {
        var episode: String?
        var number: Int?
        var titleHanzi: String?
        var titlePinyin: String?
        var titleEnglish: String?
        var free: Bool?
    }
}
