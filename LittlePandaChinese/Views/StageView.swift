import SwiftUI

struct StageView: View {
    let episode: Episode
    let beat: Beat
    let phase: EpisodeSession.Phase
    let feedback: QuizGrade?
    let onChoose: (String) -> Void

    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height
            ZStack {
                PaperBackground(tint: Theme.wash(beat.color))
                PaintSplashView(token: beat.cans == .fall ? 1 : 0)
                    .allowsHitTesting(false)
                if beat.showRainbow {
                    RainbowArc()
                        .frame(width: height * 0.42, height: height * 0.42)
                        .position(x: geo.size.width * 0.66, y: height * 0.40)
                        .transition(.scale)
                }
                HStack(alignment: .center, spacing: 12) {
                    PandaView(messy: beat.pandaMessy, waving: beat.role == .title || beat.role == .outro)
                        .scaleEffect(height < 500 ? 0.62 : 0.92)
                        .frame(maxWidth: geo.size.width * 0.34)
                    Spacer(minLength: 0)
                    rightSide(height: height)
                        .frame(maxWidth: geo.size.width * 0.48)
                }
                .padding(.horizontal, max(24, geo.size.width * 0.04))
                .padding(.bottom, height * 0.18)

                if beat.cans != .hidden {
                    PaintCans(fallen: beat.cans == .fall)
                        .position(x: geo.size.width * 0.30, y: height * 0.16)
                }

                VStack(spacing: 12) {
                    Spacer()
                    if beat.cans == .fall && beat.prompt == nil {
                        caption(SpeechLine(hanzi: "哗啦！", pinyin: "Huālā!", english: "Splash!", spoken: "哗啦！", speaker: .narrator), height: height)
                    }
                    if let line = captionLine {
                        caption(line, height: height)
                    }
                    if beat.kind == .quiz {
                        choices(height: height)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 18)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: beat.id)
    }

    @ViewBuilder
    private func rightSide(height: CGFloat) -> some View {
        if beat.role == .title {
            TitleCardView(episode: episode)
                .modifier(PopIn(token: beat.id))
        } else if let card = beat.card {
            VocabCardView(card: card)
                .modifier(PopIn(token: beat.id))
        } else if let animal = beat.animal {
            AnimalCutout(animal: animal, color: beat.color)
                .scaleEffect(height < 500 ? 0.72 : 1)
                .modifier(SlideIn(token: beat.id + animal.rawValue))
        } else if beat.showRainbow {
            VStack(spacing: 4) {
                Text("彩虹")
                    .font(.system(size: min(92, height * 0.16), weight: .heavy, design: .rounded))
                Text("cǎihóng")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.red)
                Text("rainbow")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.7))
            }
            .foregroundStyle(Theme.ink)
            .modifier(PopIn(token: beat.id))
        } else {
            Color.clear.frame(height: 20)
        }
    }

    private var captionLine: SpeechLine? {
        if beat.role == .title || beat.role == .vocab { return nil }
        if phase == .showingFeedback, let feedback { return feedback.line }
        if beat.role == .rainbow { return nil }
        return beat.prompt
    }

    private func caption(_ line: SpeechLine, height: CGFloat) -> some View {
        VStack(spacing: 2) {
            Text(line.hanzi)
                .font(.system(size: min(54, height * 0.085), weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.ink)
                .minimumScaleFactor(0.5)
            Text(line.pinyin)
                .font(.system(size: min(26, height * 0.04), weight: .bold, design: .rounded))
                .foregroundStyle(Theme.red)
            Text(line.english)
                .font(.system(size: min(20, height * 0.032), weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.68))
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 22)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Theme.card.opacity(0.94))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.ink, lineWidth: 3))
        )
        .modifier(CutShadow())
    }

    private func choices(height: CGFloat) -> some View {
        HStack(spacing: max(12, height * 0.03)) {
            ForEach(beat.choices) { choice in
                Button {
                    onChoose(choice.id)
                } label: {
                    ZStack {
                        Circle()
                            .fill(choice.color.color)
                            .overlay(Circle().stroke(Theme.ink, lineWidth: 4))
                        VStack(spacing: 0) {
                            Text(choice.hanzi)
                                .font(.system(size: min(48, height * 0.08), weight: .heavy, design: .rounded))
                            Text(choice.pinyin)
                                .font(.system(size: min(16, height * 0.028), weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(Theme.ink(on: choice.color))
                        if showsCheck(choice) {
                            stamp(correct: true)
                        } else if showsCross(choice) {
                            stamp(correct: false)
                        }
                    }
                    .frame(width: min(118, height * 0.2), height: min(118, height * 0.2))
                    .modifier(CutShadow())
                }
                .buttonStyle(KidButtonStyle())
                .disabled(phase != .awaitingAnswer)
                .accessibilityLabel("\(choice.hanzi) \(choice.english)")
                .accessibilityIdentifier("choice-\(choice.id)")
            }
        }
    }

    private func showsCheck(_ choice: QuizChoice) -> Bool {
        guard phase == .showingFeedback, feedback != nil else { return false }
        return choice.correct
    }

    private func showsCross(_ choice: QuizChoice) -> Bool {
        guard phase == .showingFeedback, let feedback, feedback.showCross else { return false }
        if let chosen = feedback.chosenID { return choice.id == chosen && !choice.correct }
        return choice.id == beat.choices.first(where: { !$0.correct })?.id
    }

    private func stamp(correct: Bool) -> some View {
        ZStack {
            Circle().fill(correct ? Theme.green : Theme.red)
            if correct {
                Tick().stroke(Color.white, style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round))
                    .padding(18)
            } else {
                Cross().stroke(Color.white, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .padding(20)
            }
        }
        .transition(.scale)
    }
}

private struct Tick: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.4, y: rect.maxY - rect.height * 0.18))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.08, y: rect.minY + rect.height * 0.18))
        return path
    }
}

private struct Cross: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        return path
    }
}

private struct PopIn: ViewModifier {
    let token: String
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(shown ? 1 : 0.2)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.52)) { shown = true }
            }
            .onChange(of: token) { _, _ in
                shown = false
                DispatchQueue.main.async {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.48)) { shown = true }
                }
            }
    }
}

private struct SlideIn: ViewModifier {
    let token: String
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .offset(x: shown ? 0 : 160)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.74)) { shown = true }
            }
            .onChange(of: token) { _, _ in
                shown = false
                DispatchQueue.main.async {
                    withAnimation(.spring(response: 0.48, dampingFraction: 0.74)) { shown = true }
                }
            }
    }
}
