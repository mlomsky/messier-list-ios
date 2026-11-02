import SwiftUI

@main
struct ViewingTonightApp: App {
    @State private var model = SkyModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
        }
    }
}
