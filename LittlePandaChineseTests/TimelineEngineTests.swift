import XCTest
@testable import LittlePandaChinese

@MainActor
final class TimelineEngineTests: XCTestCase {
    private func library() throws -> EpisodeLibrary {
        try EpisodeLibrary.load(bundle: Bundle(for: TimelineEngineTests.self))
    }

    private func episode() throws -> Episode {
        let playable = try library().playable
        return try XCTUnwrap(playable.first)
    }

    func testEpisode1Script() async throws {
        let episode = try episode()
        XCTAssertEqual(episode.id, "colors")
        XCTAssertEqual(episode.titleHanzi, "颜色")
        XCTAssertEqual(episode.titleEnglish, "Colors")
        XCTAssertTrue(episode.isFree)
        XCTAssertEqual(TimelineEngine().problems(in: episode), [])

        let questions = episode.beats.filter { $0.role == .question }.map { $0.prompt?.hanzi }
        XCTAssertEqual(questions, Array(repeating: "这是什么颜色？", count: 4))
        let answers = episode.beats.filter { $0.role == .answer }.map { $0.prompt?.hanzi }
        XCTAssertEqual(answers, ["它是红色的！", "它是黄色的！", "它是蓝色的！", "它是绿色的！"])
        XCTAssertEqual(episode.beats.filter { $0.kind == .vocab }.count, 8)
        let colors = episode.beats.filter { $0.kind == .vocab }.map { $0.card?.hanzi }
        XCTAssertEqual(colors, ["红", "黄", "蓝", "绿", "红", "黄", "蓝", "绿"])

        let quizzes = episode.beats.filter { $0.kind == .quiz }
        XCTAssertEqual(quizzes.count, 3)
        XCTAssertTrue(quizzes.allSatisfy { $0.quizPause == 3 })
        XCTAssertEqual(quizzes.map(\.twist), [false, true, false])
        XCTAssertEqual(quizzes[1].prompt?.hanzi, "是蓝色的吗？")
        XCTAssertEqual(quizzes[1].correction?.hanzi, "不是。它是黄色的！")
    }

    func testNominalTimelineIsTwoAndAHalfMinutes() async throws {
        let episode = try episode()
        let timeline = TimelineEngine().compile(episode)
        XCTAssertEqual(timeline.cues.count, episode.beats.count)
        XCTAssertEqual(timeline.duration, episode.beats.reduce(0) { $0 + $1.duration }, accuracy: 0.001)
        XCTAssertEqual(timeline.duration, 149, accuracy: 0.001)
        var cursor: TimeInterval = 0
        for cue in timeline.cues {
            XCTAssertEqual(cue.start, cursor, accuracy: 0.001)
            XCTAssertGreaterThan(cue.duration, 0)
            cursor += cue.duration
        }
        let engine = TimelineEngine()
        XCTAssertEqual(engine.cue(at: 0, in: timeline)?.beatID, "title")
        let second = timeline.cues[1]
        XCTAssertEqual(engine.cue(at: second.start, in: timeline)?.beatID, second.beatID)
        XCTAssertEqual(engine.cue(at: second.start - 0.001, in: timeline)?.beatID, timeline.cues[0].beatID)
        XCTAssertEqual(engine.cue(at: timeline.duration, in: timeline)?.beatID, episode.beats.last?.id)
    }

    func testQuizGrading() async throws {
        let episode = try episode()
        let engine = TimelineEngine()
        let red = try XCTUnwrap(episode.beats.first { $0.id == "quiz_red" })
        let correct = engine.grade(beat: red, choiceID: "red")
        XCTAssertEqual(correct?.childWasCorrect, true)
        XCTAssertEqual(correct?.showCheck, true)
        XCTAssertEqual(correct?.showCross, false)
        XCTAssertEqual(correct?.line.hanzi, "它是红色的！")

        let wrong = engine.grade(beat: red, choiceID: "blue")
        XCTAssertEqual(wrong?.childWasCorrect, false)
        XCTAssertEqual(wrong?.showCross, true)
        XCTAssertEqual(wrong?.line.hanzi, "它是红色的！")

        let reveal = engine.grade(beat: red, choiceID: nil)
        XCTAssertEqual(reveal?.childWasCorrect, false)
        XCTAssertEqual(reveal?.showCheck, true)
        XCTAssertEqual(reveal?.showCross, false)

        let twist = try XCTUnwrap(episode.beats.first { $0.id == "quiz_twist" })
        let trap = engine.grade(beat: twist, choiceID: "blue")
        XCTAssertEqual(trap?.showCross, true)
        XCTAssertEqual(trap?.line.hanzi, "不是。它是黄色的！")
        let saved = engine.grade(beat: twist, choiceID: "yellow")
        XCTAssertEqual(saved?.childWasCorrect, true)
        XCTAssertEqual(saved?.showCross, false)
        let timeout = engine.grade(beat: twist, choiceID: nil)
        XCTAssertEqual(timeout?.showCross, true)
        XCTAssertEqual(timeout?.childWasCorrect, false)
        XCTAssertEqual(timeout?.line.spoken, "不是。它是黄色的！")
    }

    func testPlaythroughAllCorrectEarnsThreeStars() async throws {
        let store = makeStore()
        let session = EpisodeSession(episode: try episode(), progress: store)
        walk(session, choice: { beat in beat.choices.first { $0.correct }?.id })
        XCTAssertEqual(session.phase, .finished)
        XCTAssertEqual(session.stars, 3)
        XCTAssertEqual(store.stars(for: "colors"), 3)
    }

    func testTwistTimeoutLeavesTwoStarsAndDoesNotEraseABetterScore() async throws {
        let store = makeStore()
        let first = EpisodeSession(episode: try episode(), progress: store)
        walk(first, choice: { beat in beat.choices.first { $0.correct }?.id })
        XCTAssertEqual(store.stars(for: "colors"), 3)

        let second = EpisodeSession(episode: try episode(), progress: store)
        walk(second) { beat in
            beat.twist ? nil : beat.choices.first { $0.correct }?.id
        }
        XCTAssertEqual(second.stars, 2)
        XCTAssertEqual(store.stars(for: "colors"), 3)
    }

    func testEnginePlaysAScriptThatIsNotEpisode1() async {
        let store = makeStore()
        let episode = Episode(
            id: "hello",
            number: 9,
            titleHanzi: "你好",
            titlePinyin: "Nǐ hǎo",
            titleEnglish: "Hello",
            isFree: false,
            beats: [
                Beat(
                    id: "only",
                    kind: .dialogue,
                    role: .intro,
                    duration: 3,
                    prompt: SpeechLine(hanzi: "你好", pinyin: "Nǐ hǎo", english: "Hello", spoken: "你好", speaker: .panda)
                )
            ]
        )
        let timeline = TimelineEngine().compile(episode)
        XCTAssertEqual(timeline.cues.count, 1)
        XCTAssertEqual(TimelineEngine().problems(in: episode), [])
        let session = EpisodeSession(episode: episode, progress: store)
        session.begin()
        session.markBeatFinished()
        XCTAssertEqual(session.phase, .finished)
        XCTAssertEqual(store.stars(for: "hello"), 1)
    }

    private func walk(_ session: EpisodeSession, choice: (Beat) -> String?) {
        session.begin()
        var steps = 0
        while session.phase != .finished {
            steps += 1
            XCTAssertLessThan(steps, 80)
            switch session.phase {
            case .performing:
                if session.beat?.kind == .quiz {
                    session.markPromptFinished()
                } else {
                    session.markBeatFinished()
                }
            case .awaitingAnswer:
                session.submit(choiceID: session.beat.flatMap(choice))
            case .showingFeedback:
                session.markBeatFinished()
            case .idle, .finished:
                XCTFail("unexpected \(session.phase)")
                return
            }
        }
    }

    private func makeStore() -> ProgressStore {
        let name = "lpc.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return ProgressStore(defaults: defaults)
    }
}
