import Foundation

/// The search dialog's criteria. Port of ObjectSearchFilter (viewmodel/MainViewModel.kt).
nonisolated struct ObjectSearchFilter: Equatable, Sendable {
    var nameQuery = ""
    var typeQuery = ""
    var direction: String? = nil
    var minAltitudeDeg: Double? = nil

    var isActive: Bool {
        !nameQuery.trimmingCharacters(in: .whitespaces).isEmpty ||
            !typeQuery.trimmingCharacters(in: .whitespaces).isEmpty ||
            direction != nil || minAltitudeDeg != nil
    }
}

/// Filtering and sorting of the object list. Port of MainViewModel.sortObjects / naturalCompare.
nonisolated enum SkySorting {

    static func apply(
        _ objects: [ObjectVisibility],
        mode: SortMode,
        hideBelowHorizon: Bool,
        filter: ObjectSearchFilter,
        favorites: Set<String>
    ) -> [ObjectVisibility] {
        var base = hideBelowHorizon ? objects.filter(\.isVisibleNow) : objects

        let name = filter.nameQuery.trimmingCharacters(in: .whitespaces)
        if !name.isEmpty {
            base = base.filter { $0.target.displayName.range(of: name, options: .caseInsensitive) != nil }
        }
        let type = filter.typeQuery.trimmingCharacters(in: .whitespaces)
        if !type.isEmpty {
            base = base.filter { $0.target.typeLabel.range(of: type, options: .caseInsensitive) != nil }
        }
        if let dir = filter.direction {
            base = base.filter { $0.currentAzimuthDeg.cardinalDirection == dir }
        }
        if let minAlt = filter.minAltitudeDeg {
            base = base.filter { $0.currentAltitudeDeg >= minAlt }
        }

        // Kotlin's sortedBy/sortedWith are stable, Swift's sort is not; stableSorted keeps ties in
        // catalog order so the list comes out the same as on Android.
        let byName: (ObjectVisibility, ObjectVisibility) -> Bool = {
            naturalCompare($0.target.displayName, $1.target.displayName) < 0
        }
        switch mode {
        case .name:
            return base.stableSorted(by: byName)
        case .maxElevation:
            return base.stableSorted { $0.window.maxAltitudeDeg > $1.window.maxAltitudeDeg }
        case .startTime:
            return base.stableSorted { $0.sortableStartTime < $1.sortableStartTime }
        case .endTime:
            return base.stableSorted { $0.sortableEndTime < $1.sortableEndTime }
        case .now:
            return base.filter(\.isVisibleNow).stableSorted { $0.currentAltitudeDeg > $1.currentAltitudeDeg }
        case .favorites:
            return base.filter { favorites.contains($0.target.id) }.stableSorted(by: byName)
        }
    }

    /// Tapping a sort button: Start toggles Start <-> End, and tapping Favorites again returns to Name.
    static func nextMode(current: SortMode, tapped: SortMode) -> SortMode {
        switch (current, tapped) {
        case (.startTime, .startTime): .endTime
        case (.endTime, .startTime): .startTime
        case (.favorites, .favorites): .name
        default: tapped
        }
    }

    /// Compares strings so embedded digit runs sort numerically (M2 < M10) instead of lexically (M10 < M2).
    /// Works on UTF-16 code units, like Kotlin's Char comparison.
    static func naturalCompare(_ a: String, _ b: String) -> Int {
        let x = Array(a.utf16), y = Array(b.utf16)
        func isDigit(_ c: UInt16) -> Bool { c >= 48 && c <= 57 }
        func number(_ s: [UInt16], _ from: Int, _ to: Int) -> Int64 {
            s[from..<to].reduce(Int64(0)) { $0 &* 10 &+ Int64($1 - 48) }
        }
        var i = 0, j = 0
        while i < x.count && j < y.count {
            if isDigit(x[i]) && isDigit(y[j]) {
                var iEnd = i
                while iEnd < x.count && isDigit(x[iEnd]) { iEnd += 1 }
                var jEnd = j
                while jEnd < y.count && isDigit(y[jEnd]) { jEnd += 1 }
                let na = number(x, i, iEnd), nb = number(y, j, jEnd)
                if na != nb { return na < nb ? -1 : 1 }
                i = iEnd
                j = jEnd
            } else {
                if x[i] != y[j] { return Int(x[i]) - Int(y[j]) }
                i += 1
                j += 1
            }
        }
        return (x.count - i) - (y.count - j)
    }
}

nonisolated extension Array {
    /// A stable sort: elements that compare equal keep their original relative order.
    func stableSorted(by areInIncreasingOrder: (Element, Element) -> Bool) -> [Element] {
        enumerated()
            .sorted { a, b in
                if areInIncreasingOrder(a.element, b.element) { return true }
                if areInIncreasingOrder(b.element, a.element) { return false }
                return a.offset < b.offset
            }
            .map(\.element)
    }
}
