import ArgumentParser
import EventKit
import Foundation

struct Remove: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "rm",
        abstract: "Delete an event. Only shows a preview unless --yes is given."
    )

    @Argument(help: "The event id, from `acal events`.")
    var id: String

    @Option(help: "For a repeating event: the start time of the occurrence to delete.")
    var occurrence: String?

    @Option(help: "For a repeating event: delete only this occurrence, or this and the later ones.")
    var span: Span?

    @Flag(help: "Delete for real instead of showing a preview.")
    var yes = false

    func run() {
        let store = openStore()
        let event = chooseOccurrence(store, id: id, occurrence: occurrence, span: span)
        let affected = affectedEvents(store, event)
        guard yes else {
            emit(["preview": true, "events": affected.map { eventObject($0) }])
            return
        }
        let summary = affected.map { eventObject($0) }
        do { try store.remove(event, span: span?.ekSpan ?? .thisEvent, commit: true) } catch {
            die("Could not delete the event: \(error.localizedDescription)")
        }
        emit(["removed": true, "events": summary])
    }

    /// What the delete takes away. For `--span future`, the later occurrences within one year.
    private func affectedEvents(_ store: EKEventStore, _ event: EKEvent) -> [EKEvent] {
        guard span == .future else { return [event] }
        let end = event.startDate.addingTimeInterval(366 * 86400)
        return occurrences(store, from: event.startDate, to: end, calendars: [event.calendar])
            .filter { $0.eventIdentifier == event.eventIdentifier }
    }
}
