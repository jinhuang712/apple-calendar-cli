import Foundation

enum Code {
    static let failure: Int32 = 1
    static let usage: Int32 = 2
    static let notAuthorized: Int32 = 3
}

func emit(_ object: [String: Any]) {
    guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys, .withoutEscapingSlashes]),
          let text = String(bytes: data, encoding: .utf8)
    else { die("Could not encode the result as JSON.") }
    print(text)
}

func warn(_ message: String) {
    FileHandle.standardError.write(Data((message + "\n").utf8))
}

func die(_ message: String, code: Int32 = Code.failure) -> Never {
    warn(message)
    exit(code)
}
