import Foundation

// Port of data/FilterText.kt.

/// The UHC/OIII/H-Beta/Light Pollution/Other selection backing a filter edit dialog.
nonisolated struct FilterSelection: Equatable, Sendable {
    var uhc = false
    var oiii = false
    var hBeta = false
    var lightPollution = false
    var otherChecked = false
    var otherText = ""
}

nonisolated enum FilterText {
    private static func ci(_ pattern: String) -> NSRegularExpression {
        try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
    }
    private static let uhc = ci("UHC")
    private static let oiii = ci("OIII")
    private static let hBeta = ci("H-?BETA")
    private static let lightPollution = ci(#"LIGHT\s*POLLUTION"#)

    private static func matches(_ re: NSRegularExpression, _ s: String) -> Bool {
        re.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)) != nil
    }
    private static func removing(_ re: NSRegularExpression, from s: String) -> String {
        re.stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: "")
    }

    /// Recovers checkbox state from a stored/default filter string (e.g. "UHC/OIII (near-tie)*").
    static func parse(_ text: String) -> FilterSelection {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return FilterSelection() }
        var rest = text
        for re in [uhc, oiii, hBeta, lightPollution] { rest = removing(re, from: rest) }
        rest = rest.replacingOccurrences(of: "/", with: " ")
            .trimmingCharacters(in: CharacterSet(charactersIn: " ,.-"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return FilterSelection(
            uhc: matches(uhc, text),
            oiii: matches(oiii, text),
            hBeta: matches(hBeta, text),
            lightPollution: matches(lightPollution, text),
            otherChecked: !rest.isEmpty,
            otherText: rest
        )
    }

    /// Builds the stored filter string from checkbox state, in UHC/OIII/H-BETA/Light Pollution/other order.
    static func build(_ s: FilterSelection) -> String {
        var parts: [String] = []
        if s.uhc { parts.append("UHC") }
        if s.oiii { parts.append("OIII") }
        if s.hBeta { parts.append("H-BETA") }
        if s.lightPollution { parts.append("Light Pollution") }
        let other = s.otherText.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.otherChecked && !other.isEmpty { parts.append(other) }
        return parts.joined(separator: "/")
    }
}
