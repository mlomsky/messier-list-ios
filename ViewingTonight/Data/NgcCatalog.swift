import Foundation

/// The NGC (New General Catalogue) entries bundled as Resources/ngc_catalog.json (the Android
/// app's assets file, unchanged), scraped from Wikipedia's "List of NGC objects" series.
/// Port of data/NgcCatalog.kt.
nonisolated enum NgcCatalog {

    /// Parsed once, on first use (Swift static lets are lazy and thread-safe).
    static let entries: [NgcEntry] = load(from: Bundle.main)

    static func load(from bundle: Bundle) -> [NgcEntry] {
        guard let url = bundle.url(forResource: "ngc_catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let rows = try? JSONDecoder().decode([Row].self, from: data)
        else {
            assertionFailure("ngc_catalog.json missing or unreadable")
            return []
        }
        return rows.map {
            NgcEntry(
                number: $0.number,
                objectType: $0.objectType,
                raDeg: $0.raDeg,
                decDeg: $0.decDeg,
                apparentMagnitude: $0.magnitude,
                commonName: $0.commonName.flatMap(cleanCommonName)
            )
        }
    }

    private struct Row: Decodable {
        let number: Int
        let objectType: String
        let raDeg: Double
        let decDeg: Double
        let magnitude: Double?
        let commonName: String?
    }

    private static let parentheticalPattern = try! NSRegularExpression(pattern: #"\s*-?\s*\([^)]*\)"#)
    private static let footnotePattern = try! NSRegularExpression(pattern: #"\s*\[[^\]]*\]"#)

    /// Wikipedia's "Other names" column often holds a pure annotation rather than a real name, e.g.
    /// "(Located in Small Magellanic Cloud )" or "(Duplicate of NGC 20 ) [5]". Strips any
    /// parenthesized/bracketed annotation (and a leading "-" separator), returning nil if nothing
    /// but the annotation was there.
    static func cleanCommonName(_ raw: String) -> String? {
        var s = raw
        for re in [parentheticalPattern, footnotePattern] {
            s = re.stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: "")
        }
        let cleaned = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }
}
