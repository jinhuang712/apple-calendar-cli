import ArgumentParser
import EventKit
import Foundation

private let maxRange: TimeInterval = 366 * 86400

/// Every occurrence that starts in the range, in start order.
func occurrences(_ store: EKEventStore, from: Date, to: Date, calendars: [EKCalendar]?) -> [EKEvent] {
    let predicate = store.predicateForEvents(withStart: from, end: to, calendars: calendars)
    return store.events(matching: predicate).sorted { $0.startDate < $1.startDate }
}

/// The occurrence of an event that starts at `occurrence`, or the next one that has not started.
func findOccurrence(_ store: EKEventStore, id: String, occurrence: Date?) -> EKEvent {
    let now = Date()
    if let occurrence {
        let window = occurrences(store, from: occurrence.addingTimeInterval(-86400),
                                 to: occurrence.addingTimeInterval(86400), calendars: nil)
        if let match = window.first(where: { $0.eventIdentifier == id && abs($0.startDate.timeIntervalSince(occurrence)) < 1 }) {
            return match
        }
        die("The event '\(id)' has no occurrence starting at \(formatTime(occurrence)).")
    }
    let upcoming = occurrences(store, from: now, to: now.addingTimeInterval(maxRange), calendars: nil)
    if let next = upcoming.first(where: { $0.eventIdentifier == id }) { return next }
    if let first = store.event(withIdentifier: id) { return first }
    die("No event with the id '\(id)'. It does not exist or was deleted.")
}

struct EventsList: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "events",
        abstract: "List the events in a time range, one JSON object per line."
    )

    @Option(help: "Start of the range: ISO 8601, or a date for the start of that day.")
    var from: String

    @Option(help: "End of the range: ISO 8601, or a date for the end of that day.")
    var to: String

    @Option(name: .customLong("calendar"), help: "Only this calendar, by name or id. Repeat for several.")
    var calendars: [String] = []

    func run() {
        let start = rangeBound(parseTime(from, option: "--from"), upper: false)
        let end = rangeBound(parseTime(to, option: "--to"), upper: true)
        guard end > start else { die("--to must be later than --from.", code: Code.usage) }
        guard end.timeIntervalSince(start) <= maxRange else {
            die("The range is longer than one year. Use a shorter range.", code: Code.usage)
        }
        let store = openStore()
        let chosen = calendars.isEmpty ? nil : findCalendars(store, calendars)
        for event in occurrences(store, from: start, to: end, calendars: chosen) { emit(eventObject(event)) }
    }
}

struct EventDetail: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "event",
        abstract: "Show one event with all its fields."
    )

    @Argument(help: "The event id, from `acal events`.")
    var id: String

    @Option(help: "For a repeating event: the start time of the occurrence to show.")
    var occurrence: String?

    func run() {
        let when = occurrence.map { parseTime($0, option: "--occurrence").date }
        let store = openStore()
        emit(eventObject(findOccurrence(store, id: id, occurrence: when), detailed: true))
    }
}
