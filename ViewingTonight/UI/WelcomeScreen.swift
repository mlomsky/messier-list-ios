import SwiftUI

/// Shown only while the very first location/astronomy data load is in flight. Port of ui/WelcomeScreen.kt.
struct WelcomeScreen: View {
    private let background = Color(red: 0x0B / 255.0, green: 0x10 / 255.0, blue: 0x26 / 255.0)
    private let foreground = Color(red: 0xF5 / 255.0, green: 0xF1 / 255.0, blue: 0xE3 / 255.0)

    var body: some View {
        ZStack {
            background.ignoresSafeArea()
            VStack(spacing: 4) {
                Image("WAALogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 160)
                    .accessibilityLabel("Westchester Amateur Astronomers")
                    .padding(.bottom, 12)
                Text("WAA Presents\nViewing Tonight")
                    .font(.title.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text("Version \(Format.appVersion)")
                    .font(.caption)
                Text("Created by Michael Lomsky for the Westchester Amateur Astronomers")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                ProgressView()
                    .tint(foreground)
                    .padding(.top, 20)
                Text("Finding your sky…")
                    .font(.caption)
            }
            .foregroundStyle(foreground)
        }
    }
}

#Preview { WelcomeScreen() }
