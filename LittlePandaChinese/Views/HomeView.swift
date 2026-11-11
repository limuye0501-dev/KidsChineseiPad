import SwiftUI

struct HomeView: View {
    let library: EpisodeLibrary
    @EnvironmentObject private var audio: AppAudio
    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var store: StoreManager
    @EnvironmentObject private var settings: AppSettings
    @State private var selected: Episode?
    @State private var showGate = false
    @State private var showSettings = false
    @State private var wiggleID: String?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                PaperBackground(tint: Theme.paper).ignoresSafeArea()
                VStack(alignment: .leading, spacing: 12) {
                    header
                    if library.shelf.isEmpty {
                        Text("Stories aren’t available.")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 22) {
                                ForEach(library.shelf) { entry in
                                    card(entry, height: max(220, geo.size.height - 168))
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 18)
            }
        }
        .fullScreenCover(item: $selected) { episode in
            EpisodePlayerView(episode: episode, progress: progress)
                .environmentObject(audio)
                .environmentObject(settings)
        }
        .sheet(isPresented: $showGate) {
            ParentGateView {
                showGate = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showSettings = true
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear(perform: applyLaunchScreen)
        .onChange(of: settings.musicEnabled) { _, value in audio.musicEnabled = value }
        .onChange(of: settings.speechRate) { _, value in audio.speechRate = Float(value) }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            Color.clear
                .frame(width: 92, height: 112)
                .overlay(PandaView(messy: false, waving: true).scaleEffect(0.46))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Little Panda Chinese")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .minimumScaleFactor(0.6)
                Text("Short stories for ages 3–6")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.65))
            }
            Spacer()
            Button {
                showGate = true
            } label: {
                Text("Grown-ups")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(Capsule().fill(Theme.card).overlay(Capsule().stroke(Theme.ink, lineWidth: 3)))
            }
            .accessibilityIdentifier("grown-ups")
        }
    }

    private func card(_ entry: ShelfEntry, height: CGFloat) -> some View {
        let width = min(280, height * 0.72)
        let access = library.playbackAccess(for: entry, unlockedAll: store.isUnlockedAll)
        return Button {
            open(entry, access: access)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text("Episode \(entry.number)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.6))
                Text(entry.titleHanzi)
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(entry.titlePinyin)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.red)
                Text(entry.titleEnglish)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.75))
                Spacer(minLength: 0)
                footer(entry, access: access)
            }
            .padding(20)
            .frame(width: width, height: height, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(cardFill(entry))
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(Theme.ink, lineWidth: 4))
            )
            .modifier(CutShadow())
            .offset(x: wiggleID == entry.id ? 8 : 0)
        }
        .buttonStyle(KidButtonStyle())
        .accessibilityLabel(access == .play ? "Play episode \(entry.number) \(entry.titleEnglish)" : "\(entry.titleEnglish), coming soon")
        .accessibilityIdentifier("episode-\(entry.number)")
    }

    @ViewBuilder
    private func footer(_ entry: ShelfEntry, access: PlaybackAccess) -> some View {
        if access == .play {
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    StarShape()
                        .fill(index < progress.stars(for: entry.id) ? Theme.yellow : Theme.ink.opacity(0.12))
                        .overlay(StarShape().stroke(Theme.ink, lineWidth: 1.5))
                        .frame(width: 26, height: 26)
                }
                Spacer()
                Text("Play")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(Capsule().fill(Theme.green))
            }
        } else {
            Text(entry.isFree ? "Free · Coming soon" : "Coming soon")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.55))
        }
    }

    private func cardFill(_ entry: ShelfEntry) -> Color {
        switch entry.number {
        case 1: return Color(red: 1.0, green: 0.93, blue: 0.90)
        case 2: return Color(red: 1.0, green: 0.96, blue: 0.84)
        case 3: return Color(red: 0.90, green: 0.94, blue: 1.0)
        case 4: return Color(red: 0.91, green: 0.96, blue: 0.90)
        default: return Theme.card
        }
    }

    private func open(_ entry: ShelfEntry, access: PlaybackAccess) {
        switch access {
        case .play:
            selected = entry.episode
        case .comingSoon:
            withAnimation(.linear(duration: 0.06).repeatCount(5, autoreverses: true)) {
                wiggleID = entry.id
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { wiggleID = nil }
        case .needsPurchase:
            showGate = true
        }
    }

    private func applyLaunchScreen() {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-LPCScreen"), index + 1 < args.count else { return }
        switch args[index + 1] {
        case "gate":
            showGate = true
        case "quiz", "joke", "title", "episode":
            DispatchQueue.main.async {
                selected = library.shelf.first?.episode
            }
        default:
            break
        }
    }
}
