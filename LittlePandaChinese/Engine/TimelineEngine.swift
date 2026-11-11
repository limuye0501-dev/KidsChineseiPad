import Foundation

struct TimelineCue: Equatable {
    var beatID: String
    var kind: BeatKind
    var start: TimeInterval
    var duration: TimeInterval
}

struct Timeline: Equatable {
    var cues: [TimelineCue]
    var duration: TimeInterval
}

struct QuizGrade: Equatable {
    /// True only when the child taps the right answer. A timeout reveal is not a star.
    var childWasCorrect: Bool
    var showCheck: Bool
    var showCross: Bool
    var chosenID: String?
    var line: SpeechLine
}

enum StarRating {
    /// Finishing is always one star. Every quiz tapped correctly is three.
    static func stars(quizzes: Int, correctTaps: Int) -> Int {
        guard quizzes > 0 else { return 1 }
        if correctTaps >= quizzes { return 3 }
        if correctTaps >= quizzes - 1 { return 2 }
        return 1
    }
}

struct TimelineEngine {
    /// Nominal clock. Playback waits on speech and on the quiz pause; this timeline
    /// is the script's planned length so a new episode can be checked without the UI.
    func compile(_ episode: Episode) -> Timeline {
        var cursor: TimeInterval = 0
        var cues: [TimelineCue] = []
        for beat in episode.beats {
            cues.append(TimelineCue(beatID: beat.id, kind: beat.kind, start: cursor, duration: beat.duration))
            cursor += beat.duration
        }
        return Timeline(cues: cues, duration: cursor)
    }

    func cue(at time: TimeInterval, in timeline: Timeline) -> TimelineCue? {
        if time >= timeline.duration { return timeline.cues.last }
        return timeline.cues.last { $0.start <= time }
    }

    func grade(beat: Beat, choiceID: String?) -> QuizGrade? {
        guard beat.kind == .quiz, let answer = beat.answer else { return nil }
        let correction = beat.correction ?? answer
        if let choiceID, let choice = beat.choices.first(where: { $0.id == choiceID }) {
            if choice.correct {
                return QuizGrade(childWasCorrect: true, showCheck: true, showCross: false, chosenID: choiceID, line: answer)
            }
            return QuizGrade(childWasCorrect: false, showCheck: false, showCross: true, chosenID: choiceID, line: correction)
        }
        if beat.twist {
            return QuizGrade(childWasCorrect: false, showCheck: false, showCross: true, chosenID: nil, line: correction)
        }
        return QuizGrade(childWasCorrect: false, showCheck: true, showCross: false, chosenID: nil, line: answer)
    }

    func problems(in episode: Episode) -> [String] {
        var issues: [String] = []
        if episode.beats.isEmpty { issues.append("no beats") }
        var seen = Set<String>()
        for beat in episode.beats {
            if !seen.insert(beat.id).inserted { issues.append("duplicate \(beat.id)") }
            if beat.id.range(of: "^[a-z0-9_]+$", options: .regularExpression) == nil {
                issues.append("unsafe id \(beat.id)")
            }
            if beat.duration <= 0 { issues.append("\(beat.id) duration") }
            if beat.kind == .quiz {
                if abs(beat.quizPause - 3) > 0.001 { issues.append("\(beat.id) pause") }
                if beat.choices.filter(\.correct).count != 1 { issues.append("\(beat.id) choices") }
                if beat.answer == nil { issues.append("\(beat.id) answer") }
            }
            if beat.kind == .vocab, beat.card == nil { issues.append("\(beat.id) card") }
            for line in [beat.prompt, beat.answer, beat.correction].compactMap({ $0 }) {
                if line.spoken.contains(where: { $0.isASCII && $0.isLetter }) {
                    issues.append("\(beat.id) spoken latin")
                }
                if line.hanzi.isEmpty || line.english.isEmpty || line.pinyin.isEmpty {
                    issues.append("\(beat.id) empty line")
                }
            }
        }
        return issues
    }
}
