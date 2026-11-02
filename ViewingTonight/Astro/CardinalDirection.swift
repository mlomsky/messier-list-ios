import Foundation

// Port of astro/CardinalDirection.kt.

nonisolated enum CompassPoints {
    static let all = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
}

nonisolated extension Double {
    /// Azimuth in degrees (0 = N, 90 = E) to one of the eight compass points.
    var cardinalDirection: String {
        let normalized = (self.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        let index = Int((normalized / 45.0) + 0.5) % 8
        return CompassPoints.all[index]
    }
}
