import ArgumentParser
import EventKit

/// Calendars matching a name or an id. A name can match several calendars.
func findCalendars(_ store: EKEventStore, _ names: [String]) -> [EKCalendar] {
    let all = store.calendars(for: .event)
    return names.flatMap { name -> [EKCalendar] in
        let matches = all.filter { $0.calendarIdentifier == name || $0.title == name }
        if matches.isEmpty { die("No calendar named or with the id '\(name)'. See `acal calendars`.") }
        return matches
    }
}

struct Calendars: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "List all calendars, one JSON object per line.")

    func run() {
        let store = openStore()
        for calendar in store.calendars(for: .event) { emit(calendarObject(calendar)) }
    }
}
