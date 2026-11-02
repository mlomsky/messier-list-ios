import SwiftUI

/// Colors for day and night (red-on-black, night-vision) modes. Port of ui/theme/Theme.kt.
struct AppTheme {
    static let nightRed = Color(red: 1.0, green: 59.0 / 255.0, blue: 48.0 / 255.0)   // #FF3B30, same as Android
    static let nightBlack = Color.black

    var night: Bool

    var text: Color { night ? Self.nightRed : .primary }
    var secondaryText: Color { night ? Self.nightRed.opacity(0.75) : .secondary }
    var accent: Color { night ? Self.nightRed : .accentColor }
    var background: Color { night ? Self.nightBlack : Color(uiColor: .systemBackground) }
    var divider: Color { night ? Self.nightRed.opacity(0.35) : Color(uiColor: .separator) }

    /// Alt/az text once an object is at or below the horizon: red by day, grey at night (red is "normal" at night).
    var belowHorizon: Color { night ? .gray : .red }

    var chipSelectedBackground: Color { night ? Self.nightRed : Color.accentColor.opacity(0.18) }
    var chipSelectedText: Color { night ? Self.nightBlack : .accentColor }
    var chipText: Color { night ? Self.nightRed : .primary }
    var chipBorder: Color { night ? Self.nightRed : Color(uiColor: .separator) }
}

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme(night: false)
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

extension View {
    /// Applies the app theme everywhere below this view, including system chrome (status bar,
    /// navigation bar, sheets), which is forced dark in night mode so nothing glows white.
    func appTheme(night: Bool) -> some View {
        environment(\.appTheme, AppTheme(night: night))
            .preferredColorScheme(night ? .dark : nil)
            .tint(night ? AppTheme.nightRed : nil)
    }
}
