import Foundation

// Port of astro/Coordinates.kt.

nonisolated struct Observer: Equatable, Codable {
    var latitudeDeg: Double
    var longitudeDeg: Double // east-positive
    var elevationMeters: Double = 0.0
}

/// Right ascension and declination, in degrees (equinox of date is close enough to J2000 for this app's purposes).
nonisolated struct EquatorialCoordinates: Equatable {
    var rightAscensionDeg: Double
    var declinationDeg: Double
}

/// Azimuth measured from North, through East (0=N, 90=E, 180=S, 270=W).
nonisolated struct HorizontalCoordinates: Equatable {
    var altitudeDeg: Double
    var azimuthDeg: Double
}

/// Supplies an object's equatorial position at a given Julian Date (constant for fixed deep-sky objects).
/// Kotlin used a `fun interface`; a Swift closure type is the direct equivalent.
typealias EquatorialPositionProvider = (_ jd: Double) -> EquatorialCoordinates

nonisolated extension EquatorialCoordinates {
    /// Converts equatorial coordinates to horizontal (altitude/azimuth) coordinates for an observer,
    /// at the given Julian Date.
    ///
    /// Algorithm: Duffett-Smith & Zwart, "Practical Astronomy with your Calculator or Spreadsheet".
    func toHorizontal(observer: Observer, jd: Double) -> HorizontalCoordinates {
        let lst = SiderealTime.localMeanSiderealTimeDegrees(jd, longitudeDeg: observer.longitudeDeg)
        let hourAngle = normalizeDegrees(lst - rightAscensionDeg)

        let sinAlt = sinDeg(declinationDeg) * sinDeg(observer.latitudeDeg) +
            cosDeg(declinationDeg) * cosDeg(observer.latitudeDeg) * cosDeg(hourAngle)
        let altitude = asinDeg(sinAlt)

        let cosAltRaw = cosDeg(altitude)
        let cosAlt = abs(cosAltRaw) < 1e-9 ? 1e-9 : cosAltRaw

        let cosAz = (sinDeg(declinationDeg) - sinDeg(altitude) * sinDeg(observer.latitudeDeg)) /
            (cosAlt * cosDeg(observer.latitudeDeg))
        var azimuth = acosDeg(cosAz)
        if sinDeg(hourAngle) > 0 {
            azimuth = 360.0 - azimuth
        }

        return HorizontalCoordinates(altitudeDeg: altitude, azimuthDeg: azimuth)
    }
}

/// Standard altitude thresholds (degrees) for rise/set events, accounting for refraction and apparent size.
nonisolated enum RiseSetThresholds {
    static let starOrPlanet = -0.5667
    static let sun = -0.8333

    /// Meeus 15.1: the Moon's threshold depends on its horizontal parallax (degrees).
    static func moon(horizontalParallaxDeg: Double) -> Double {
        0.7275 * horizontalParallaxDeg - 0.5667
    }
}
