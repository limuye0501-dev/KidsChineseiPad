import SwiftUI

@main
struct LittlePandaChineseApp: App {
    @StateObject private var audio = AppAudio()
    @StateObject private var progress = ProgressStore()
    @StateObject private var store = StoreManager()
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            HomeView(library: (try? EpisodeLibrary.load()) ?? .empty)
                .environmentObject(audio)
                .environmentObject(progress)
                .environmentObject(store)
                .environmentObject(settings)
                .preferredColorScheme(.light)
        }
    }
}
