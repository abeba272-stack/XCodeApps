import Foundation

enum DailyPromptProvider {
    static func prompt(for date: Date, niches: [String], language: ContentLanguage) -> String {
        let niche = niches.isEmpty ? (language == .german ? "dein Thema" : "your niche") : niches[StablePicker.index(seed: ISO8601DateFormatter().string(from: date), salt: "niche", upperBound: niches.count)]

        let promptsEn = [
            "Record a 20-second myth-vs-fact about \(niche) that challenges a common belief.",
            "Create a before/after post about one habit that changes outcomes in \(niche).",
            "Turn one unpopular truth in \(niche) into a short punchy hook and CTA.",
            "Show the mistake beginners make in \(niche) and how to fix it in three beats."
        ]

        let promptsDe = [
            "Nimm ein 20-Sekunden-Mythos-vs-Fakt-Video zu \(niche) auf, das eine gaengige Annahme zerlegt.",
            "Erstelle einen Vorher-Nachher-Post ueber eine Gewohnheit, die in \(niche) alles veraendert.",
            "Formuliere eine unbequeme Wahrheit aus \(niche) als kurzen Hook mit klarer CTA.",
            "Zeig den Fehler, den Anfaenger in \(niche) machen, und loese ihn in drei klaren Schritten."
        ]

        return StablePicker.pick(language == .german ? promptsDe : promptsEn, seed: ISO8601DateFormatter().string(from: date), salt: "daily-prompt")
    }
}
