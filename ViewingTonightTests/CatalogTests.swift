import Foundation
import Testing
@testable import ViewingTonight

@Suite("Catalogs and models") struct CatalogTests {

    @Test func messierCatalog() {
        let all = MessierCatalog.entries
        #expect(all.count == 110)
        #expect(all.map(\.number) == Array(1...110))
        let m42 = all[41]
        #expect(m42.commonName == "Orion Nebula")
        #expect(m42.raDeg == 83.8221 && m42.decDeg == -5.3911 && m42.apparentMagnitude == 4.0)
        #expect(CatalogTarget.messier(m42).id == "M42")
        #expect(CatalogTarget.messier(m42).displayName == "M42 - Orion Nebula")
        #expect(CatalogTarget.messier(all[1]).displayName == "M2")
    }

    @Test func ngcCatalogLoadsFromBundle() {
        let all = NgcCatalog.entries
        #expect(all.count == 4016)
        #expect(all.filter { $0.commonName != nil }.count == 380)
        #expect(all.filter { $0.apparentMagnitude == nil }.count == 425)
        let northAmerica = all.first { $0.number == 7000 }
        #expect(northAmerica?.commonName == "North America Nebula")
        #expect(northAmerica?.apparentMagnitude == 4.0)
        let whirlpool = all.first { $0.number == 5194 }
        #expect(whirlpool?.commonName == "Messier 51a Whirlpool Galaxy")
        if let n = northAmerica {
            #expect(CatalogTarget.ngc(n).id == "NGC7000")
            #expect(CatalogTarget.ngc(n).displayName == "NGC 7000 - North America Nebula")
        }
    }

    @Test func ngcNameCleanup() {
        #expect(NgcCatalog.cleanCommonName("(Located in Small Magellanic Cloud )") == nil)
        #expect(NgcCatalog.cleanCommonName("(Duplicate of NGC 20 ) [5]") == nil)
        #expect(NgcCatalog.cleanCommonName("Bubble Nebula - (part of Sh2-162)") == "Bubble Nebula")
        #expect(NgcCatalog.cleanCommonName("Messier 51a [ 5 ] Whirlpool Galaxy") == "Messier 51a Whirlpool Galaxy")
    }

    @Test func targetIdsMatchAndroid() {
        #expect(CatalogTarget.planet(.jupiter).id == "JUPITER")
        #expect(CatalogTarget.planet(.jupiter).displayName == "Jupiter")
        #expect(CatalogTarget.planet(.jupiter).typeLabel == "Planet")
        #expect(CatalogTarget.moon(apparentMagnitude: -10).id == "MOON")
        #expect(CatalogTarget.moon(apparentMagnitude: -10).typeLabel == "Moon")
    }

    @Test func filterTextParsing() {
        #expect(FilterText.parse("") == FilterSelection())
        #expect(FilterText.parse("   ") == FilterSelection())
        #expect(FilterText.parse("UHC/OIII (near-tie)*") ==
                FilterSelection(uhc: true, oiii: true, otherChecked: true, otherText: "(near-tie)*"))
        #expect(FilterText.parse("UHC/DEEP-SKY (H-beta *not* recommended).") ==
                FilterSelection(uhc: true, hBeta: true, otherChecked: true, otherText: "DEEP-SKY ( *not* recommended)"))
        #expect(FilterText.parse("light   pollution") == FilterSelection(lightPollution: true))
        #expect(FilterText.parse("UHC/H-BETA") == FilterSelection(uhc: true, hBeta: true))
    }

    @Test func filterTextBuilding() {
        #expect(FilterText.build(FilterSelection(uhc: true, hBeta: true, lightPollution: true,
                                                 otherChecked: true, otherText: "  Deep-Sky ")) ==
                "UHC/H-BETA/Light Pollution/Deep-Sky")
        #expect(FilterText.build(FilterSelection(oiii: true, otherChecked: false, otherText: "ignored")) == "OIII")
        #expect(FilterText.build(FilterSelection()) == "")
        // Round trip
        let s = FilterSelection(uhc: true, oiii: true, otherChecked: true, otherText: "my note")
        #expect(FilterText.parse(FilterText.build(s)) == s)
    }

    @Test func viewingSessionWindows() {
        let ny = TimeZone(identifier: "America/New_York")!
        func utc(_ s: TimeInterval) -> Date { Date(timeIntervalSince1970: s) }
        // 2026-11-01 19:00 EST -> tonight 18:00 EST (23:00Z) to tomorrow 06:00 EST (11:00Z)
        var s = ViewingSession.forNow(utc(1793577600), timeZone: ny)
        #expect(s.start == utc(1793574000) && s.end == utc(1793617200))
        // 2026-11-02 03:00 EST -> still the session that started last evening
        s = ViewingSession.forNow(utc(1793606400), timeZone: ny)
        #expect(s.start == utc(1793574000) && s.end == utc(1793617200))
        // DST fall-back night: 2026-11-01 05:00 EST -> Oct 31 18:00 EDT (22:00Z) to Nov 1 06:00 EST (11:00Z), 13 h
        s = ViewingSession.forNow(utc(1793527200), timeZone: ny)
        #expect(s.start == utc(1793484000) && s.end == utc(1793530800))
        #expect(s.end.timeIntervalSince(s.start) == 13 * 3600)
        // Summer midday: 2026-07-04 12:00 EDT -> 18:00 EDT (22:00Z) to Jul 5 06:00 EDT (10:00Z)
        s = ViewingSession.forNow(utc(1783180800), timeZone: ny)
        #expect(s.start == utc(1783202400) && s.end == utc(1783245600))
    }

    @MainActor @Test func settingsPersist() {
        let suite = "CatalogTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let a = AppSettings(defaults: defaults)
        #expect(a.enabledCatalogs == [.planets, .messier])
        #expect(a.ngcMagnitudeLimit == 12.0)
        #expect(a.filterText(for: "M42") == "UHC/OIII (near-tie)*")
        a.nightMode = true
        a.setCatalog(.ngc, enabled: true)
        a.setCatalog(.planets, enabled: false)
        a.ngcMagnitudeLimit = 9.5
        a.toggleFavorite("M31"); a.toggleFavorite("JUPITER"); a.toggleFavorite("JUPITER")
        a.setFilter("OIII", for: "M42")
        a.setFilter("UHC", for: "M57"); a.setFilter("  ", for: "M57")

        let b = AppSettings(defaults: defaults)   // fresh instance reads what was saved
        #expect(b.nightMode)
        #expect(b.enabledCatalogs == [.messier, .ngc])
        #expect(b.ngcMagnitudeLimit == 9.5)
        #expect(b.favorites == ["M31"])
        #expect(b.filterText(for: "M42") == "OIII")
        #expect(b.filterText(for: "M57") == "UHC/OIII.  UHC does improve it to a degree")
    }
}
