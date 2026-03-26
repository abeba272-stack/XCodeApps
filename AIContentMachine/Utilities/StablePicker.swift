import Foundation

enum StablePicker {
    static func index(seed: String, salt: String, upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        let total = (seed + salt).unicodeScalars.reduce(into: 0) { partialResult, scalar in
            partialResult += Int(scalar.value)
        }
        return abs(total) % upperBound
    }

    static func pick(_ values: [String], seed: String, salt: String) -> String {
        guard !values.isEmpty else { return "" }
        return values[index(seed: seed, salt: salt, upperBound: values.count)]
    }

    static func picks(_ values: [String], count: Int, seed: String, salt: String) -> [String] {
        guard !values.isEmpty else { return [] }
        var copy = values
        var selections: [String] = []
        var currentSalt = salt

        for _ in 0..<min(count, values.count) {
            let idx = index(seed: seed, salt: currentSalt, upperBound: copy.count)
            selections.append(copy.remove(at: idx))
            currentSalt += "-\(idx)"
        }

        return selections
    }
}
