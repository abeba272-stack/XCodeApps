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
#if DEBUG
        print("[INFO][\(category)] \(message)")
#endif
    }

    func warn(_ message: String, category: String) {
#if DEBUG
        print("[WARN][\(category)] \(message)")
#endif
    }

    func error(_ message: String, category: String) {
        fputs("[ERROR][\(category)] \(message)\n", stderr)
    }
}
