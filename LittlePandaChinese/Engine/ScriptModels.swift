import Foundation

/// A paper-cut episode is data: add the next one by dropping another JSON script
/// into Resources/Episodes and pointing the shelf at it. The player does not grow.
struct Episode: Identifiable, Equatable, Decodable {
    var id: String
    var number: Int
    var titleHanzi: String
    var titlePinyin: String
    var titleEnglish: String
    var isFree: Bool
    var beats: [Beat]

    enum CodingKeys: String, CodingKey {
        case id, number, titleHanzi, titlePinyin, titleEnglish, beats
        case isFree = "free"
    }
}

struct Beat: Identifiable, Equatable, Decodable {
    var id: String
    var kind: BeatKind
    var role: LineRole
    var duration: TimeInterval
    /// Seconds to keep the card up after speech. Nominal `duration` still feeds the timeline.
    var hold: TimeInterval
    var quizPause: TimeInterval
    var twist: Bool
    var animal: Animal?
    var color: PaintColor?
    var sfx: SoundEffect?
    var prompt: SpeechLine?
    var answer: SpeechLine?
    var correction: SpeechLine?
    var card: VocabCard?
    var choices: [QuizChoice]
    var pandaMessy: Bool
    var showRainbow: Bool
    var cans: CanState

    init(
        id: String,
        kind: BeatKind,
        role: LineRole,
        duration: TimeInterval,
        hold: TimeInterval = 0.9,
        quizPause: TimeInterval = 0,
        twist: Bool = false,
        animal: Animal? = nil,
        color: PaintColor? = nil,
        sfx: SoundEffect? = nil,
        prompt: SpeechLine? = nil,
        answer: SpeechLine? = nil,
        correction: SpeechLine? = nil,
        card: VocabCard? = nil,
        choices: [QuizChoice] = [],
        pandaMessy: Bool = false,
        showRainbow: Bool = false,
        cans: CanState = .hidden
    ) {
        self.id = id
        self.kind = kind
        self.role = role
        self.duration = duration
        self.hold = hold
        self.quizPause = quizPause
        self.twist = twist
        self.animal = animal
        self.color = color
        self.sfx = sfx
        self.prompt = prompt
        self.answer = answer
        self.correction = correction
        self.card = card
        self.choices = choices
        self.pandaMessy = pandaMessy
        self.showRainbow = showRainbow
        self.cans = cans
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        kind = try c.decode(BeatKind.self, forKey: .kind)
        role = try c.decode(LineRole.self, forKey: .role)
        duration = try c.decode(TimeInterval.self, forKey: .duration)
        hold = try c.decodeIfPresent(TimeInterval.self, forKey: .hold) ?? 0.9
        quizPause = try c.decodeIfPresent(TimeInterval.self, forKey: .quizPause) ?? 0
        twist = try c.decodeIfPresent(Bool.self, forKey: .twist) ?? false
        animal = try c.decodeIfPresent(Animal.self, forKey: .animal)
        color = try c.decodeIfPresent(PaintColor.self, forKey: .color)
        sfx = try c.decodeIfPresent(SoundEffect.self, forKey: .sfx)
        prompt = try c.decodeIfPresent(SpeechLine.self, forKey: .prompt)
        answer = try c.decodeIfPresent(SpeechLine.self, forKey: .answer)
        correction = try c.decodeIfPresent(SpeechLine.self, forKey: .correction)
        card = try c.decodeIfPresent(VocabCard.self, forKey: .card)
        choices = try c.decodeIfPresent([QuizChoice].self, forKey: .choices) ?? []
        pandaMessy = try c.decodeIfPresent(Bool.self, forKey: .pandaMessy) ?? false
        showRainbow = try c.decodeIfPresent(Bool.self, forKey: .showRainbow) ?? false
        cans = try c.decodeIfPresent(CanState.self, forKey: .cans) ?? .hidden
    }

    private enum CodingKeys: String, CodingKey {
        case id, kind, role, duration, hold, quizPause, twist, animal, color, sfx
        case prompt, answer, correction, card, choices, pandaMessy, showRainbow, cans
    }
}

enum BeatKind: String, Decodable, Equatable {
    case title, dialogue, vocab, joke, quiz, outro
}

enum LineRole: String, Decodable, Equatable {
    case title, intro, question, answer, drill, vocab, joke, rainbow, yourTurn, quiz, outro
}

enum Animal: String, Decodable, Equatable {
    case crab, duck, bird, frog
}

enum PaintColor: String, Decodable, Equatable {
    case red, yellow, blue, green, rainbow
}

enum SoundEffect: String, Decodable, Equatable {
    case pop, boing, splash, ding, wrong
}

enum CanState: String, Decodable, Equatable {
    case hidden, teeter, fall
}

enum Speaker: String, Decodable, Equatable {
    case panda, animal, narrator
}

struct SpeechLine: Equatable, Decodable {
    var hanzi: String
    var pinyin: String
    var english: String
    /// Spoken Chinese only. On-screen English is never sent to the voice.
    var spoken: String
    var speaker: Speaker

    init(hanzi: String, pinyin: String, english: String, spoken: String, speaker: Speaker = .narrator) {
        self.hanzi = hanzi
        self.pinyin = pinyin
        self.english = english
        self.spoken = spoken
        self.speaker = speaker
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        hanzi = try c.decode(String.self, forKey: .hanzi)
        pinyin = try c.decode(String.self, forKey: .pinyin)
        english = try c.decode(String.self, forKey: .english)
        spoken = try c.decode(String.self, forKey: .spoken)
        speaker = try c.decodeIfPresent(Speaker.self, forKey: .speaker) ?? .narrator
    }

    private enum CodingKeys: String, CodingKey {
        case hanzi, pinyin, english, spoken, speaker
    }
}

struct VocabCard: Equatable, Decodable {
    var hanzi: String
    var pinyin: String
    var english: String
    var color: PaintColor
}

struct QuizChoice: Identifiable, Equatable, Decodable {
    var id: String
    var hanzi: String
    var pinyin: String
    var english: String
    var color: PaintColor
    var correct: Bool
}
