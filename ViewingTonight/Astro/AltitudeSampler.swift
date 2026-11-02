import Foundation

// Port of astro/AltitudeSampler.kt.

nonisolated struct AltitudeSample: Equatable {
    var time: Date
    var altitudeDeg: Double
    var azimuthDeg: Double
}

nonisolated struct VisibilityWindow: Equatable {
    var risesAboveThreshold: Bool
    var alwaysAboveThreshold: Bool
    var riseTime: Date?
    var setTime: Date?
    var maxAltitudeTime: Date
    var maxAltitudeDeg: Double
    var azimuthAtMax: Double
}

/// Samples an object's altitude across [start, end] at `stepMinutes` resolution to find when it
/// crosses `thresholdDeg`, and its peak altitude in the window. A sampling approach (rather than a
/// closed-form rise/set formula) was chosen because it works uniformly for fixed (Messier) and
/// moving (Sun/Moon/planet) targets, and degrades gracefully for circumpolar or never-rising objects.
nonisolated enum AltitudeSampler {

    static func sample(
        observer: Observer,
        position: EquatorialPositionProvider,
        start: Date,
        end: Date,
        thresholdDeg: Double,
        stepMinutes: Int = 2
    ) -> VisibilityWindow {
        let samples = series(observer: observer, position: position, start: start, end: end, stepMinutes: stepMinutes)

        var maxSample = samples[0]
        for s in samples where s.altitudeDeg > maxSample.altitudeDeg { maxSample = s }

        var riseTime: Date?
        var setTime: Date?
        for i in 1..<max(samples.count, 1) {
            let prev = samples[i - 1]
            let curr = samples[i]
            if prev.altitudeDeg < thresholdDeg && curr.altitudeDeg >= thresholdDeg && riseTime == nil {
                riseTime = interpolateCrossing(prev, curr, thresholdDeg: thresholdDeg)
            }
            if prev.altitudeDeg >= thresholdDeg && curr.altitudeDeg < thresholdDeg {
                setTime = interpolateCrossing(prev, curr, thresholdDeg: thresholdDeg)
            }
        }

        let alwaysAbove = samples.allSatisfy { $0.altitudeDeg >= thresholdDeg }
        let everAbove = samples.contains { $0.altitudeDeg >= thresholdDeg }

        return VisibilityWindow(
            risesAboveThreshold: everAbove,
            alwaysAboveThreshold: alwaysAbove,
            riseTime: riseTime,
            setTime: setTime,
            maxAltitudeTime: maxSample.time,
            maxAltitudeDeg: maxSample.altitudeDeg,
            azimuthAtMax: maxSample.azimuthDeg
        )
    }

    /// Samples an object's altitude/azimuth at `stepMinutes` resolution across [start, end], e.g. for charting.
    static func series(
        observer: Observer,
        position: EquatorialPositionProvider,
        start: Date,
        end: Date,
        stepMinutes: Int = 30
    ) -> [AltitudeSample] {
        var samples: [AltitudeSample] = []
        let step = TimeInterval(stepMinutes * 60)
        var t = start
        while t <= end {
            samples.append(sampleAt(t, observer: observer, position: position))
            t = t.addingTimeInterval(step)
        }
        if samples.last?.time != end {
            samples.append(sampleAt(end, observer: observer, position: position))
        }
        return samples
    }

    private static func sampleAt(_ t: Date, observer: Observer, position: EquatorialPositionProvider) -> AltitudeSample {
        let jd = JulianDate.from(t)
        let horizontal = position(jd).toHorizontal(observer: observer, jd: jd)
        return AltitudeSample(time: t, altitudeDeg: horizontal.altitudeDeg, azimuthDeg: horizontal.azimuthDeg)
    }

    private static func interpolateCrossing(_ a: AltitudeSample, _ b: AltitudeSample, thresholdDeg: Double) -> Date {
        let span = b.altitudeDeg - a.altitudeDeg
        if span == 0.0 { return a.time }
        let fraction = (thresholdDeg - a.altitudeDeg) / span
        // Kotlin truncates to whole milliseconds; mirror that so both apps print identical times.
        let durationMillis = (b.time.timeIntervalSince(a.time) * 1000).rounded(.towardZero)
        let offsetMillis = (durationMillis * fraction).rounded(.towardZero)
        return a.time.addingTimeInterval(offsetMillis / 1000)
    }
}
