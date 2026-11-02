import Foundation

// Port of model/CatalogTarget.kt. Kotlin's sealed interface maps to a Swift enum with associated values.

nonisolated struct MessierEntry: Hashable, Sendable {
    let number: Int
    let objectType: String
    let raDeg: Double
    let decDeg: Double
    let commonName: String?
    let apparentMagnitude: Double
}

nonisolated struct NgcEntry: Hashable, Sendable {
    let number: Int
    let objectType: String
    let raDeg: Double
    let decDeg: Double
    let apparentMagnitude: Double?
    let commonName: String?
}

nonisolated enum CatalogTarget: Hashable, Sendable, Identifiable {
    case messier(MessierEntry)
    case ngc(NgcEntry)
    case planet(Planet)
    case moon(apparentMagnitude: Double)

    /// Stable id, identical to the Android app's ids ("M42", "NGC7000", "JUPITER", "MOON") so
    /// favorites and filter notes mean the same thing on both platforms.
    var id: String {
        switch self {
        case .messier(let m): "M\(m.number)"
        case .ngc(let n): "NGC\(n.number)"
        case .planet(let p): p.rawValue.uppercased()   // Kotlin used the enum constant name
        case .moon: "MOON"
        }
    }

    var displayName: String {
        switch self {
        case .messier(let m): m.commonName.map { "M\(m.number) - \($0)" } ?? "M\(m.number)"
        case .ngc(let n): n.commonName.map { "NGC \(n.number) - \($0)" } ?? "NGC \(n.number)"
        case .planet(let p): p.displayName
        case .moon: "Moon"
        }
    }

    /// A plain-text object type label usable for search/filtering, uniform across all catalog kinds.
    var typeLabel: String {
        switch self {
        case .messier(let m): m.objectType
        case .ngc(let n): n.objectType
        case .planet: "Planet"
        case .moon: "Moon"
        }
    }

    /// Catalog value for Messier/NGC (nil when the NGC table has none), a representative mean for
    /// planets, and the live phase-based value captured when the Moon target was built.
    var apparentMagnitude: Double? {
        switch self {
        case .messier(let m): m.apparentMagnitude
        case .ngc(let n): n.apparentMagnitude
        case .planet(let p): p.meanApparentMagnitude
        case .moon(let mag): mag
        }
    }
}
