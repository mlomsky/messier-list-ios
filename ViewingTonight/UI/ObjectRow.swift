import SwiftUI

/// One row of the object list. Port of ObjectRow in MainScreen.kt.
struct ObjectRow: View {
    @Environment(\.appTheme) private var theme
    let visibility: ObjectVisibility
    let filterText: String?
    let isFavorite: Bool
    let onFavorite: () -> Void
    let onFilter: () -> Void
    let onShowChart: () -> Void

    private var target: CatalogTarget { visibility.target }
    private var window: VisibilityWindow { visibility.window }
    private var hasFilter: Bool { !(filterText ?? "").trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            FavoriteStar(isFavorite: isFavorite, action: onFavorite)
            FilterBadge(hasFilter: hasFilter, action: onFilter)

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Button(action: onShowChart) {
                        Text(target.displayName)
                            .font(.headline)
                            .foregroundStyle(theme.text)
                            .multilineTextAlignment(.leading)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityHint("Shows tonight's elevation chart")

                    Text(altAzText)
                        .font(.caption)
                        .foregroundStyle(visibility.currentAltitudeDeg <= 0 ? theme.belowHorizon : theme.text)
                        .fixedSize()
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(theme.secondaryText)
                if hasFilter, let filterText {
                    Text("Filter: \(filterText)")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 2) {
                Text("Max \(Int(window.maxAltitudeDeg))°")
                    .font(.subheadline)
                Text(rangeText)
                    .font(.caption)
            }
            .foregroundStyle(theme.text)
            .fixedSize()
        }
        .padding(.vertical, 4)
    }

    private var altAzText: String {
        let alt = String(format: "%.0f", visibility.currentAltitudeDeg)
        let az = String(format: "%.0f", visibility.currentAzimuthDeg)
        return "\(alt)°/\(az)° \(visibility.currentAzimuthDeg.cardinalDirection)"
    }

    private var subtitle: String {
        "\(target.typeLabel)  •  Mag \(Format.magnitude(target.apparentMagnitude))"
    }

    private var rangeText: String {
        if !window.risesAboveThreshold { return "Not visible" }
        if window.alwaysAboveThreshold { return "All night" }
        return "\(Format.time(window.riseTime)) - \(Format.time(window.setTime))"
    }
}
