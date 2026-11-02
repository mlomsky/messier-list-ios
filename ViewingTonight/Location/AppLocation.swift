import Foundation

// Port of AppLocation / DefaultLocation from data/LocationRepository.kt.

nonisolated struct AppLocation: Equatable, Codable, Sendable {
    var label: String
    var latitudeDeg: Double
    var longitudeDeg: Double
    var elevationMeters: Double
    var isCustom: Bool

    var observer: Observer {
        Observer(latitudeDeg: latitudeDeg, longitudeDeg: longitudeDeg, elevationMeters: elevationMeters)
    }

    /// Fallback when GPS is unavailable or permission is denied (same as Android).
    static let newYorkCity = AppLocation(
        label: "New York City", latitudeDeg: 40.7128, longitudeDeg: -74.0060, elevationMeters: 10.0, isCustom: false
    )
}
