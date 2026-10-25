import Foundation

/// A time given on the command line: ISO 8601, or a bare date.
struct ParsedTime {
    let date: Date
    let dateOnly: Bool
}

private let inputPatterns: [(pattern: String, dateOnly: Bool)] = [
    ("yyyy-MM-dd'T'HH:mm:ssXXXXX", false),
    ("yyyy-MM-dd'T'HH:mm:ss", false),
    ("yyyy-MM-dd'T'HH:mm", false),
    ("yyyy-MM-dd", true)
]

private func makeFormatter(_ pattern: String) -> DateFormatter {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = .current
    formatter.dateFormat = pattern
    return formatter
}

/// Reads an ISO 8601 time. A time without an offset is read in the system time zone.
func parseTime(_ text: String, option: String) -> ParsedTime {
    for (pattern, dateOnly) in inputPatterns {
        if let date = makeFormatter(pattern).date(from: text) { return ParsedTime(date: date, dateOnly: dateOnly) }
    }
    die("\(option): cannot read '\(text)'. Use ISO 8601, for example 2026-11-03T15:00:00+08:00 or 2026-11-03.",
        code: Code.usage)
}

private let outputFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.timeZone = .current
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
}()

func formatTime(_ date: Date) -> String {
    outputFormatter.string(from: date)
}

/// A date-only bound is the start of that day, or the end of it (the next midnight) for an upper bound.
func rangeBound(_ parsed: ParsedTime, upper: Bool) -> Date {
    guard parsed.dateOnly, upper else { return parsed.date }
    return Calendar.current.date(byAdding: .day, value: 1, to: parsed.date) ?? parsed.date
}

/// Reads a duration such as 10m, 2h or 1d, in seconds.
func parseOffset(_ text: String, option: String) -> TimeInterval {
    let units: [Character: TimeInterval] = ["m": 60, "h": 3600, "d": 86400]
    guard let unit = text.last, let factor = units[unit], let count = Double(text.dropLast()), count >= 0 else {
        die("\(option): cannot read '\(text)'. Use a number and m, h or d, for example 30m.", code: Code.usage)
    }
    return count * factor
}

func formatOffset(_ seconds: TimeInterval) -> String {
    let value = Int(seconds.rounded())
    if value != 0, value % 86400 == 0 { return "\(value / 86400)d" }
    if value != 0, value % 3600 == 0 { return "\(value / 3600)h" }
    return "\(value / 60)m"
}
