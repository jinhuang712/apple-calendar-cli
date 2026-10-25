import ArgumentParser
import EventKit
import Foundation

/// Runs one AppleScript line in the Calendar app. Exits with code 3 when the terminal may not control Calendar.
@discardableResult
func runAppleScript(_ script: String) -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    process.arguments = ["-e", script]
    let output = Pipe()
    let errors = Pipe()
    process.standardOutput = output
    process.standardError = errors
    do { try process.run() } catch { die("Could not start osascript: \(error.localizedDescription)") }
    process.waitUntilExit()
    let message = String(bytes: errors.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    guard process.terminationStatus == 0 else {
        if message.contains("-1743") {
            die("This terminal may not control Calendar. Allow it in System Settings > Privacy & Security > Automation.",
                code: Code.notAuthorized)
        }
        die("Calendar did not do it: \(message.trimmingCharacters(in: .whitespacesAndNewlines))")
    }
    return String(bytes: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
}

/// Text that is safe inside an AppleScript string. Exits when it is not.
private func scriptText(_ text: String, option: String) -> String {
    guard !text.contains("\""), !text.contains("\\"), !text.contains("\n") else {
        die("\(option): quotes, backslashes and line breaks are not allowed.", code: Code.usage)
    }
    return text
}

struct Subscribe: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Start a subscription. Calendar asks the user to confirm twice."
    )

    @Argument(help: "A webcal:// or https:// address of an .ics calendar.")
    var address: String

    func run() {
        guard let url = URL(string: address), ["webcal", "http", "https"].contains(url.scheme ?? "") else {
            die("'\(address)' is not a webcal://, http:// or https:// address.", code: Code.usage)
        }
        let safe = scriptText(address, option: "address")
        runAppleScript("tell application \"Calendar\" to GetURL \"\(safe)\"")
        emit(["status": "awaitingConfirmation"])
    }
}

struct Unsubscribe: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Remove a subscribed calendar. Only shows a preview unless --yes is given."
    )

    @Argument(help: "The calendar id, from `acal calendars`.")
    var id: String

    @Flag(help: "Remove for real instead of showing a preview.")
    var yes = false

    func run() {
        let store = openStore()
        let all = store.calendars(for: .event)
        guard let calendar = all.first(where: { $0.calendarIdentifier == id }) else {
            die("No calendar with the id '\(id)'. See `acal calendars`.")
        }
        guard calendar.type == .subscription else {
            die("The calendar '\(calendar.title)' is not a subscription. Only subscriptions can be removed here.")
        }
        guard yes else {
            emit(["preview": true, "calendar": calendarObject(calendar), "events": eventsNearby(store, calendar)])
            return
        }
        guard all.filter({ $0.title == calendar.title }).count == 1 else {
            die("Several calendars are named '\(calendar.title)', so the subscription cannot be picked by name.")
        }
        let name = scriptText(calendar.title, option: "calendar title")
        runAppleScript("tell application \"Calendar\" to delete (first calendar whose name is \"\(name)\")")
        guard waitUntilGone(calendar.calendarIdentifier) else {
            die("Calendar accepted the command, but '\(calendar.title)' is still there.")
        }
        emit(["removed": true, "calendar": calendarObject(calendar)])
    }

    /// The number of events within a year before and after now.
    private func eventsNearby(_ store: EKEventStore, _ calendar: EKCalendar) -> Int {
        let now = Date()
        let year: TimeInterval = 365 * 86400
        return occurrences(store, from: now - year, to: now + year, calendars: [calendar]).count
    }

    private func waitUntilGone(_ calendarID: String) -> Bool {
        for _ in 0..<10 {
            if !EKEventStore().calendars(for: .event).contains(where: { $0.calendarIdentifier == calendarID }) { return true }
            Thread.sleep(forTimeInterval: 0.5)
        }
        return false
    }
}

struct Refresh: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Ask Calendar to reload all calendars.")

    func run() {
        runAppleScript("tell application \"Calendar\" to reload calendars")
        emit(["requested": true])
    }
}
