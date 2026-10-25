import ArgumentParser

@main
struct Acal: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "acal",
        abstract: "Read and write Calendar events.",
        version: "0.1.0",
        subcommands: [
            Auth.self, Calendars.self, EventsList.self, EventDetail.self,
            Add.self, Edit.self, Remove.self,
            Subscribe.self, Unsubscribe.self, Refresh.self
        ]
    )
}
