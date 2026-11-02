import Foundation

/// Julian Date calculations (Meeus, Astronomical Algorithms, ch. 7). Port of astro/JulianDate.kt.
nonisolated enum JulianDate {

    /// Julian Date (UT) for the given instant.
    static func from(_ date: Date) -> Double {
        // Unix epoch (1970-01-01 00:00:00 UTC) = JD 2440587.5
        2440587.5 + date.timeIntervalSince1970 / 86400.0
    }

    /// Julian centuries since J2000.0 (JD 2451545.0).
    static func centuriesSinceJ2000(_ jd: Double) -> Double {
        (jd - 2451545.0) / 36525.0
    }
}
