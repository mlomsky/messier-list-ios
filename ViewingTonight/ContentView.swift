import SwiftUI

/// Root view: the welcome screen during the first load, then the main screen. Mirrors the
/// showWelcome logic in MainActivity.kt.
struct ContentView: View {
    @Environment(SkyModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase
    @State private var showWelcome = true

    var body: some View {
        Group {
            if showWelcome {
                WelcomeScreen()
            } else {
                MainScreen()
            }
        }
        .appTheme(night: model.settings.nightMode)
        .task { model.start() }
        .onChange(of: model.isLoading) { _, loading in
            if !loading { withAnimation { showWelcome = false } }
        }
        // iOS pauses apps in the background, so refresh when the user comes back
        // (e.g. phone pocketed at the eyepiece for twenty minutes).
        .onChange(of: scenePhase) { _, phase in
            if phase == .active && !showWelcome { Task { await model.recompute() } }
        }
    }
}

#Preview {
    ContentView().environment(SkyModel())
}
