import SwiftUI

/// Branding, version and what's in the app. Port of ui/AboutDialog.kt.
struct AboutSheet: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM d, yyyy"
        return f
    }()

    private let features = [
        "Planets (plus the Moon), the 110 Messier objects and 4,000+ NGC objects, each toggled with P / M / NGC",
        "Rise and set times, max elevation, and live altitude/azimuth for tonight's 6pm–6am session",
        "Tap any object's name for an elevation chart across tonight's session",
        "Tap the Sunset/Sunrise/Moonrise/Moonset/Illumination row for a Sun & Moon chart with twilight shading",
        "Search by name, type, direction or altitude; set a limiting magnitude; hide objects below the horizon",
        "Favorites, nebula-filter notes, and a red Night Mode to protect your dark adaptation",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    Text("WAA Presents\nViewing Tonight")
                        .font(.title2.weight(.semibold))
                        .multilineTextAlignment(.center)
                    Image("WAALogo")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .background(Color.black, in: RoundedRectangle(cornerRadius: 8))
                        .accessibilityLabel("Westchester Amateur Astronomers")
                    Text("Version \(Format.appVersion)  •  \(Self.dateFormatter.string(from: .now))")
                        .font(.subheadline)
                    Text("Created by Michael Lomsky for the Westchester Amateur Astronomers")
                        .font(.body)
                        .multilineTextAlignment(.center)
                    Text("An observing tool to help you pick what objects you'd like to see among the Messier, NGC, and planet catalogs.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("The iPhone version").font(.headline)
                        Text("A full port of the Android app (v2.2), with the same calculations and catalogs:")
                            .font(.footnote)
                        ForEach(features, id: \.self) { item in
                            Text("•  \(item)").font(.footnote)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                }
                .padding()
            }
            .foregroundStyle(theme.text)
            .background(theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .themedNavigationBar(theme)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Close") { dismiss() } } }
        }
    }
}

/// Feature guide. Port of ui/HelpDialog.kt, with icon names adjusted for the iPhone layout.
struct HelpSheet: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    private let items: [(String, String)] = [
        ("Observing session",
         "Every calculation in this app is based on one observing session: 6pm local time tonight to 6am the next morning. If you open the app between midnight and 6am, you're seeing the tail end of the session that started the evening before."),
        ("Location",
         "Uses your phone's GPS by default (falls back to New York City if that's unavailable). Tap the pin icon to search for a different city or address instead. Pull the list down to refresh."),
        ("P / M / NGC buttons",
         "P (Planets), M (Messier), and NGC — independently turn each catalog on or off. NGC adds thousands of fainter deep-sky objects beyond the 110 Messier objects — pair it with the magnitude limit below to keep the list manageable."),
        ("Search (magnifying glass)",
         "Filter the current list by name, object type (e.g. \"Galaxy\"), compass direction, and/or a minimum current altitude. All fields are optional and combine together; \"Clear search\" resets them."),
        ("Display Filters (slider icon)",
         "Set the dimmest magnitude to include, across all catalogs — P, M, and NGC (lower numbers are brighter; objects with no published magnitude are always shown), and optionally hide any object that's currently below the horizon, also across all catalogs."),
        ("Sunrise/sunset & moon",
         "Shown even if they fall slightly outside the 6pm-6am session, since the search window is widened a bit around it. A missing moonrise or moonset on a given night is expected sometimes — it matches real published moon tables, not a bug."),
        ("Sun & Moon chart",
         "Tap Sunset, Sunrise, Moonrise, Moonset, or Illumination to see the Sun's and Moon's altitude across the whole session. The background shades as the sky darkens: clear by day, a light band through twilight, a darker band for astronomical twilight, and the darkest band once it's fully dark."),
        ("Night Mode",
         "The moon icon switches all text to red to preserve your night vision while observing."),
        ("Sort buttons",
         "Sort the object list by Name, Max Elevation during the session, Rise/Set Time (tap again to switch), Now (only objects currently above the horizon, sorted by current altitude), or the ★ Favorites toggle (tap again to turn it off)."),
        ("Object list",
         "Every object from the catalogs you've turned on: Messier, NGC, and the naked-eye/telescope planets. Current altitude/azimuth and compass direction sit next to each name, turning red (grey in Night Mode) once the object drops to or below the horizon. Max elevation and rise/set time for the session are on the right."),
        ("Elevation chart",
         "Tap any object's name to see a chart of its altitude across tonight's session, with the below-horizon portion shaded so you can see at a glance how much of the night it's up."),
        ("Magnitude",
         "\"Mag\" is an object's apparent (visual) magnitude — lower numbers mean brighter. For planets this is a representative mean value, since their real brightness varies with position."),
        ("★ Favorites",
         "Tap the star next to any object to favorite it, on any catalog. Use the ★ sort button to view just your favorites."),
        ("F button",
         "Tap the F circle next to any object to record which filter works best for it (UHC, OIII, H-Beta, Light Pollution, or your own write-in). Several Messier objects already come with a starting recommendation."),
    ]

    var body: some View {
        NavigationStack {
            List(items, id: \.0) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.0).font(.subheadline.bold())
                    Text(item.1).font(.footnote)
                }
                .padding(.vertical, 2)
                .themedRow(theme)
            }
            .listStyle(.plain)
            .themedForm(theme)
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.inline)
            .themedNavigationBar(theme)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Close") { dismiss() } } }
        }
    }
}
