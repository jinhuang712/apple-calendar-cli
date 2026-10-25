import ArgumentParser
import EventKit
import Foundation

enum Repeat: String, ExpressibleByArgument, CaseIterable {
    case daily, weekly, monthly, yearly

    var frequency: EKRecurrenceFrequency {
        switch self {
        case .daily: .daily
        case .weekly: .weekly
        case .monthly: .monthly
        case .yearly: .yearly
        }
    }
}

enum Span: String, ExpressibleByArgument, CaseIterable {
    case this, future

    var ekSpan: EKSpan { self == .this ? .thisEvent : .futureEvents }
}

func endOfDay(_ date: Date) -> Date {
    Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: date) ?? date
}

/// The one calendar with this name or id. Exits when there is none, several, or it is read-only.
func writableCalendar(_ store: EKEventStore, _ name: String) -> EKCalendar {
    let matches = findCalendars(store, [name])
    guard matches.count == 1, let calendar = matches.first else {
        die("The name '\(name)' matches \(matches.count) calendars. Use the id from `acal calendars`.")
    }
    guard calendar.allowsContentModifications else { die("The calendar '\(calendar.title)' is read-only.") }
    return calendar
}

/// The fields of an event, shared by `acal add` and `acal edit`.
struct EventFields: ParsableArguments {
    @Option(help: "Title.")
    var title: String?

    @Option(help: "Start: ISO 8601, or a date with --all-day.")
    var start: String?

    @Option(help: "End: ISO 8601, or a date with --all-day.")
    var end: String?

    @Flag(name: .customLong("all-day"), help: "Make it an all-day event; --start and --end are dates.")
    var allDay = false

    @Option(help: "Location.")
    var location: String?

    @Option(help: "Notes.")
    var notes: String?

    @Option(help: "Link.")
    var url: String?

    @Option(name: .customLong("calendar"), help: "Calendar, by name or id.")
    var calendarName: String?

    @Option(name: .customLong("alarm"), help: "Alarm before the start, such as 10m, 2h or 1d. Repeat for several.")
    var alarms: [String] = []

    @Option(name: .customLong("repeat"), help: "daily, weekly, monthly or yearly.")
    var repeatRule: Repeat?

    @Option(help: "Repeat every this many periods. Needs --repeat.")
    var interval: Int?

    @Option(help: "Stop after this many occurrences. Needs --repeat.")
    var count: Int?

    @Option(help: "Last day of the repeat. Needs --repeat.")
    var until: String?

    func apply(to event: EKEvent, store: EKEventStore, isNew: Bool) {
        if let name = calendarName {
            event.calendar = writableCalendar(store, name)
        } else if isNew {
            guard let fallback = store.defaultCalendarForNewEvents, fallback.allowsContentModifications else {
                die("There is no default calendar. Choose one with --calendar.")
            }
            event.calendar = fallback
        }
        applyText(to: event)
        applyTimes(to: event, isNew: isNew)
        if !alarms.isEmpty { event.alarms = alarms.map { EKAlarm(relativeOffset: -parseOffset($0, option: "--alarm")) } }
        applyRepeat(to: event)
    }

    private func applyText(to event: EKEvent) {
        if let title { event.title = title }
        if let location { event.location = location }
        if let notes { event.notes = notes }
        guard let url else { return }
        guard let parsed = URL(string: url), parsed.scheme != nil else {
            die("--url: '\(url)' is not a link.", code: Code.usage)
        }
        event.url = parsed
    }

    private func applyTimes(to event: EKEvent, isNew: Bool) {
        let newStart = start.map { parseTime($0, option: "--start") }
        let newEnd = end.map { parseTime($0, option: "--end") }
        if isNew, newStart == nil { die("--start is required.", code: Code.usage) }
        guard newStart != nil || newEnd != nil || allDay else { return }
        let dayLong = allDay || event.isAllDay
        for (parsed, name) in [(newStart, "--start"), (newEnd, "--end")] where parsed?.dateOnly == true && !dayLong {
            die("\(name): a date without a time needs --all-day.", code: Code.usage)
        }
        var from = newStart?.date ?? event.startDate ?? Date()
        var upTo = newEnd?.date ?? from.addingTimeInterval(isNew ? 0 : event.endDate.timeIntervalSince(event.startDate))
        if isNew, !dayLong, newEnd == nil { die("--end is required.", code: Code.usage) }
        if dayLong {
            from = Calendar.current.startOfDay(for: from)
            upTo = endOfDay(upTo)
        }
        guard upTo > from else { die("--end must be later than --start.", code: Code.usage) }
        event.isAllDay = dayLong
        event.startDate = from
        event.endDate = upTo
    }

    private func applyRepeat(to event: EKEvent) {
        guard let repeatRule else {
            if interval != nil || count != nil || until != nil { die("--interval, --count and --until need --repeat.", code: Code.usage) }
            return
        }
        if count != nil, until != nil { die("Use --count or --until, not both.", code: Code.usage) }
        var ending: EKRecurrenceEnd?
        if let count { ending = EKRecurrenceEnd(occurrenceCount: count) }
        if let until {
            let parsed = parseTime(until, option: "--until")
            ending = EKRecurrenceEnd(end: parsed.dateOnly ? endOfDay(parsed.date) : parsed.date)
        }
        for rule in event.recurrenceRules ?? [] { event.removeRecurrenceRule(rule) }
        event.addRecurrenceRule(EKRecurrenceRule(recurrenceWith: repeatRule.frequency, interval: interval ?? 1, end: ending))
    }
}
