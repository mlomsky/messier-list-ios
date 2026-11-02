import Foundation

/// Low-precision solar position (Meeus, Astronomical Algorithms, ch. 25).
/// Accurate to about 0.01 degrees in geocentric apparent RA/Dec. Port of astro/SunPosition.kt.
nonisolated enum SunPosition {
    static func geocentricEquatorial(_ jd: Double) -> EquatorialCoordinates {
        let t = JulianDate.centuriesSinceJ2000(jd)

        let l0 = normalizeDegrees(280.46646 + 36000.76983 * t + 0.0003032 * t * t)
        let m = normalizeDegrees(357.52911 + 35999.05029 * t - 0.0001537 * t * t)

        let c = (1.914602 - 0.004817 * t - 0.000014 * t * t) * sinDeg(m) +
            (0.019993 - 0.000101 * t) * sinDeg(2 * m) +
            0.000289 * sinDeg(3 * m)

        let trueLongitude = l0 + c

        let omega = normalizeDegrees(125.04 - 1934.136 * t)
        let apparentLongitude = trueLongitude - 0.00569 - 0.00478 * sinDeg(omega)

        let meanObliquity = 23.439291 - 0.0130042 * t - 0.00000016 * t * t + 0.000000504 * t * t * t
        let correctedObliquity = meanObliquity + 0.00256 * cosDeg(omega)

        let ra = normalizeDegrees(
            atan2Deg(
                cosDeg(correctedObliquity) * sinDeg(apparentLongitude),
                cosDeg(apparentLongitude)
            )
        )
        let dec = asinDeg(sinDeg(correctedObliquity) * sinDeg(apparentLongitude))

        return EquatorialCoordinates(rightAscensionDeg: ra, declinationDeg: dec)
    }
}
