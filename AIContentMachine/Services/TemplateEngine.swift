import Foundation

enum TemplateEngine {
    static func makeDefaultTemplates() -> [TemplateModel] {
        [
            TemplateModel(
                name: "Controversial truth",
                description: "Lead with a sharp truth that challenges lazy consensus and earns reactions.",
                category: "Hot Take",
                exampleHook: "The advice everyone repeats about growth is exactly why most people stay invisible.",
                structureRules: ["Hard truth", "Contrast", "Specific example", "Direct CTA"]
            ),
            TemplateModel(
                name: "3 mistakes people make",
                description: "Turn recurring beginner errors into a compact, high-save list format.",
                category: "Educational",
                exampleHook: "Three mistakes creators make before they even hit record.",
                structureRules: ["Numbered list", "Short examples", "Actionable correction", "Save CTA"]
            ),
            TemplateModel(
                name: "Nobody talks about this",
                description: "Frame an overlooked insight with tension and credibility.",
                category: "Insight",
                exampleHook: "Nobody talks about the emotional tax behind consistency.",
                structureRules: ["Hidden angle", "Emotional truth", "Reframe", "Comment CTA"]
            ),
            TemplateModel(
                name: "Stop doing this if you want X",
                description: "Use a strong stop-start pattern for conversion-oriented content.",
                category: "Direct",
                exampleHook: "Stop posting random tips if you want followers who actually buy.",
                structureRules: ["Command", "Reason", "Replacement tactic", "Action CTA"]
            ),
            TemplateModel(
                name: "This is why people fail at X",
                description: "Explain failure through a single overlooked mechanism.",
                category: "Authority",
                exampleHook: "This is why smart people still fail at audience growth.",
                structureRules: ["State failure", "Core cause", "Proof", "Fix"]
            ),
            TemplateModel(
                name: "The real reason behind X",
                description: "Pull back the curtain and explain the hidden driver behind a visible result.",
                category: "Storytelling",
                exampleHook: "The real reason some creators look effortless is boring, not magical.",
                structureRules: ["Reveal", "Mechanism", "Example", "Takeaway"]
            ),
            TemplateModel(
                name: "You think X, but actually Y",
                description: "Use contrast framing to sharpen clarity and spark saves.",
                category: "Myth vs Fact",
                exampleHook: "You think discipline starts with motivation, but actually it starts with friction.",
                structureRules: ["Expectation", "Correction", "Reasoning", "CTA"]
            )
        ]
    }

    static func structureHint(templateName: String?, rules: [String], language: ContentLanguage) -> String {
        guard let templateName, !rules.isEmpty else { return "" }

        let rules = rules.joined(separator: language == .german ? " • " : " • ")

        if language == .german {
            return "Vorlage: \(templateName). Struktur: \(rules)."
        }

        return "Template: \(templateName). Structure: \(rules)."
    }
}
