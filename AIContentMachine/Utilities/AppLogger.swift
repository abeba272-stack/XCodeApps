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
        Self.write("[DEBUG][\(category)] \(Self.sanitized(message))", to: stdout)
#endif
    }

    func info(_ message: String, category: String) {
#if DEBUG
        Self.write("[INFO][\(category)] \(Self.sanitized(message))", to: stdout)
#endif
    }

    func warn(_ message: String, category: String) {
#if DEBUG
        Self.write("[WARN][\(category)] \(Self.sanitized(message))", to: stdout)
#endif
    }

    func error(_ message: String, category: String) {
#if DEBUG
        Self.write("[ERROR][\(category)] \(Self.sanitized(message))", to: stderr)
#else
        Self.write("[ERROR][\(category)] Operation failed.", to: stderr)
#endif
    }

    private static func write(_ message: String, to stream: UnsafeMutablePointer<FILE>) {
        fputs("\(message)\n", stream)
    }

    private static func sanitized(_ message: String) -> String {
        let replacements: [(pattern: String, template: String)] = [
            (#"(?i)\b[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}\b"#, "<redacted-email>"),
            (#"(?i)\bBearer\s+[A-Za-z0-9\-\._~\+\/]+=*"#, "Bearer <redacted>"),
            (#"(?i)\b(api[_ -]?key|token|password|secret)\b(\s*[:=]\s*)(\"?)([^\"\\s,;]+)(\"?)"#, "$1$2$3<redacted>$5")
        ]

        return replacements.reduce(message.trimmingCharacters(in: .whitespacesAndNewlines)) { partialResult, replacement in
            partialResult.replacingMatches(of: replacement.pattern, withTemplate: replacement.template)
        }
    }
}

private extension String {
    func replacingMatches(of pattern: String, withTemplate template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return self
        }

        let range = NSRange(startIndex..<endIndex, in: self)
        return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: template)
    }
}
