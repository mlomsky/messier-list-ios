import CoreLocation

/// GPS location plus the single remembered custom location. Port of data/LocationRepository.kt
/// (Android LocationManager + DataStore -> CLLocationManager + UserDefaults).
final class LocationService: NSObject, CLLocationManagerDelegate {

    private enum Key {
        static let label = "custom_label"
        static let lat = "custom_lat"
        static let lon = "custom_lon"
        static let elevation = "custom_elevation"
    }

    private let defaults: UserDefaults
    private let manager = CLLocationManager()
    private var authorizationWaiters: [CheckedContinuation<Void, Never>] = []
    private var locationWaiters: [CheckedContinuation<CLLocation?, Never>] = []

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        super.init()
        manager.delegate = self
        // Kilometer accuracy is plenty for "what's above my horizon" and is much faster and
        // kinder to the battery than a full GPS fix.
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    // MARK: Custom location

    var customLocation: AppLocation? {
        guard let label = defaults.string(forKey: Key.label),
              let lat = defaults.object(forKey: Key.lat) as? Double,
              let lon = defaults.object(forKey: Key.lon) as? Double
        else { return nil }
        let elevation = defaults.object(forKey: Key.elevation) as? Double ?? 0.0
        return AppLocation(label: label, latitudeDeg: lat, longitudeDeg: lon, elevationMeters: elevation, isCustom: true)
    }

    func saveCustomLocation(_ location: AppLocation) {
        defaults.set(location.label, forKey: Key.label)
        defaults.set(location.latitudeDeg, forKey: Key.lat)
        defaults.set(location.longitudeDeg, forKey: Key.lon)
        defaults.set(location.elevationMeters, forKey: Key.elevation)
    }

    func clearCustomLocation() {
        for key in [Key.label, Key.lat, Key.lon, Key.elevation] { defaults.removeObject(forKey: key) }
    }

    // MARK: GPS

    var isAuthorized: Bool {
        manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways
    }

    /// The device's current location, or nil if unavailable, denied, or the fix failed.
    /// Asks for permission the first time it's called.
    func currentLocation() async -> AppLocation? {
        if manager.authorizationStatus == .notDetermined {
            await withCheckedContinuation { continuation in
                authorizationWaiters.append(continuation)
                if authorizationWaiters.count == 1 { manager.requestWhenInUseAuthorization() }
            }
        }
        guard isAuthorized else { return nil }

        // Like Android's "last known location": reuse a recent fix instead of waiting for a new one.
        if let recent = manager.location, recent.timestamp.timeIntervalSinceNow > -30 * 60 {
            return await appLocation(from: recent)
        }
        let fix: CLLocation? = await withCheckedContinuation { continuation in
            locationWaiters.append(continuation)
            if locationWaiters.count == 1 { manager.requestLocation() }
        }
        guard let fix else { return nil }
        return await appLocation(from: fix)
    }

    private func appLocation(from location: CLLocation) async -> AppLocation {
        var elevation = 0.0
        if location.verticalAccuracy > 0 && location.altitude != 0 {
            elevation = location.altitude
        } else if let looked = await ElevationService.lookupMeters(
            latitudeDeg: location.coordinate.latitude, longitudeDeg: location.coordinate.longitude) {
            elevation = looked
        }
        return AppLocation(
            label: "Current Location",
            latitudeDeg: location.coordinate.latitude,
            longitudeDeg: location.coordinate.longitude,
            elevationMeters: elevation,
            isCustom: false
        )
    }

    // MARK: CLLocationManagerDelegate
    // The manager is created on the main thread, so Core Location calls these on the main thread.

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        MainActor.assumeIsolated {
            guard status != .notDetermined else { return }
            let waiters = authorizationWaiters
            authorizationWaiters.removeAll()
            waiters.forEach { $0.resume() }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let last = locations.last
        MainActor.assumeIsolated { finishLocationRequest(with: last) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        MainActor.assumeIsolated { finishLocationRequest(with: nil) }
    }

    private func finishLocationRequest(with location: CLLocation?) {
        let waiters = locationWaiters
        locationWaiters.removeAll()
        waiters.forEach { $0.resume(returning: location) }
    }
}
