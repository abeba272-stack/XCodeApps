import Foundation

enum CopyExportService {
    static func formattedPackage(for project: ContentProject) -> String {
        [
            project.title,
            "",
            "Overview",
            project.overview,
            "",
            "Hook",
            project.hook,
            "",
            "Alternate Hooks",
            project.alternateHooks.joined(separator: "\n"),
            "",
            "Script",
            project.script,
            "",
            "Voiceover",
            project.voiceover,
            "",
            "Caption",
            project.caption,
            "",
            "Hashtags",
            project.hashtags.joined(separator: " "),
            "",
            "CTA",
            project.cta,
            "",
            "Shot List",
            project.shotList.joined(separator: "\n"),
            "",
            "Posting Checklist",
            project.postingChecklist.joined(separator: "\n"),
            "",
            "Posting Tip",
            project.postingTip,
            "",
            "Performance Rationale",
            project.performanceRationale
        ]
        .joined(separator: "\n")
    }

    static func sectionText(for section: ContentSection, project: ContentProject) -> String {
        switch section {
        case .overview: project.overview
        case .hook: ([project.hook] + project.alternateHooks).joined(separator: "\n")
        case .script: project.script
        case .caption: project.caption
        case .hashtags: project.hashtags.joined(separator: " ")
        case .cta: project.cta
        case .shotList: project.shotList.joined(separator: "\n")
        case .notes: project.notes
        }
    }

    static func exportURL(profile: UserProfile, settings: AppSettings, projects: [ContentProject], assignments: [PlannerAssignment]) throws -> URL {
        let bundle = ExportBundle(
            profile: profile.snapshot,
            settings: settings.snapshot,
            projects: projects.map(\.snapshot),
            assignments: assignments.map(\.snapshot),
            exportedAt: .now
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(bundle)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("AIContentMachine-Export-\(Int(Date().timeIntervalSince1970)).json")
        try data.write(to: url, options: .atomic)
        return url
    }
}
