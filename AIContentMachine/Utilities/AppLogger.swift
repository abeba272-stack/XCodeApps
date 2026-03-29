import Foundation

protocol AppLogger: Sendable {
    func debug(_ message: String, category: String)
    func info(_ message: String, category: String)
    func warn(_ message: String, category: String)
    func error(_ message: String, category: String)
}

struct ConsoleAppLogger: AppLogger {
    func debug(_ message: String, category: String) {
#if DEBUG
        print("[DEBUG][\(category)] \(message)")
#endif
    }

    func info(_ message: String, category: String) {
        print("[INFO][\(category)] \(message)")
    }

    func warn(_ message: String, category: String) {
        print("[WARN][\(category)] \(message)")
    }

    func error(_ message: String, category: String) {
        fputs("[ERROR][\(category)] \(message)\n", stderr)
    }
}
