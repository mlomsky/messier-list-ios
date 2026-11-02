import CoreLocation

/// Resolves a free-text address/place name to a location. Port of data/GeocodingRepository.kt
/// (Android Geocoder -> CLGeocoder). Requires network; returns nil if nothing is found.
enum GeocodingService {

    static func search(_ query: String) async -> AppLocation? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        // CLGeocoder is deprecated in the iOS 26 SDK in favor of MapKit's MKGeocodingRequest, but that
        // replacement needs iOS 26 and we support iOS 17+, so CLGeocoder is the right call for now.
        guard let placemark = try? await CLGeocoder().geocodeAddressString(trimmed).first,
              let coordinate = placemark.location?.coordinate
        else { return nil }

        let locality = placemark.locality?.trimmingCharacters(in: .whitespacesAndNewlines)
        var location = AppLocation(
            label: (locality?.isEmpty == false ? locality! : trimmed),
            latitudeDeg: coordinate.latitude,
            longitudeDeg: coordinate.longitude,
            elevationMeters: 0.0,
            isCustom: true
        )
        if let elevation = await ElevationService.lookupMeters(
            latitudeDeg: location.latitudeDeg, longitudeDeg: location.longitudeDeg) {
            location.elevationMeters = elevation
        }
        return location
    }
}
