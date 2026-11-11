import SwiftUI
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        .landscape
    }
}

enum LaunchRequest {
    /// `-LPCScreen home|title|quiz|joke|gate|episode` for simulator captures.
    static var screen: String {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-LPCScreen"), index + 1 < args.count else { return "" }
        return args[index + 1]
    }
}

@main
struct LittlePandaChineseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var audio = AppAudio()
    @StateObject private var progress = ProgressStore()
    @StateObject private var store = StoreManager()
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            RootView(library: (try? EpisodeLibrary.load()) ?? .empty)
                .environmentObject(audio)
                .environmentObject(progress)
                .environmentObject(store)
                .environmentObject(settings)
                .preferredColorScheme(.light)
        }
    }
}

struct RootView: View {
    let library: EpisodeLibrary
    @EnvironmentObject private var progress: ProgressStore

    var body: some View {
        switch LaunchRequest.screen {
        case "gate":
            ParentGateView {}
        case "quiz", "joke", "title", "episode":
            if let episode = library.playable.first {
                EpisodePlayerView(episode: episode, progress: progress)
            } else {
                HomeView(library: library)
            }
        default:
            HomeView(library: library)
        }
    }
}
