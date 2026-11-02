import Foundation

/// Reduced-accuracy geocentric lunar position (Meeus, Astronomical Algorithms, ch. 47 intro),
/// accurate to about 10' in longitude and 4' in latitude - plenty for rise/set/altitude purposes.
/// Port of astro/MoonPosition.kt.
nonisolated enum MoonPosition {

    struct Result: Equatable {
        var equatorial: EquatorialCoordinates
        var horizontalParallaxDeg: Double
    }

    static func geocentric(_ jd: Double) -> Result {
        let t = JulianDate.centuriesSinceJ2000(jd)

        // Fundamental arguments (degrees).
        let lMoon = normalizeDegrees(218.3164591 + 481267.88134236 * t)  // mean longitude
        let d = normalizeDegrees(297.8502042 + 445267.1115168 * t)       // mean elongation from Sun
        let mSun = normalizeDegrees(357.5291092 + 35999.0502909 * t)     // Sun's mean anomaly
        let mMoon = normalizeDegrees(134.9634114 + 477198.8676313 * t)   // Moon's mean anomaly
        let f = normalizeDegrees(93.2720993 + 483202.0175273 * t)        // argument of latitude

        // Split into partial sums: one long chained expression can stall the Swift type checker.
        var longitude = lMoon
        longitude += 6.289 * sinDeg(mMoon)
        longitude -= 1.274 * sinDeg(mMoon - 2 * d)
        longitude += 0.658 * sinDeg(2 * d)
        longitude -= 0.186 * sinDeg(mSun)
        longitude -= 0.059 * sinDeg(2 * mMoon - 2 * d)
        longitude -= 0.057 * sinDeg(mMoon - 2 * d + mSun)
        longitude += 0.053 * sinDeg(mMoon + 2 * d)
        longitude += 0.046 * sinDeg(2 * d - mSun)
        longitude += 0.041 * sinDeg(mMoon - mSun)
        longitude -= 0.035 * sinDeg(d)
        longitude -= 0.031 * sinDeg(mMoon + mSun)
        longitude -= 0.015 * sinDeg(2 * f - 2 * d)
        longitude += 0.011 * sinDeg(mMoon - 4 * d)

        var latitude = 5.128 * sinDeg(f)
        latitude += 0.281 * sinDeg(mMoon + f)
        latitude += 0.278 * sinDeg(mMoon - f)
        latitude += 0.173 * sinDeg(2 * d - f)
        latitude += 0.055 * sinDeg(2 * d - mMoon + f)
        latitude += 0.046 * sinDeg(2 * d - mMoon - f)
        latitude += 0.033 * sinDeg(2 * d + f)
        latitude += 0.017 * sinDeg(2 * mMoon + f)

        var parallax = 0.9508
        parallax += 0.0518 * cosDeg(mMoon)
        parallax += 0.0095 * cosDeg(mMoon - 2 * d)
        parallax += 0.0078 * cosDeg(2 * d)
        parallax += 0.0028 * cosDeg(2 * mMoon)

        let obliquity = 23.439291 - 0.0130042 * t

        let ra = normalizeDegrees(
            atan2Deg(
                sinDeg(longitude) * cosDeg(obliquity) - tanDeg(latitude) * sinDeg(obliquity),
                cosDeg(longitude)
            )
        )
        let dec = asinDeg(
            sinDeg(latitude) * cosDeg(obliquity) + cosDeg(latitude) * sinDeg(obliquity) * sinDeg(longitude)
        )

        return Result(
            equatorial: EquatorialCoordinates(rightAscensionDeg: ra, declinationDeg: dec),
            horizontalParallaxDeg: parallax
        )
    }

    /// Fraction of the Moon's disk illuminated (0 = new, 1 = full), via Meeus's simpler
    /// geocentric-elongation method (ch. 48): k = (1 - cos(elongation from the Sun)) / 2.
    static func illuminatedFraction(_ jd: Double) -> Double {
        (1 - cosElongationFromSun(jd)) / 2
    }

    /// Approximate apparent visual magnitude for the Moon's current phase, via the standard
    /// phase-angle formula (Explanatory Supplement to the Astronomical Almanac): V = -12.73 +
    /// 0.026|p| + 4e-9 p^4, where p is the phase angle in degrees, approximated here as
    /// 180 minus the geocentric Sun-Moon elongation (full moon at p=0, new moon at p=180).
    static func apparentMagnitude(_ jd: Double) -> Double {
        // elongationDeg is in [0, 180], so phaseAngleDeg is too - no need to take its absolute value.
        let elongationDeg = acosDeg(cosElongationFromSun(jd))
        let phaseAngleDeg = 180.0 - elongationDeg
        return -12.73 + 0.026 * phaseAngleDeg + 4e-9 * pow(phaseAngleDeg, 4.0)
    }

    private static func cosElongationFromSun(_ jd: Double) -> Double {
        let moon = geocentric(jd).equatorial
        let sun = SunPosition.geocentricEquatorial(jd)
        return sinDeg(moon.declinationDeg) * sinDeg(sun.declinationDeg) +
            cosDeg(moon.declinationDeg) * cosDeg(sun.declinationDeg) *
            cosDeg(moon.rightAscensionDeg - sun.rightAscensionDeg)
    }
}
