import ArgumentParser

@main
struct Acal: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "acal",
        abstract: "Read and write Calendar events.",
        subcommands: [Auth.self]
    )
}

