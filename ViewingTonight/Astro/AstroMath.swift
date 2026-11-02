import Foundation

// Port of astro/AstroMath.kt — degree-based trig helpers shared by the astronomy code.

@inline(__always) nonisolated func toRadians(_ deg: Double) -> Double { deg * .pi / 180.0 }
@inline(__always) nonisolated func toDegrees(_ rad: Double) -> Double { rad * 180.0 / .pi }

@inline(__always) nonisolated func clampUnit(_ x: Double) -> Double { min(max(x, -1.0), 1.0) }

nonisolated func sinDeg(_ deg: Double) -> Double { sin(toRadians(deg)) }
nonisolated func cosDeg(_ deg: Double) -> Double { cos(toRadians(deg)) }
nonisolated func tanDeg(_ deg: Double) -> Double { tan(toRadians(deg)) }
nonisolated func asinDeg(_ x: Double) -> Double { toDegrees(asin(clampUnit(x))) }
nonisolated func acosDeg(_ x: Double) -> Double { toDegrees(acos(clampUnit(x))) }
nonisolated func atan2Deg(_ y: Double, _ x: Double) -> Double { toDegrees(atan2(y, x)) }

/// Normalizes an angle in degrees to [0, 360).
/// `truncatingRemainder` matches Kotlin's `%` on Double (result takes the dividend's sign).
nonisolated func normalizeDegrees(_ deg: Double) -> Double {
    var d = deg.truncatingRemainder(dividingBy: 360.0)
    if d < 0 { d += 360.0 }
    return d
}
