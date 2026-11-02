import Foundation

/// One observing session runs from 6pm local time to 6am the next day. If "now" is at or after
/// 6am, the upcoming/current session is tonight 6pm -> tomorrow 6am. If "now" is between midnight
/// and 6am, we're in the tail end of the session that started the previous evening, so the window
/// is yesterday 6pm -> today 6am. Port of model/ViewingSession.kt.
nonisolated struct ViewingSession: Equatable, Sendable {
    let start: Date
    let end: Date
    let timeZone: TimeZone

    static let sessionStartHour = 18
    static let sessionEndHour = 6

    static func forNow(_ now: Date = .now, timeZone: TimeZone = .current) -> ViewingSession {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone

        let today = cal.startOfDay(for: now)
        let hour = cal.component(.hour, from: now)
        let startDay = hour < sessionEndHour ? cal.date(byAdding: .day, value: -1, to: today)! : today
        let endDay = cal.date(byAdding: .day, value: 1, to: startDay)!

        // Build from calendar components (not date(bySettingHour:of:), which can roll forward a day)
        // so DST-change nights come out right, e.g. the 13-hour fall-back night.
        let start = at(hour: sessionStartHour, on: startDay, cal)
        let end = at(hour: sessionEndHour, on: endDay, cal)
        return ViewingSession(start: start, end: end, timeZone: timeZone)
    }

    private static func at(hour: Int, on day: Date, _ cal: Calendar) -> Date {
        var c = cal.dateComponents([.year, .month, .day], from: day)
        c.hour = hour
        c.minute = 0
        c.second = 0
        return cal.date(from: c)!
    }
}
