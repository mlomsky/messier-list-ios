import SwiftUI

/// Every popup the main screen can show. Port of the show*Dialog flags in MainActivity.kt.
enum ActiveSheet: Identifiable {
    case help, about, location, displayFilters, search, sunMoonChart
    case filterEdit(CatalogTarget)
    case elevationChart(CatalogTarget)

    var id: String {
        switch self {
        case .help: "help"
        case .about: "about"
        case .location: "location"
        case .displayFilters: "displayFilters"
        case .search: "search"
        case .sunMoonChart: "sunMoonChart"
        case .filterEdit(let t): "filter-\(t.id)"
        case .elevationChart(let t): "chart-\(t.id)"
        }
    }
}

/// The main screen. Port of ui/MainScreen.kt.
struct MainScreen: View {
    @Environment(SkyModel.self) private var model
    @Environment(\.appTheme) private var theme
    @State private var sheet: ActiveSheet?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CatalogToggleRow(sheet: $sheet)
                HeaderSection()
                SunMoonSection { sheet = .sunMoonChart }
                theme.divider.frame(height: 1).padding(.vertical, 6)
                SortButtonsRow()
                if model.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ObjectList(sheet: $sheet)
                }
            }
            .background(theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.night ? AnyShapeStyle(AppTheme.nightBlack) : AnyShapeStyle(Material.bar), for: .navigationBar)
            .toolbarBackground(theme.night ? .visible : .automatic, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("WAA Presents").font(.headline)
                        Text("Viewing Tonight  V\(Format.appVersion)").font(.caption)
                    }
                    .foregroundStyle(theme.text)
                    .fixedSize()
                    .accessibilityElement(children: .combine)
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { sheet = .help } label: { Image(systemName: "questionmark.circle") }
                        .accessibilityLabel("Help")
                    Button { sheet = .location } label: { Image(systemName: "mappin.and.ellipse") }
                        .accessibilityLabel("Set location")
                    Button { model.toggleNightMode() } label: {
                        Image(systemName: theme.night ? "moon.fill" : "moon")
                    }
                    .accessibilityLabel("Night mode")
                    .accessibilityValue(theme.night ? "On" : "Off")
                    Button { sheet = .about } label: { Image(systemName: "info.circle") }
                        .accessibilityLabel("About")
                }
            }
        }
        .sheet(item: $sheet) { which in
            SheetHost(sheet: which)
        }
    }
}

/// Routes each popup to its screen.
private struct SheetHost: View {
    @Environment(SkyModel.self) private var model
    let sheet: ActiveSheet

    var body: some View {
        Group {
            switch sheet {
            case .help: HelpSheet()
            case .about: AboutSheet()
            case .location: LocationSheet()
            case .displayFilters: DisplayFiltersSheet()
            case .search: SearchSheet()
            case .sunMoonChart: SunMoonChartSheet()
            case .filterEdit(let t): FilterEditSheet(target: t)
            case .elevationChart(let t): ElevationChartSheet(target: t)
            }
        }
        .appTheme(night: model.settings.nightMode)
    }
}

// MARK: - Sections

private struct CatalogToggleRow: View {
    @Environment(SkyModel.self) private var model
    @Environment(\.appTheme) private var theme
    @Binding var sheet: ActiveSheet?

    var body: some View {
        HStack(spacing: 8) {
            catalogChip("P", .planets)
            catalogChip("M", .messier)
            catalogChip("NGC", .ngc)
            Button { sheet = .search } label: {
                Image(systemName: model.searchFilter.isActive
                      ? "line.3.horizontal.decrease.circle.fill" : "magnifyingglass")
                    .font(.title3)
                    .frame(width: 40, height: 32)
            }
            .accessibilityLabel(model.searchFilter.isActive ? "Search (filter active)" : "Search objects")
            Button { sheet = .displayFilters } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3)
                    .frame(width: 40, height: 32)
            }
            .accessibilityLabel("Display filters")
        }
        .foregroundStyle(theme.accent)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    private func catalogChip(_ title: String, _ source: CatalogSource) -> some View {
        let on = model.settings.enabledCatalogs.contains(source)
        return Chip(title, selected: on) { model.setCatalog(source, enabled: !on) }
    }
}

private struct HeaderSection: View {
    @Environment(SkyModel.self) private var model
    @Environment(\.appTheme) private var theme

    var body: some View {
        let loc = model.location
        VStack(alignment: .leading, spacing: 2) {
            Text(loc.label)
                .font(.largeTitle.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text("\(Format.dms(loc.latitudeDeg, positive: "N", negative: "S"))  "
                 + "\(Format.dms(loc.longitudeDeg, positive: "E", negative: "W"))  "
                 + "\(String(format: "%.0f", loc.elevationMeters * 3.28084)) ft elev")
                .font(.subheadline)
            Text("\(Format.day(model.now))   \(Format.time(model.now))")
                .font(.title3)
        }
        .foregroundStyle(theme.text)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

private struct SunMoonSection: View {
    @Environment(SkyModel.self) private var model
    @Environment(\.appTheme) private var theme
    let onTap: () -> Void

    var body: some View {
        let t = model.sunMoonTimes
        Button(action: onTap) {
            HStack {
                stat("Sunset", Format.time(t.sunset))
                Spacer(minLength: 4)
                stat("Sunrise", Format.time(t.sunrise))
                Spacer(minLength: 4)
                stat("Moonrise", Format.time(t.moonrise))
                Spacer(minLength: 4)
                stat("Moonset", Format.time(t.moonset))
                Spacer(minLength: 4)
                stat("Illumination", String(format: "%.0f%%", t.moonIlluminationPercent))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(theme.text)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .accessibilityHint("Shows the Sun and Moon chart")
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 1) {
            Text(value).font(.subheadline.weight(.medium)).lineLimit(1).minimumScaleFactor(0.7)
            Text(label).font(.caption2).lineLimit(1).minimumScaleFactor(0.7)
        }
    }
}

private struct SortButtonsRow: View {
    @Environment(SkyModel.self) private var model

    var body: some View {
        let mode = model.sortMode
        HStack(spacing: 6) {
            Chip("Name", selected: mode == .name) { model.setSortMode(.name) }
            Chip("Max Elev", selected: mode == .maxElevation) { model.setSortMode(.maxElevation) }
            Chip(mode == .endTime ? "Set Time" : "Rise Time",
                 selected: mode == .startTime || mode == .endTime) { model.setSortMode(.startTime) }
            Chip("Now", selected: mode == .now) { model.setSortMode(.now) }
            Chip(selected: mode == .favorites) { model.setSortMode(.favorites) } label: {
                Image(systemName: mode == .favorites ? "star.fill" : "star")
                    .accessibilityLabel("Favorites")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}

private struct ObjectList: View {
    @Environment(SkyModel.self) private var model
    @Environment(\.appTheme) private var theme
    @Binding var sheet: ActiveSheet?

    var body: some View {
        let objects = model.objects
        if objects.isEmpty {
            ContentUnavailableView(
                "Nothing to show",
                systemImage: "sparkles",
                description: Text("Try turning on another catalog, raising the magnitude limit, or clearing the search."))
                .foregroundStyle(theme.text)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(objects) { v in
                ObjectRow(
                    visibility: v,
                    filterText: model.filterText(for: v.target),
                    isFavorite: model.settings.favorites.contains(v.target.id),
                    onFavorite: { model.toggleFavorite(v.target) },
                    onFilter: { sheet = .filterEdit(v.target) },
                    onShowChart: { sheet = .elevationChart(v.target) }
                )
                .listRowBackground(theme.background)
                .listRowSeparatorTint(theme.divider)
                .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .refreshable { await model.refreshLocation() }
        }
    }
}
