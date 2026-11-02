import Foundation

/// Approximate geocentric planetary positions using mean Keplerian elements (Standish/JPL,
/// "Keplerian Elements for Approximate Positions of the Major Planets", valid 1800-2050),
/// following the method in Meeus, Astronomical Algorithms, ch. 33. No light-time or aberration
/// correction is applied; expect accuracy on the order of a few arcminutes, which is fine for
/// telling whether a planet is above the horizon but not for precision pointing.
/// Port of astro/PlanetPositions.kt.
nonisolated enum PlanetPositions {

    static func geocentricEquatorial(_ planet: Planet, jd: Double) -> EquatorialCoordinates {
        let t = JulianDate.centuriesSinceJ2000(jd)
        let earth = heliocentricEcliptic(.earth, t: t)
        let body = heliocentricEcliptic(planet.elements, t: t)

        let x = body.x - earth.x
        let y = body.y - earth.y
        let z = body.z - earth.z

        let obliquity = 23.439291 - 0.0130042 * t
        let xEq = x
        let yEq = y * cosDeg(obliquity) - z * sinDeg(obliquity)
        let zEq = y * sinDeg(obliquity) + z * cosDeg(obliquity)

        let ra = normalizeDegrees(atan2Deg(yEq, xEq))
        let r = (xEq * xEq + yEq * yEq + zEq * zEq).squareRoot()
        let dec = asinDeg(zEq / r)

        return EquatorialCoordinates(rightAscensionDeg: ra, declinationDeg: dec)
    }

    private static func heliocentricEcliptic(
        _ elements: OrbitalElements, t: Double
    ) -> (x: Double, y: Double, z: Double) {
        let resolved = elements.at(t)
        let meanAnomaly = normalizeSigned(resolved.l - resolved.longPeri)
        let eccentricAnomaly = solveKepler(meanAnomaly, eccentricity: resolved.e)

        let xOrbit = resolved.a * (cosDeg(eccentricAnomaly) - resolved.e)
        let yOrbit = resolved.a * (1 - resolved.e * resolved.e).squareRoot() * sinDeg(eccentricAnomaly)

        let argPeri = resolved.longPeri - resolved.longNode
        let bigOmega = resolved.longNode
        let incl = resolved.i

        let cosO = cosDeg(bigOmega)
        let sinO = sinDeg(bigOmega)
        let cosW = cosDeg(argPeri)
        let sinW = sinDeg(argPeri)
        let cosI = cosDeg(incl)
        let sinI = sinDeg(incl)

        let x = (cosW * cosO - sinW * sinO * cosI) * xOrbit + (-sinW * cosO - cosW * sinO * cosI) * yOrbit
        let y = (cosW * sinO + sinW * cosO * cosI) * xOrbit + (-sinW * sinO + cosW * cosO * cosI) * yOrbit
        let z = (sinW * sinI) * xOrbit + (cosW * sinI) * yOrbit

        return (x, y, z)
    }

    /// Solves Kepler's equation M = E - e*sin(E) for E, in degrees, via Newton-Raphson.
    private static func solveKepler(_ meanAnomalyDeg: Double, eccentricity: Double) -> Double {
        let m = toRadians(meanAnomalyDeg)
        var e = m + eccentricity * sin(m)
        for _ in 0..<8 {
            let delta = (e - eccentricity * sin(e) - m) / (1 - eccentricity * cos(e))
            e -= delta
        }
        return toDegrees(e)
    }

    private static func normalizeSigned(_ deg: Double) -> Double {
        var d = normalizeDegrees(deg)
        if d > 180.0 { d -= 360.0 }
        return d
    }
}
