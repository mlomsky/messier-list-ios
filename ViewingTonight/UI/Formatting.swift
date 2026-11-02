import Foundation

/// Display formatting shared by the screens (ports of the helpers at the top of MainScreen.kt).
enum Format {
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "h:mm a"
        return f
    }()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEEE, MMM d"
        return f
    }()

    /// "9:05 PM", or "--" when there's no time (e.g. the Moon doesn't set tonight).
    static func time(_ date: Date?, timeZone: TimeZone = .current) -> String {
        guard let date else { return "--" }
        timeFormatter.timeZone = timeZone
        return timeFormatter.string(from: date)
    }

    /// "Sunday, Nov 1"
    static func day(_ date: Date, timeZone: TimeZone = .current) -> String {
        dateFormatter.timeZone = timeZone
        return dateFormatter.string(from: date)
    }

    /// Degrees-minutes-seconds with a hemisphere letter, e.g. 41°2'2"N.
    static func dms(_ value: Double, positive: String, negative: String) -> String {
        let hemisphere = value >= 0 ? positive : negative
        let a = abs(value)
        let degrees = Int(a)
        let minutesFull = (a - Double(degrees)) * 60
        let minutes = Int(minutesFull)
        let seconds = (minutesFull - Double(minutes)) * 60
        return "\(degrees)°\(minutes)'\(String(format: "%.0f", seconds))\"\(hemisphere)"
    }

    static func magnitude(_ mag: Double?) -> String {
        mag.map { String(format: "%.1f", $0) } ?? "--"
    }

    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}
