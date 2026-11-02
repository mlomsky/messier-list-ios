import Foundation
import Testing
@testable import ViewingTonight

@Suite("View model logic") struct SkyModelTests {

    static let ny = TimeZone(identifier: "America/New_York")!
    static let waa = AppLocation(label: "WAA", latitudeDeg: 41.0340, longitudeDeg: -73.7629, elevationMeters: 0, isCustom: true)
    /// 2026-11-02 03:00 UTC = 2026-11-01 22:00 EST
    static let now = Date(timeIntervalSince1970: 1793588400)

    static func snapshot(_ catalogs: Set<CatalogSource>, limit: Double = 12.0) -> SkySnapshot {
        SkyCalculator.compute(location: waa, enabledCatalogs: catalogs, magnitudeLimit: limit, now: now, timeZone: ny)
    }

    @Test func sessionAndSunMoonTimesMatchKotlin() {
        let s = Self.snapshot([.planets, .messier])
        #expect(s.session.start == Date(timeIntervalSince1970: 1793574000))
        #expect(s.session.end == Date(timeIntervalSince1970: 1793617200))
        func near(_ d: Date?, _ t: TimeInterval) -> Bool { d.map { abs($0.timeIntervalSince1970 - t) <= 0.002 } ?? false }
        #expect(near(s.sunMoonTimes.sunset, 1793569842.066))    // 4:50 pm EST
        #expect(near(s.sunMoonTimes.sunrise, 1793618833.98))    // 6:27 am EST
        #expect(near(s.sunMoonTimes.moonrise, 1793592649.82))   // 11:10 pm EST
        #expect(near(s.sunMoonTimes.moonset, 1793556368.972))
        #expect(abs(s.sunMoonTimes.moonIlluminationPercent - 47.169064689328124) < 1e-6)
    }

    @Test func catalogsAndMagnitudeLimit() {
        let all = Self.snapshot([.planets, .messier])
        #expect(all.objects.count == 110 + 7 + 1)                     // every Messier, 7 planets, the Moon
        #expect(all.objects.first?.target.id == "M1")                 // Messier first, as on Android
        #expect(all.objects.last?.target.id == "MOON")
        if case .moon(let mag)? = all.objects.last?.target { #expect(abs(mag - -10.003214459705628) < 1e-7) }

        let bright = Self.snapshot([.planets, .messier], limit: 5.0)
        #expect(bright.objects.count == 8 + 5 + 1)                   // 8 Messier, Mercury..Saturn, Moon

        let ngc = Self.snapshot([.ngc], limit: 4.5)
        #expect(ngc.objects.count == 449)                            // includes NGC objects with no magnitude
        #expect(Self.snapshot([]).objects.isEmpty)
    }

    @Test func objectVisibilityMatchesKotlin() throws {
        // Search first, then #require: a trailing closure inside the macro trips a "call can throw" error.
        let found = Self.snapshot([.messier]).objects.first { $0.target.id == "M42" }
        let m42 = try #require(found)
        #expect(abs(m42.window.riseTime!.timeIntervalSince1970 - 1793584841.66) <= 0.002)  // 9:00 pm EST
        #expect(m42.window.setTime == nil)
        #expect(m42.window.maxAltitudeTime == Date(timeIntervalSince1970: 1793605440))
        #expect(abs(m42.window.maxAltitudeDeg - 43.5748977118111) < 1e-9)
        #expect(abs(m42.currentAltitudeDeg - 10.40482062908062) < 1e-9)
        #expect(abs(m42.currentAzimuthDeg - 106.64538923788955) < 1e-6)
        #expect(m42.currentAzimuthDeg.cardinalDirection == "E")
        #expect(m42.isVisibleNow)
    }

    @Test func naturalSort() {
        let c = SkySorting.naturalCompare
        #expect(c("M2", "M10") < 0)
        #expect(c("M10", "M2") > 0)
        #expect(c("M42 - Orion Nebula", "M42 - Orion Nebula") == 0)
        #expect(c("NGC 224", "NGC 1976") < 0)
        #expect(c("M4", "M42 - Orion Nebula") < 0)
        #expect(c("Jupiter", "M1") < 0)
        #expect(c("Mars", "M1") > 0)          // 'a' sorts after ' '/digits, same as Kotlin
    }

    @Test func sortButtonCycling() {
        let n = SkySorting.nextMode
        #expect(n(.name, .startTime) == .startTime)
        #expect(n(.startTime, .startTime) == .endTime)
        #expect(n(.endTime, .startTime) == .startTime)
        #expect(n(.favorites, .favorites) == .name)
        #expect(n(.name, .favorites) == .favorites)
        #expect(n(.endTime, .now) == .now)
    }

    // Note: checks like `list.allSatisfy { ... }` are computed into a Bool *before* #expect.
    // Passed straight to #expect, the macro rewrites them and the compiler wrongly reports
    // "call can throw, but it is not marked with 'try'".
    @Test func filteringAndSorting() {
        let objs = Self.snapshot([.planets, .messier]).objects
        func sorted(_ mode: SortMode, hide: Bool = false, filter: ObjectSearchFilter = .init(),
                    favorites: Set<String> = []) -> [ObjectVisibility] {
            SkySorting.apply(objs, mode: mode, hideBelowHorizon: hide, filter: filter, favorites: favorites)
        }
        func ordered(_ list: [ObjectVisibility], _ inOrder: (ObjectVisibility, ObjectVisibility) -> Bool) -> Bool {
            zip(list, list.dropFirst()).allSatisfy { inOrder($0, $1) }
        }

        let names = sorted(.name).map(\.target.displayName)
        let m2 = names.firstIndex(of: "M2") ?? -1, m10 = names.firstIndex(of: "M10") ?? -1
        #expect(m2 >= 0 && m2 < m10)

        let up = sorted(.name, hide: true)
        let upAllVisible = up.allSatisfy { $0.isVisibleNow }
        #expect(upAllVisible)
        #expect(up.count < objs.count)

        let now = sorted(.now)
        let nowAllVisible = now.allSatisfy { $0.isVisibleNow }
        let nowOrdered = ordered(now) { $0.currentAltitudeDeg >= $1.currentAltitudeDeg }
        #expect(nowAllVisible)
        #expect(nowOrdered)

        let tallestOrdered = ordered(sorted(.maxElevation)) { $0.window.maxAltitudeDeg >= $1.window.maxAltitudeDeg }
        #expect(tallestOrdered)

        let startsOrdered = ordered(sorted(.startTime)) { $0.sortableStartTime <= $1.sortableStartTime }
        #expect(startsOrdered)
        let endsOrdered = ordered(sorted(.endTime)) { $0.sortableEndTime <= $1.sortableEndTime }
        #expect(endsOrdered)

        let favIds = sorted(.favorites, favorites: ["M31", "JUPITER", "M2"]).map(\.target.id)
        #expect(favIds == ["JUPITER", "M2", "M31"])

        let orionIds = sorted(.name, filter: .init(nameQuery: " orion ")).map(\.target.id)
        #expect(orionIds == ["M42"])

        let globs = sorted(.name, filter: .init(typeQuery: "GLOBULAR"))
        let allGlobular = globs.allSatisfy { $0.target.typeLabel == "Globular cluster" }
        #expect(globs.count == 29)
        #expect(allGlobular)

        let east = sorted(.name, filter: .init(direction: "E"))
        let allEast = east.allSatisfy { $0.currentAzimuthDeg.cardinalDirection == "E" }
        #expect(east.count > 0)
        #expect(allEast)

        let high = sorted(.name, filter: .init(minAltitudeDeg: 45))
        let allHigh = high.allSatisfy { $0.currentAltitudeDeg >= 45 }
        #expect(high.count > 0)
        #expect(allHigh)

        let activeWithAltitude = ObjectSearchFilter(minAltitudeDeg: 45).isActive
        let activeWithBlankName = ObjectSearchFilter(nameQuery: "  ").isActive
        #expect(activeWithAltitude)
        #expect(!activeWithBlankName)
    }
}
