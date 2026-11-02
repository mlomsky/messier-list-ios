import SwiftUI

extension View {
    /// Form/List styling that follows the app theme: pure black with red text in night mode.
    func themedForm(_ theme: AppTheme) -> some View {
        self
            .foregroundStyle(theme.text)
            .scrollContentBackground(theme.night ? .hidden : .automatic)
            .background(theme.night ? AppTheme.nightBlack : Color.clear)
    }

    /// Row background for themed forms (rows otherwise glow dark grey at night).
    func themedRow(_ theme: AppTheme) -> some View {
        listRowBackground(theme.night ? AppTheme.nightBlack : nil)
            .listRowSeparatorTint(theme.night ? theme.divider : nil)
    }

    /// Black navigation bar in night mode.
    func themedNavigationBar(_ theme: AppTheme) -> some View {
        self
            .toolbarBackground(theme.night ? AnyShapeStyle(AppTheme.nightBlack) : AnyShapeStyle(Material.bar), for: .navigationBar)
            .toolbarBackground(theme.night ? .visible : .automatic, for: .navigationBar)
    }
}
