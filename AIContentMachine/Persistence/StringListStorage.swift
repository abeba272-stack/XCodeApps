import Foundation

enum StringListStorage {
    static func encode(_ values: [String]) -> Data {
        (try? JSONEncoder().encode(values)) ?? Data()
    }

    static func decode(_ data: Data) -> [String] {
        (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }
}
