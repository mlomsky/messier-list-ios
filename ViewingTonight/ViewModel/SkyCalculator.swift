import Foundation

// The heavy part of MainViewModel.recomputeForCurrentLocation(), as a pure function so it can run
// off the main thread and be unit-tested with a fixed clock.

nonisolated struct SunMoonTimes: Equatable, Sendable {
    var sunrise: Date?
    var sunset: Date?
    var moonrise: Date?
    var moonset: Date?
    var moonIlluminationPercent: Double

    static let empty = SunMoonTimes(sunrise: nil, sunset: nil, moonrise: nil, moonset: nil, moonIlluminationPercent: 0)
}

nonisolated struct SkySnapshot: Sendable {
    let session: ViewingSession
    let sunMoonTimes: SunMoonTimes
    let objects: [ObjectVisibility]
}

nonisolated enum SkyCalculator {

    static func compute(
        location: AppLocation,
        enabledCatalogs: Set<CatalogSource>,
        magnitudeLimit: Double,
        now: Date = .now,
        timeZone: TimeZone = .current,
        ngcEntries: [NgcEntry]? = nil
    ) -> SkySnapshot {
        let session = ViewingSession.forNow(now, timeZone: timeZone)
        let observer = location.observer

        // Sun/moon rise-set are searched over the "observing night" (local noon to local noon,
        // centered on the 6pm-6am session) rather than just the session window itself, so a
        // sunrise/sunset/moonrise/moonset that falls outside 6pm-6am still gets reported instead
        // of showing as missing.
        let sunMoonStart = session.start.addingTimeInterval(-6 * 3600)
        let sunMoonEnd = session.end.addingTimeInterval(6 * 3600)

        let sunWindow = AltitudeSampler.sample(
            observer: observer, position: sunProvider, start: sunMoonStart, end: sunMoonEnd,
            thresholdDeg: RiseSetThresholds.sun)

        let moonParallax = MoonPosition.geocentric(JulianDate.from(session.start)).horizontalParallaxDeg
        let moonThreshold = RiseSetThresholds.moon(horizontalParallaxDeg: moonParallax)
        let moonWindow = AltitudeSampler.sample(
            observer: observer, position: moonProvider, start: sunMoonStart, end: sunMoonEnd,
            thresholdDeg: moonThreshold)

        let nowJd = JulianDate.from(now)
        let sunMoonTimes = SunMoonTimes(
            sunrise: sunWindow.riseTime,
            sunset: sunWindow.setTime,
            moonrise: moonWindow.riseTime,
            moonset: moonWindow.setTime,
            moonIlluminationPercent: MoonPosition.illuminatedFraction(nowJd) * 100.0
        )

        func visibility(_ target: CatalogTarget, threshold: Double = RiseSetThresholds.starOrPlanet) -> ObjectVisibility {
            let position = provider(for: target)
            let window = AltitudeSampler.sample(
                observer: observer, position: position, start: session.start, end: session.end, thresholdDeg: threshold)
            let nowHorizontal = position(nowJd).toHorizontal(observer: observer, jd: nowJd)
            return ObjectVisibility(
                target: target, window: window,
                currentAltitudeDeg: nowHorizontal.altitudeDeg, currentAzimuthDeg: nowHorizontal.azimuthDeg)
        }

        // Same catalog order as Android (Messier, planets, Moon, NGC): it's the tie-break order for sorting.
        var objects: [ObjectVisibility] = []
        if enabledCatalogs.contains(.messier) {
            for entry in MessierCatalog.entries where entry.apparentMagnitude <= magnitudeLimit {
                objects.append(visibility(.messier(entry)))
            }
        }
        if enabledCatalogs.contains(.planets) {
            for planet in Planet.allCases where planet.meanApparentMagnitude <= magnitudeLimit {
                objects.append(visibility(.planet(planet)))
            }
            let moonMagnitude = MoonPosition.apparentMagnitude(nowJd)
            if moonMagnitude <= magnitudeLimit {
                // The Moon's rise/set threshold accounts for its parallax and apparent size (Meeus
                // 15.1), unlike the fixed threshold used for stars and planets.
                objects.append(visibility(.moon(apparentMagnitude: moonMagnitude), threshold: moonThreshold))
            }
        }
        if enabledCatalogs.contains(.ngc) {
            // Filtered by magnitude *before* sampling: the NGC table is large enough that sampling
            // all of it on every recompute would be slow. Entries with no catalog magnitude are kept.
            for entry in ngcEntries ?? NgcCatalog.entries {
                if let mag = entry.apparentMagnitude, mag > magnitudeLimit { continue }
                objects.append(visibility(.ngc(entry)))
            }
        }

        return SkySnapshot(session: session, sunMoonTimes: sunMoonTimes, objects: objects)
    }

    static let sunProvider: EquatorialPositionProvider = { SunPosition.geocentricEquatorial($0) }
    static let moonProvider: EquatorialPositionProvider = { MoonPosition.geocentric($0).equatorial }

    static func provider(for target: CatalogTarget) -> EquatorialPositionProvider {
        switch target {
        case .messier(let m):
            let fixed = EquatorialCoordinates(rightAscensionDeg: m.raDeg, declinationDeg: m.decDeg)
            return { _ in fixed }
        case .ngc(let n):
            let fixed = EquatorialCoordinates(rightAscensionDeg: n.raDeg, declinationDeg: n.decDeg)
            return { _ in fixed }
        case .planet(let p):
            return { PlanetPositions.geocentricEquatorial(p, jd: $0) }
        case .moon:
            return moonProvider
        }
    }
}
