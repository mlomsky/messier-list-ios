import Foundation

/// Mean Keplerian orbital elements at J2000.0 and their rates per Julian century, valid for the
/// epoch range 1800-2050 (Standish, JPL, "Keplerian Elements for Approximate Positions of the
/// Major Planets", 1992). Angles in degrees, semi-major axis in AU. Port of astro/PlanetElements.kt.
nonisolated struct OrbitalElements {
    let a0: Double, aDot: Double
    let e0: Double, eDot: Double
    let i0: Double, iDot: Double
    let l0: Double, lDot: Double
    let longPeri0: Double, longPeriDot: Double
    let longNode0: Double, longNodeDot: Double

    func at(_ t: Double) -> ResolvedElements {
        ResolvedElements(
            a: a0 + aDot * t,
            e: e0 + eDot * t,
            i: i0 + iDot * t,
            l: l0 + lDot * t,
            longPeri: longPeri0 + longPeriDot * t,
            longNode: longNode0 + longNodeDot * t
        )
    }
}

nonisolated struct ResolvedElements {
    let a: Double
    let e: Double
    let i: Double
    let l: Double
    let longPeri: Double
    let longNode: Double
}

nonisolated extension OrbitalElements {
    static let earth = OrbitalElements(
    a0: 1.00000261, aDot: 0.00000562,
    e0: 0.01671123, eDot: -0.00004392,
    i0: -0.00001531, iDot: -0.01294668,
    l0: 100.46457166, lDot: 35999.37244981,
    longPeri0: 102.93768193, longPeriDot: 0.32327364,
    longNode0: 0.0, longNodeDot: 0.0
    )
}

nonisolated enum Planet: String, CaseIterable, Codable {
    case mercury, venus, mars, jupiter, saturn, uranus, neptune

    var displayName: String {
        switch self {
        case .mercury: "Mercury"
        case .venus: "Venus"
        case .mars: "Mars"
        case .jupiter: "Jupiter"
        case .saturn: "Saturn"
        case .uranus: "Uranus"
        case .neptune: "Neptune"
        }
    }

    /// Mean apparent (visual) magnitude, per Wikipedia's "Apparent magnitude" reference table.
    /// Planets vary continuously in brightness depending on their position; this mean value is
    /// a representative figure for display, not a live computation.
    var meanApparentMagnitude: Double {
        switch self {
        case .mercury: 0.23
        case .venus: -4.14
        case .mars: 0.71
        case .jupiter: -2.20
        case .saturn: 0.46
        case .uranus: 5.68
        case .neptune: 7.78
        }
    }

    var elements: OrbitalElements {
        switch self {
        case .mercury: OrbitalElements(
            a0: 0.38709927, aDot: 0.00000037,
            e0: 0.20563593, eDot: 0.00001906,
            i0: 7.00497902, iDot: -0.00594749,
            l0: 252.25032350, lDot: 149472.67411175,
            longPeri0: 77.45779628, longPeriDot: 0.16047689,
            longNode0: 48.33076593, longNodeDot: -0.12534081)
        case .venus: OrbitalElements(
            a0: 0.72333566, aDot: 0.00000390,
            e0: 0.00677672, eDot: -0.00004107,
            i0: 3.39467605, iDot: -0.00078890,
            l0: 181.97909950, lDot: 58517.81538729,
            longPeri0: 131.60246718, longPeriDot: 0.00268329,
            longNode0: 76.67984255, longNodeDot: -0.27769418)
        case .mars: OrbitalElements(
            a0: 1.52371034, aDot: 0.00001847,
            e0: 0.09339410, eDot: 0.00007882,
            i0: 1.84969142, iDot: -0.00813131,
            l0: -4.55343205, lDot: 19140.30268499,
            longPeri0: -23.94362959, longPeriDot: 0.44441088,
            longNode0: 49.55953891, longNodeDot: -0.29257343)
        case .jupiter: OrbitalElements(
            a0: 5.20288700, aDot: -0.00011607,
            e0: 0.04838624, eDot: -0.00013253,
            i0: 1.30439695, iDot: -0.00183714,
            l0: 34.39644051, lDot: 3034.74612775,
            longPeri0: 14.72847983, longPeriDot: 0.21252668,
            longNode0: 100.47390909, longNodeDot: 0.20469106)
        case .saturn: OrbitalElements(
            a0: 9.53667594, aDot: -0.00125060,
            e0: 0.05386179, eDot: -0.00050991,
            i0: 2.48599187, iDot: 0.00193609,
            l0: 49.95424423, lDot: 1222.49362201,
            longPeri0: 92.59887831, longPeriDot: -0.41897216,
            longNode0: 113.66242448, longNodeDot: -0.28867794)
        case .uranus: OrbitalElements(
            a0: 19.18916464, aDot: -0.00196176,
            e0: 0.04725744, eDot: -0.00004397,
            i0: 0.77263783, iDot: -0.00242939,
            l0: 313.23810451, lDot: 428.48202785,
            longPeri0: 170.95427630, longPeriDot: 0.40805281,
            longNode0: 74.01692503, longNodeDot: 0.04240589)
        case .neptune: OrbitalElements(
            a0: 30.06992276, aDot: 0.00026291,
            e0: 0.00859048, eDot: 0.00005105,
            i0: 1.77004347, iDot: 0.00035372,
            l0: -55.12002969, lDot: 218.45945325,
            longPeri0: 44.96476227, longPeriDot: -0.32241464,
            longNode0: 131.78422574, longNodeDot: -0.00508664)
        }
    }
}
