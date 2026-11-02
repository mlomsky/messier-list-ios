import Foundation
import Observation

/// Persisted user settings. Port of data/PreferencesRepository.kt (Android DataStore -> UserDefaults).
/// Key names and stored values match the Android app's, which keeps the two easy to compare.
@Observable
final class AppSettings {
    static let defaultEnabledCatalogs: Set<CatalogSource> = [.planets, .messier]
    static let defaultNgcMagnitudeLimit = 12.0

    private enum Key {
        static let nightMode = "night_mode"
        static let enabledCatalogs = "enabled_catalogs"
        static let ngcMagnitudeLimit = "ngc_magnitude_limit"
        static let hideBelowHorizon = "hide_below_horizon"
        static let favorites = "favorites"
        static let filterOverrides = "filter_overrides"
    }

    @ObservationIgnored private let defaults: UserDefaults

    var nightMode: Bool { didSet { defaults.set(nightMode, forKey: Key.nightMode) } }

    var enabledCatalogs: Set<CatalogSource> {
        didSet { defaults.set(enabledCatalogs.map(\.rawValue).sorted(), forKey: Key.enabledCatalogs) }
    }

    /// Magnitude limit applied across all catalogs (the Display Filters dialog).
    var ngcMagnitudeLimit: Double { didSet { defaults.set(ngcMagnitudeLimit, forKey: Key.ngcMagnitudeLimit) } }

    var hideBelowHorizon: Bool { didSet { defaults.set(hideBelowHorizon, forKey: Key.hideBelowHorizon) } }

    /// Favorited object ids ("M1", "NGC220", "JUPITER", ...).
    var favorites: Set<String> { didSet { defaults.set(favorites.sorted(), forKey: Key.favorites) } }

    /// User-set filter notes, keyed by catalog id ("M1", "M8", ...). These override DefaultFilters.
    var filterOverrides: [String: String] { didSet { defaults.set(filterOverrides, forKey: Key.filterOverrides) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        nightMode = defaults.bool(forKey: Key.nightMode)
        if let stored = defaults.stringArray(forKey: Key.enabledCatalogs) {
            enabledCatalogs = Set(stored.compactMap(CatalogSource.init(rawValue:)))
        } else {
            enabledCatalogs = Self.defaultEnabledCatalogs
        }
        ngcMagnitudeLimit = defaults.object(forKey: Key.ngcMagnitudeLimit) as? Double ?? Self.defaultNgcMagnitudeLimit
        hideBelowHorizon = defaults.bool(forKey: Key.hideBelowHorizon)
        favorites = Set(defaults.stringArray(forKey: Key.favorites) ?? [])
        filterOverrides = defaults.dictionary(forKey: Key.filterOverrides) as? [String: String] ?? [:]
    }

    func setCatalog(_ source: CatalogSource, enabled: Bool) {
        if enabled { enabledCatalogs.insert(source) } else { enabledCatalogs.remove(source) }
    }

    func toggleFavorite(_ objectId: String) {
        if favorites.contains(objectId) { favorites.remove(objectId) } else { favorites.insert(objectId) }
    }

    /// Blank text clears the user's note (falling back to the built-in default, if any).
    func setFilter(_ text: String, for objectId: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { filterOverrides.removeValue(forKey: objectId) } else { filterOverrides[objectId] = text }
    }

    /// The note to show for an object: the user's override if set, else the built-in recommendation.
    func filterText(for objectId: String) -> String? {
        filterOverrides[objectId] ?? DefaultFilters.byId[objectId]
    }
}
