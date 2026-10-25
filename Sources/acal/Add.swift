import ArgumentParser
import EventKit

struct Add: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Create an event. Prints the new event as JSON.")

    @OptionGroup var fields: EventFields

    func run() {
        guard fields.title != nil else { die("--title is required.", code: Code.usage) }
        let store = openStore()
        let event = EKEvent(eventStore: store)
        fields.apply(to: event, store: store, isNew: true)
        do { try store.save(event, span: .futureEvents, commit: true) } catch { die("Could not save the event: \(error.localizedDescription)") }
        emit(eventObject(event, detailed: true))
    }
}
