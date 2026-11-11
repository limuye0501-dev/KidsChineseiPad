import SwiftUI

struct PandaView: View {
    var messy: Bool
    var waving: Bool

    var body: some View {
        ZStack {
            Circle().fill(Theme.ink).frame(width: 50, height: 50).offset(x: -48, y: -62)
            Circle().fill(Theme.ink).frame(width: 50, height: 50).offset(x: 48, y: -62)
            Ellipse()
                .fill(Color.white)
                .overlay(Ellipse().stroke(Theme.ink, lineWidth: 4))
                .frame(width: 120, height: 102)
                .offset(y: 82)
            Ellipse().fill(Theme.ink).frame(width: 34, height: 20).offset(x: -50, y: 74)
            Ellipse().fill(Theme.ink).frame(width: 34, height: 20).offset(x: 50, y: 74)
            Circle()
                .fill(Color.white)
                .overlay(Circle().stroke(Theme.ink, lineWidth: 4))
                .frame(width: 132, height: 132)
            Ellipse().fill(Theme.ink).frame(width: 40, height: 32).rotationEffect(.degrees(-16)).offset(x: -26, y: -2)
            Ellipse().fill(Theme.ink).frame(width: 40, height: 32).rotationEffect(.degrees(16)).offset(x: 26, y: -2)
            Circle().fill(Color.white).frame(width: 13, height: 13).offset(x: -24, y: -6)
            Circle().fill(Color.white).frame(width: 13, height: 13).offset(x: 28, y: -6)
            Ellipse().fill(Theme.ink).frame(width: 18, height: 12).offset(y: 20)
            Capsule().fill(Theme.ink).frame(width: 26, height: 6).offset(y: 36)
            Circle().fill(Theme.blush.opacity(0.9)).frame(width: 16, height: 16).offset(x: -40, y: 24)
            Circle().fill(Theme.blush.opacity(0.9)).frame(width: 16, height: 16).offset(x: 40, y: 24)
            if messy {
                Circle().fill(Theme.red).frame(width: 22, height: 22).offset(x: 34, y: 78)
                Circle().fill(Theme.yellow).frame(width: 18, height: 18).offset(x: -30, y: 96)
                Circle().fill(Theme.blue).frame(width: 16, height: 16).offset(x: 8, y: 48)
                Circle().fill(Theme.green).frame(width: 14, height: 14).offset(x: -16, y: 60)
            }
        }
        .frame(width: 190, height: 240)
        .modifier(Wiggle(active: waving))
        .modifier(CutShadow())
    }
}

struct AnimalCutout: View {
    var animal: Animal
    var color: PaintColor?

    var body: some View {
        Group {
            switch animal {
            case .crab: CrabView()
            case .duck: DuckView()
            case .bird: BirdView()
            case .frog: FrogView()
            }
        }
        .accessibilityLabel(color?.englishName ?? animal.rawValue)
    }
}

struct CrabView: View {
    var body: some View {
        ZStack {
            Capsule().fill(Theme.red).frame(width: 28, height: 54).rotationEffect(.degrees(-40)).offset(x: -78, y: 8)
            Capsule().fill(Theme.red).frame(width: 28, height: 54).rotationEffect(.degrees(40)).offset(x: 78, y: 8)
            Circle().stroke(Theme.ink, lineWidth: 4).background(Circle().fill(Theme.red)).frame(width: 36, height: 36).offset(x: -92, y: -18)
            Circle().stroke(Theme.ink, lineWidth: 4).background(Circle().fill(Theme.red)).frame(width: 36, height: 36).offset(x: 92, y: -18)
            Ellipse()
                .fill(Theme.red)
                .overlay(Ellipse().stroke(Theme.ink, lineWidth: 4))
                .frame(width: 150, height: 100)
            Circle().fill(Theme.ink).frame(width: 10, height: 10).offset(x: -28, y: -8)
            Circle().fill(Theme.ink).frame(width: 10, height: 10).offset(x: 28, y: -8)
            Capsule().fill(Theme.ink).frame(width: 8, height: 22).offset(x: -28, y: -28)
            Capsule().fill(Theme.ink).frame(width: 8, height: 22).offset(x: 28, y: -28)
            Circle().fill(Color.white).frame(width: 16, height: 16).offset(x: -28, y: -40)
            Circle().fill(Color.white).frame(width: 16, height: 16).offset(x: 28, y: -40)
            Circle().fill(Theme.ink).frame(width: 7, height: 7).offset(x: -28, y: -40)
            Circle().fill(Theme.ink).frame(width: 7, height: 7).offset(x: 28, y: -40)
        }
        .frame(width: 230, height: 170)
        .rotationEffect(.degrees(-3))
        .modifier(CutShadow())
    }
}

struct DuckView: View {
    var body: some View {
        ZStack {
            Ellipse()
                .fill(Theme.yellow)
                .overlay(Ellipse().stroke(Theme.ink, lineWidth: 4))
                .frame(width: 150, height: 100)
                .offset(y: 36)
            Ellipse().fill(Color(red: 0.98, green: 0.85, blue: 0.35)).frame(width: 70, height: 28).offset(y: 28).rotationEffect(.degrees(-8))
            Circle()
                .fill(Theme.yellow)
                .overlay(Circle().stroke(Theme.ink, lineWidth: 4))
                .frame(width: 84, height: 84)
                .offset(x: 36, y: -24)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: 0.93, green: 0.45, blue: 0.12))
                .frame(width: 36, height: 16)
                .offset(x: 78, y: -16)
            Circle().fill(Theme.ink).frame(width: 8, height: 8).offset(x: 48, y: -36)
            Ellipse().fill(Color(red: 0.93, green: 0.45, blue: 0.12)).frame(width: 22, height: 10).offset(x: -10, y: 78)
        }
        .frame(width: 220, height: 190)
        .rotationEffect(.degrees(3))
        .modifier(CutShadow())
    }
}

struct BirdView: View {
    var body: some View {
        ZStack {
            Ellipse().fill(Theme.blue).frame(width: 70, height: 28).rotationEffect(.degrees(20)).offset(x: -70, y: 10)
            Ellipse()
                .fill(Theme.blue)
                .overlay(Ellipse().stroke(Theme.ink, lineWidth: 4))
                .frame(width: 120, height: 86)
                .offset(x: -10, y: 16)
            Circle()
                .fill(Theme.blue)
                .overlay(Circle().stroke(Theme.ink, lineWidth: 4))
                .frame(width: 72, height: 72)
                .offset(x: 48, y: -20)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(red: 0.95, green: 0.72, blue: 0.2))
                .frame(width: 28, height: 12)
                .offset(x: 86, y: -12)
            Circle().fill(Theme.ink).frame(width: 8, height: 8).offset(x: 58, y: -30)
            Capsule().fill(Theme.blue).frame(width: 16, height: 28).offset(x: 40, y: -52)
                .overlay(Capsule().stroke(Theme.ink, lineWidth: 3).frame(width: 16, height: 28).offset(x: 40, y: -52))
        }
        .frame(width: 210, height: 170)
        .rotationEffect(.degrees(-4))
        .modifier(CutShadow())
    }
}

struct FrogView: View {
    var body: some View {
        ZStack {
            Ellipse()
                .fill(Theme.green)
                .overlay(Ellipse().stroke(Theme.ink, lineWidth: 4))
                .frame(width: 160, height: 110)
                .offset(y: 16)
            Ellipse().fill(Color(red: 0.75, green: 0.9, blue: 0.55)).frame(width: 80, height: 48).offset(y: 28)
            Circle().fill(Color.white).overlay(Circle().stroke(Theme.ink, lineWidth: 4)).frame(width: 36, height: 36).offset(x: -36, y: -36)
            Circle().fill(Color.white).overlay(Circle().stroke(Theme.ink, lineWidth: 4)).frame(width: 36, height: 36).offset(x: 36, y: -36)
            Circle().fill(Theme.ink).frame(width: 14, height: 14).offset(x: -36, y: -36)
            Circle().fill(Theme.ink).frame(width: 14, height: 14).offset(x: 36, y: -36)
            Capsule().fill(Theme.ink).frame(width: 28, height: 6).offset(y: 8)
        }
        .frame(width: 200, height: 170)
        .rotationEffect(.degrees(2))
        .modifier(CutShadow())
    }
}

struct PaintCans: View {
    var fallen: Bool

    var body: some View {
        HStack(spacing: 18) {
            can(.red, tilt: fallen ? 28 : -8)
            can(.yellow, tilt: fallen ? -18 : 6)
            can(.blue, tilt: fallen ? 16 : -4)
        }
        .offset(y: fallen ? 150 : 0)
        .animation(.easeIn(duration: 0.7), value: fallen)
    }

    private func can(_ color: PaintColor, tilt: Double) -> some View {
        ZStack {
            Capsule().stroke(Theme.ink, lineWidth: 4).frame(width: 28, height: 16).offset(y: -32)
            RoundedRectangle(cornerRadius: 8)
                .fill(color.color)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.ink, lineWidth: 4))
                .frame(width: 46, height: 58)
            RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.85)).frame(width: 28, height: 10).offset(y: -8)
        }
        .frame(width: 54, height: 90)
        .rotationEffect(.degrees(tilt))
        .modifier(CutShadow())
    }
}

struct RainbowArc: View {
    var body: some View {
        ZStack {
            ForEach(Array(bands.enumerated()), id: \.offset) { index, color in
                Circle()
                    .trim(from: 0.02, to: 0.48)
                    .stroke(Theme.ink, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 280 - CGFloat(index) * 32, height: 280 - CGFloat(index) * 32)
                Circle()
                    .trim(from: 0.02, to: 0.48)
                    .stroke(color, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .frame(width: 280 - CGFloat(index) * 32, height: 280 - CGFloat(index) * 32)
            }
        }
        .rotationEffect(.degrees(180))
        .modifier(CutShadow())
    }

    private var bands: [Color] {
        [Theme.red, Color(red: 0.95, green: 0.55, blue: 0.18), Theme.yellow, Theme.green, Theme.blue]
    }
}

struct VocabCardView: View {
    var card: VocabCard
    var body: some View {
        VStack(spacing: 6) {
            Text(card.hanzi)
                .font(.system(size: 120, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.ink(on: card.color))
                .minimumScaleFactor(0.4)
            Text(card.pinyin)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink(on: card.color).opacity(0.9))
            Text(card.english)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.ink(on: card.color).opacity(0.8))
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(card.color.color)
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(Theme.ink, lineWidth: 4))
        )
        .modifier(CutShadow())
    }
}

struct TitleCardView: View {
    var episode: Episode
    var body: some View {
        VStack(spacing: 8) {
            Text("Episode \(episode.number)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.7))
            Text(episode.titleHanzi)
                .font(.system(size: 108, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.ink)
                .minimumScaleFactor(0.5)
            Text(episode.titlePinyin)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.red)
            Text(episode.titleEnglish)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.75))
        }
        .padding(36)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(Theme.card)
                .overlay(RoundedRectangle(cornerRadius: 32).stroke(Theme.ink, lineWidth: 4))
        )
        .modifier(CutShadow())
    }
}

private struct Wiggle: ViewModifier {
    var active: Bool
    @State private var flipped = false

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(active ? (flipped ? 5 : -4) : -2))
            .onAppear { spin() }
            .onChange(of: active) { _, _ in spin() }
    }

    private func spin() {
        guard active else { return }
        withAnimation(.easeInOut(duration: 0.48).repeatForever(autoreverses: true)) {
            flipped = true
        }
    }
}

extension PaintColor {
    var englishName: String {
        switch self {
        case .red: return "red"
        case .yellow: return "yellow"
        case .blue: return "blue"
        case .green: return "green"
        case .rainbow: return "rainbow"
        }
    }
}
