import ArgumentParser

struct Acal: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "acal",
        abstract: "Read and write Calendar events.",
        subcommands: []
    )
}

Acal.main()
