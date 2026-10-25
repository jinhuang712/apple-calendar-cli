import ArgumentParser
import EventKit

/// The occurrence to change or remove, after the checks both commands share.
func chooseOccurrence(_ store: EKEventStore, id: String, occurrence: String?, span: Span?) -> EKEvent {
    let when = occurrence.map { parseTime($0, option: "--occurrence").date }
    let event = findOccurrence(store, id: id, occurrence: when)
    guard event.calendar.allowsContentModifications else { die("The calendar '\(event.calendar.title)' is read-only.") }
    if event.hasRecurrenceRules {
        guard let span else { die("This event repeats. Say --span this or --span future.", code: Code.usage) }
        if span == .this, when == nil { die("--span this needs --occurrence.", code: Code.usage) }
    }
    return event
}

struct Edit: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Change an event. Changes to a repeating event only show a preview unless --yes is given."
    )

    @Argument(help: "The event id, from `acal events`.")
    var id: String

    @Option(help: "For a repeating event: the start time of the occurrence to change.")
    var occurrence: String?

    @Option(help: "For a repeating event: change only this occurrence, or this and the later ones.")
    var span: Span?

    @Flag(help: "Apply a change to a repeating event instead of showing a preview.")
    var yes = false

    @OptionGroup var fields: EventFields

    func run() {
        let store = openStore()
        let event = chooseOccurrence(store, id: id, occurrence: occurrence, span: span)
        fields.apply(to: event, store: store, isNew: false)
        if event.hasRecurrenceRules, !yes {
            emit(["preview": true, "span": span?.rawValue ?? "", "event": eventObject(event, detailed: true)])
            store.reset()
            return
        }
        do { try store.save(event, span: span?.ekSpan ?? .thisEvent, commit: true) } catch {
            die("Could not save the event: \(error.localizedDescription)")
        }
        emit(eventObject(event, detailed: true))
    }
}
