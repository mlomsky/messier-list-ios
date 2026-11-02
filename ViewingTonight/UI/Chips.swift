import SwiftUI

/// A toggle chip used for the catalog (P / M / NGC) and sort rows. Port of SortButton/FilterChip.
struct Chip<Label: View>: View {
    @Environment(\.appTheme) private var theme
    let selected: Bool
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    var body: some View {
        Button(action: action) {
            label()
                .font(.footnote.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, minHeight: 32)
                .foregroundStyle(selected ? theme.chipSelectedText : theme.chipText)
                .background(selected ? theme.chipSelectedBackground : .clear, in: Capsule())
                .overlay(Capsule().strokeBorder(selected ? .clear : theme.chipBorder, lineWidth: 1))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

extension Chip where Label == Text {
    init(_ title: String, selected: Bool, action: @escaping () -> Void) {
        self.init(selected: selected, action: action) { Text(title) }
    }
}

/// The round "F" button that opens an object's nebula-filter note. Filled when a note exists.
struct FilterBadge: View {
    @Environment(\.appTheme) private var theme
    let hasFilter: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("F")
                .font(.caption.weight(.bold))
                .frame(width: 28, height: 28)
                .foregroundStyle(foreground)
                .background(background, in: Circle())
                .overlay(Circle().strokeBorder(theme.night && !hasFilter ? AppTheme.nightRed : .clear, lineWidth: 1))
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(hasFilter ? "Edit filter note" : "Add filter note")
    }

    private var background: Color {
        switch (theme.night, hasFilter) {
        case (true, true): AppTheme.nightRed
        case (true, false): AppTheme.nightBlack
        case (false, true): Color.accentColor.opacity(0.25)
        case (false, false): Color(uiColor: .secondarySystemFill)
        }
    }

    private var foreground: Color {
        theme.night ? (hasFilter ? AppTheme.nightBlack : AppTheme.nightRed) : .primary
    }
}

/// The star that adds/removes a favorite.
struct FavoriteStar: View {
    @Environment(\.appTheme) private var theme
    let isFavorite: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.system(size: 18))
                .foregroundStyle(theme.accent)
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
    }
}
