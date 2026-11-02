import Foundation
import Observation

/// The app's state hub, read by every screen. Port of viewmodel/MainViewModel.kt: recomputes all
/// catalog visibility every 5 minutes and whenever the location or catalog settings change, and
/// ticks a clock every 15 seconds for the header.
@Observable
final class SkyModel {
    static let recomputeInterval: Duration = .seconds(5 * 60)
    static let clockTick: Duration = .seconds(15)

    let settings: AppSettings
    @ObservationIgnored private let locationService: LocationService

    private(set) var location: AppLocation = .newYorkCity
    private(set) var session: ViewingSession?
    private(set) var sunMoonTimes: SunMoonTimes = .empty
    private(set) var allObjects: [ObjectVisibility] = []
    private(set) var sortMode: SortMode = .name
    private(set) var isLoading = true
    private(set) var now = Date()
    var searchFilter = ObjectSearchFilter()

    @ObservationIgnored private var computeGeneration = 0
    @ObservationIgnored private var loops: [Task<Void, Never>] = []

    init(settings: AppSettings = AppSettings(), locationService: LocationService = LocationService()) {
        self.settings = settings
        self.locationService = locationService
    }

    /// The list as shown: filtered by search and hide-below-horizon, then sorted.
    var objects: [ObjectVisibility] {
        SkySorting.apply(
            allObjects, mode: sortMode, hideBelowHorizon: settings.hideBelowHorizon,
            filter: searchFilter, favorites: settings.favorites)
    }

    /// The filter note for an object: the user's own, else the built-in recommendation.
    func filterText(for target: CatalogTarget) -> String? { settings.filterText(for: target.id) }

    // MARK: Lifecycle

    /// Starts the clock and refresh loops and resolves the location. Safe to call more than once.
    func start() {
        guard loops.isEmpty else { return }
        loops.append(Task { [weak self] in
            while !Task.isCancelled {
                self?.now = Date()
                try? await Task.sleep(for: Self.clockTick)
            }
        })
        loops.append(Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: Self.recomputeInterval)
                await self?.recompute()
            }
        })
        Task { await refreshLocation() }
    }

    func refreshLocation() async {
        isLoading = true
        if let custom = locationService.customLocation {
            location = custom
        } else {
            location = await locationService.currentLocation() ?? .newYorkCity
        }
        await recompute()
    }

    /// Recomputes everything on a background thread. If settings change mid-calculation, only the
    /// newest result is kept.
    func recompute() async {
        computeGeneration += 1
        let generation = computeGeneration
        let location = self.location
        let enabled = settings.enabledCatalogs
        let limit = settings.ngcMagnitudeLimit
        let snapshot = await Task.detached(priority: .userInitiated) {
            SkyCalculator.compute(location: location, enabledCatalogs: enabled, magnitudeLimit: limit)
        }.value
        guard generation == computeGeneration else { return }
        session = snapshot.session
        sunMoonTimes = snapshot.sunMoonTimes
        allObjects = snapshot.objects
        now = Date()
        isLoading = false
    }

    // MARK: User actions

    func setSortMode(_ tapped: SortMode) {
        sortMode = SkySorting.nextMode(current: sortMode, tapped: tapped)
    }

    func toggleNightMode() { settings.nightMode.toggle() }

    func setCustomLocation(_ newLocation: AppLocation) async {
        locationService.saveCustomLocation(newLocation)
        location = newLocation
        await recompute()
    }

    func useGpsLocation() async {
        locationService.clearCustomLocation()
        await refreshLocation()
    }

    func searchLocation(_ query: String) async -> AppLocation? {
        await GeocodingService.search(query)
    }

    func setCatalog(_ source: CatalogSource, enabled: Bool) {
        settings.setCatalog(source, enabled: enabled)
        Task { await recompute() }
    }

    func setMagnitudeLimit(_ limit: Double) {
        settings.ngcMagnitudeLimit = limit
        Task { await recompute() }
    }

    func setHideBelowHorizon(_ hide: Bool) { settings.hideBelowHorizon = hide }

    func toggleFavorite(_ target: CatalogTarget) { settings.toggleFavorite(target.id) }

    func setFilter(_ text: String, for target: CatalogTarget) { settings.setFilter(text, for: target.id) }

    // MARK: Charts

    /// Altitude across tonight's session at 30-minute steps (the elevation chart).
    func elevationSeries(for target: CatalogTarget) async -> [AltitudeSample] {
        guard let session else { return [] }
        let observer = location.observer
        return await Task.detached {
            AltitudeSampler.series(
                observer: observer, position: SkyCalculator.provider(for: target),
                start: session.start, end: session.end)
        }.value
    }

    /// Sun and Moon altitude across tonight's session at 15-minute steps (the Sun & Moon chart).
    func sunMoonSeries() async -> (sun: [AltitudeSample], moon: [AltitudeSample]) {
        guard let session else { return ([], []) }
        let observer = location.observer
        return await Task.detached {
            let sun = AltitudeSampler.series(
                observer: observer, position: SkyCalculator.sunProvider,
                start: session.start, end: session.end, stepMinutes: 15)
            let moon = AltitudeSampler.series(
                observer: observer, position: SkyCalculator.moonProvider,
                start: session.start, end: session.end, stepMinutes: 15)
            return (sun, moon)
        }.value
    }
}
