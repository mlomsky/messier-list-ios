import Foundation

/// Greenwich/local sidereal time (Meeus, Astronomical Algorithms, ch. 12). Port of astro/SiderealTime.kt.
nonisolated enum SiderealTime {

    /// Greenwich Mean Sidereal Time in degrees, normalized to [0, 360).
    static func greenwichMeanSiderealTimeDegrees(_ jd: Double) -> Double {
        let t = JulianDate.centuriesSinceJ2000(jd)
        let gmst = 280.46061837 +
            360.98564736629 * (jd - 2451545.0) +
            0.000387933 * t * t -
            (t * t * t) / 38710000.0
        return normalizeDegrees(gmst)
    }

    /// Local Mean Sidereal Time in degrees, normalized to [0, 360). `longitudeDeg` is east-positive.
    static func localMeanSiderealTimeDegrees(_ jd: Double, longitudeDeg: Double) -> Double {
        normalizeDegrees(greenwichMeanSiderealTimeDegrees(jd) + longitudeDeg)
    }
}
