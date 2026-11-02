import Foundation

/// Starting filter recommendations for the Messier objects where a specific nebula filter
/// (UHC/OIII/H-beta/Deep-Sky) makes a real difference, ported from the user's notes in the
/// Python Astronomy tool. Keyed by catalog id ("M1", "M8", ...). Objects not listed here have
/// no default — the user can still set their own via the filter button. Port of data/DefaultFilters.kt.
nonisolated enum DefaultFilters {
    static let byId: [String: String] = [
        "M1": "UHC/DEEP-SKY (H-beta *not* recommended).",
        "M8": "UHC/OIII",
        "M16": "UHC/OIII, but H-BETA hurts the view",
        "M17": "OIII/UHC (H-BETA not recommended)",
        "M20": "UHC/H-BETA",
        "M27": "UHC (OIII also useful in showing some inner detail)",
        "M42": "UHC/OIII (near-tie)*",
        "M43": "H-BETA (UHC and Deep-Sky also help)",
        "M57": "UHC/OIII.  UHC does improve it to a degree",
        "M76": "UHC/OIII (H-BETA NOT recommended!)",
        "M97": "OIII/UHC (H-beta *not* recommended)",
    ]
}
