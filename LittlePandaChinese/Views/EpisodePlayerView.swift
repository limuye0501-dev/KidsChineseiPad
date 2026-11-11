import SwiftUI

struct EpisodePlayerView: View {
    @StateObject private var session: EpisodeSession
    @EnvironmentObject private var audio: AppAudio
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    init(episode: Episode, progress: ProgressStore) {
        _session = StateObject(wrappedValue: EpisodeSession(episode: episode, progress: progress))
    }

    var body: some View {
        ZStack {
            if let beat = session.beat {
                StageView(
                    episode: session.episode,
                    beat: beat,
                    phase: session.phase,
                    feedback: session.feedback,
                    onChoose: { session.choose($0) }
                )
            } else {
                PaperBackground(tint: Theme.paper)
            }
            VStack {
                HStack(spacing: 16) {
                    Button {
                        session.stop()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 56, height: 56)
                            .background(Circle().fill(Theme.card).overlay(Circle().stroke(Theme.ink, lineWidth: 3)))
                    }
                    .accessibilityLabel("Close")
                    .accessibilityIdentifier("close-episode")
                    Spacer()
                    progressBar
                        .frame(width: 180)
                }
                .padding(.horizontal, 22)
                .padding(.top, 14)
                Spacer()
            }
            if session.phase == .finished {
                finishedCard
            }
        }
        .background(Theme.paper)
        .statusBarHidden(true)
        .onAppear(perform: begin)
        .onDisappear { session.stop() }
        .sensoryFeedback(session.feedback?.showCross == true ? .warning : .success, trigger: session.feedback?.line.hanzi)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.ink.opacity(0.12))
                Capsule().fill(Theme.red).frame(width: max(8, geo.size.width * session.fraction))
            }
        }
        .frame(height: 10)
        .accessibilityLabel("Story progress")
    }

    private var finishedCard: some View {
        VStack(spacing: 14) {
            Text("太棒了！")
                .font(.system(size: 48, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.ink)
            Text("You did it!")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.7))
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    StarShape()
                        .fill(index < session.stars ? Theme.yellow : Theme.ink.opacity(0.12))
                        .overlay(StarShape().stroke(Theme.ink, lineWidth: 2))
                        .frame(width: 42, height: 42)
                }
            }
            HStack(spacing: 16) {
                Button {
                    session.startPlaying(audio: audio, music: settings.musicEnabled, rate: Float(settings.speechRate))
                } label: {
                    Text("Again")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 140, height: 64)
                        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.yellow).overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.ink, lineWidth: 3)))
                }
                .buttonStyle(KidButtonStyle())
                Button {
                    session.stop()
                    dismiss()
                } label: {
                    Text("Home")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 140, height: 64)
                        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.green).overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.ink, lineWidth: 3)))
                }
                .buttonStyle(KidButtonStyle())
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Theme.card)
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(Theme.ink, lineWidth: 4))
        )
        .modifier(CutShadow())
    }

    private func begin() {
        let args = ProcessInfo.processInfo.arguments
        if let index = args.firstIndex(of: "-LPCScreen"), index + 1 < args.count {
            switch args[index + 1] {
            case "quiz":
                session.showPaused(beatID: "quiz_red")
                return
            case "joke":
                session.showPaused(beatID: "joke_fall")
                return
            case "title":
                session.showPaused(beatID: "title")
                return
            default:
                break
            }
        }
        session.startPlaying(audio: audio, music: settings.musicEnabled, rate: Float(settings.speechRate))
    }
}
