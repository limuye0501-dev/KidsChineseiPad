import XCTest
@testable import LittlePandaChinese

@MainActor
final class ProgressAndAccessTests: XCTestCase {
    func testStarsKeepTheBestScore() async {
        let name = "lpc.progress.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        let store = ProgressStore(defaults: defaults)
        XCTAssertEqual(store.stars(for: "colors"), 0)
        store.record(episodeID: "colors", stars: 2)
        store.record(episodeID: "colors", stars: 1)
        XCTAssertEqual(store.stars(for: "colors"), 2)
        store.record(episodeID: "other", stars: 3)
        XCTAssertEqual(store.stars(for: "colors"), 2)
        let reloaded = ProgressStore(defaults: defaults)
        XCTAssertEqual(reloaded.stars(for: "colors"), 2)
        XCTAssertEqual(reloaded.stars(for: "other"), 3)
        reloaded.reset()
        XCTAssertEqual(ProgressStore(defaults: defaults).stars(for: "colors"), 0)
    }

    func testShelfAccess() async throws {
        let library = try EpisodeLibrary.load(bundle: Bundle(for: ProgressAndAccessTests.self))
        XCTAssertEqual(library.freeThrough, 2)
        XCTAssertEqual(library.shelf.map(\.number), [1, 2, 3, 4, 5])
        for entry in library.shelf {
            XCTAssertEqual(entry.isFree, entry.number <= library.freeThrough)
        }
        XCTAssertEqual(library.playbackAccess(for: library.shelf[0], unlockedAll: false), .play)
        XCTAssertEqual(library.playbackAccess(for: library.shelf[1], unlockedAll: false), .comingSoon)
        XCTAssertEqual(library.playbackAccess(for: library.shelf[1], unlockedAll: true), .comingSoon)
        XCTAssertEqual(library.playbackAccess(for: library.shelf[2], unlockedAll: true), .comingSoon)

        let paid = ShelfEntry(
            id: "animals",
            number: 3,
            titleHanzi: "动物",
            titlePinyin: "Dòngwù",
            titleEnglish: "Animals",
            isFree: false,
            episode: Episode(
                id: "animals",
                number: 3,
                titleHanzi: "动物",
                titlePinyin: "Dòngwù",
                titleEnglish: "Animals",
                isFree: false,
                beats: []
            )
        )
        XCTAssertEqual(library.playbackAccess(for: paid, unlockedAll: false), .needsPurchase)
        XCTAssertEqual(library.playbackAccess(for: paid, unlockedAll: true), .play)
    }

    func testStarFormula() async {
        XCTAssertEqual(StarRating.stars(quizzes: 3, correctTaps: 3), 3)
        XCTAssertEqual(StarRating.stars(quizzes: 3, correctTaps: 2), 2)
        XCTAssertEqual(StarRating.stars(quizzes: 3, correctTaps: 0), 1)
        XCTAssertEqual(StarRating.stars(quizzes: 0, correctTaps: 0), 1)
    }
}
