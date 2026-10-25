import ArgumentParser
import EventKit

enum AuthStatus: String {
    case granted, denied, writeOnly, notDetermined, restricted

    init(_ status: EKAuthorizationStatus) {
        switch status {
        case .fullAccess: self = .granted
        case .writeOnly: self = .writeOnly
        case .denied: self = .denied
        case .restricted: self = .restricted
        default: self = .notDetermined
        }
    }

    static var current: AuthStatus { AuthStatus(EKEventStore.authorizationStatus(for: .event)) }

    /// What the user can do next, or nil when nothing is wrong.
    var hint: String? {
        switch self {
        case .granted: nil
        case .notDetermined: "Run `acal auth --request` to show the system authorization prompt."
        case .denied, .writeOnly:
            "Open System Settings > Privacy & Security > Calendars and give this terminal Full Access."
        case .restricted: "Calendar access is restricted on this Mac, for example by a profile."
        }
    }
}

struct Auth: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Show calendar authorization, or ask for it.")

    @Flag(help: "Show the system prompt when the status is notDetermined.")
    var request = false

    func run() async throws {
        if request, AuthStatus.current == .notDetermined {
            _ = try? await EKEventStore().requestFullAccessToEvents()
        }
        let status = AuthStatus.current
        emit(["status": status.rawValue])
        if let hint = status.hint { warn(hint) }
        if request, status != .granted { throw ExitCode(Code.notAuthorized) }
    }
}
