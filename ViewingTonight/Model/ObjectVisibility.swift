import Foundation

// Port of model/ObjectVisibility.kt.

nonisolated struct ObjectVisibility: Identifiable, Equatable, Sendable {
    let target: CatalogTarget
    let window: VisibilityWindow
    let currentAltitudeDeg: Double
    let currentAzimuthDeg: Double

    var id: String { target.id }

    /// Objects already up at session start (no rise time) sort first.
    var sortableStartTime: Date { window.riseTime ?? .distantPast }

    /// Objects still up at session end (no set time) sort last.
    var sortableEndTime: Date { window.setTime ?? .distantFuture }

    var isVisibleNow: Bool { currentAltitudeDeg >= RiseSetThresholds.starOrPlanet }
}

nonisolated enum SortMode: String, CaseIterable, Codable, Sendable {
    case name = "NAME"
    case maxElevation = "MAX_ELEVATION"
    case startTime = "START_TIME"
    case endTime = "END_TIME"
    case now = "NOW"
    case favorites = "FAVORITES"
}

/// Raw values match the Kotlin enum names (the Android app stored these strings in its settings).
nonisolated enum CatalogSource: String, CaseIterable, Codable, Sendable {
    case planets = "PLANETS"
    case messier = "MESSIER"
    case ngc = "NGC"
}
