import Foundation

enum CopyExportService {
    static func formattedPackage(for project: ContentProject) -> String {
        var lines = [
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

        let videoPrompt = videoPromptText(for: project)
        if !videoPrompt.isEmpty {
            lines += [
                "",
                "Video AI Prompt",
                videoPrompt
            ]
        }

        return lines.joined(separator: "\n")
    }

    static func formattedPackage(for session: GenerationSession) -> String {
        formattedPackage(for: session.asContentProject())
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

    static func sectionText(for section: ContentSection, session: GenerationSession) -> String {
        sectionText(for: section, project: session.asContentProject())
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

    static func videoPromptText(for project: ContentProject) -> String {
        VideoPromptBuilder.makePrompt(for: project)
    }

    static func videoPromptText(for session: GenerationSession) -> String {
        videoPromptText(for: session.asContentProject())
    }
}

enum VideoPromptBuilder {
    static func makePrompt(for project: ContentProject) -> String {
        guard project.generationMode != .batchIdeas else { return "" }

        let sections = [
            section("HOOK_VISUAL", hookVisual(for: project)),
            section("SCENE", scene(for: project)),
            section("CAMERA", camera(for: project)),
            section("MOTION", motion(for: project)),
            section("STYLE", style(for: project)),
            section("LIGHTING", lighting(for: project)),
            section("SOUND", sound(for: project)),
            section("DURATION", "3-5 seconds")
        ]

        return sections.joined(separator: "\n\n")
    }

    private static func contentBeats(for project: ContentProject) -> [String] {
        let scriptLines = project.script
            .split(separator: "\n")
            .map(String.init)
            .map {
                $0.replacingOccurrences(of: #"^\d+\.\s*"#, with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }

        if !scriptLines.isEmpty {
            return scriptLines
        }

        return [
            project.hook,
            project.overview,
            project.caption,
            project.cta
        ]
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
    }

    private static func section(_ title: String, _ value: String) -> String {
        "[\(title)]\n\(value)"
    }

    private static func hookVisual(for project: ContentProject) -> String {
        let hook = clipped(primaryFocus(for: project), wordLimit: 12)
        let shot = clipped(primaryShot(for: project), wordLimit: 10)

        if project.language == .german {
            return "Sofortige Nahaufnahme mit \(shot.lowercased()) und direktem Hook-Moment: \(hook)"
        }

        return "Immediate close-up with \(shot.lowercased()) and the hook landing fast: \(hook)"
    }

    private static func scene(for project: ContentProject) -> String {
        let setting = clipped(sceneSetting(for: project), wordLimit: 12)
        let topic = clipped(topicFocus(for: project), wordLimit: 10)

        if project.language == .german {
            return "\(setting) mit Fokus auf \(topic) im Hochformat."
        }

        return "\(setting) with the subject locked on \(topic) in vertical frame."
    }

    private static func camera(for project: ContentProject) -> String {
        switch project.platform {
        case .tiktok:
            return project.language == .german
                ? "Schneller Close-up mit leichtem Push-in."
                : "Fast close-up with a slight push-in."
        case .instagramReels:
            return project.language == .german
                ? "Sauberer Tracking-Shot mit ruhigem Mini-Zoom."
                : "Clean tracking shot with a soft mini-zoom."
        case .youtubeShorts:
            return project.language == .german
                ? "Direkter Mid-to-Close Shot mit kleinem Vorwaertszug."
                : "Direct mid-to-close shot with a subtle push forward."
        case .x:
            return project.language == .german
                ? "Statischer Close-up mit leichtem Text- oder Screen-Pan."
                : "Static close-up with a slight text or screen pan."
        }
    }

    private static func motion(for project: ContentProject) -> String {
        let beat = clipped(secondaryFocus(for: project), wordLimit: 12)
        let action = motionAction(for: project)

        if project.language == .german {
            return "\(action), waehrend \(beat.lowercased()) visuell klar gezeigt wird."
        }

        return "\(action) while \(beat.lowercased()) is shown in one clear action."
    }

    private static func style(for project: ContentProject) -> String {
        switch project.platform {
        case .tiktok:
            return project.language == .german
                ? "Schnell, viral, kontrastreich, \(project.tone.rawValue.lowercased())."
                : "Fast, viral, high-contrast, \(project.tone.rawValue.lowercased())."
        case .instagramReels:
            return project.language == .german
                ? "Clean, hochwertig, modern, \(project.tone.rawValue.lowercased())."
                : "Clean, premium, modern, \(project.tone.rawValue.lowercased())."
        case .youtubeShorts:
            return project.language == .german
                ? "Scharf, autoritaetsstark, high-retention, \(project.tone.rawValue.lowercased())."
                : "Sharp, authoritative, high-retention, \(project.tone.rawValue.lowercased())."
        case .x:
            return project.language == .german
                ? "Reduziert, text-first, meinungsstark, \(project.tone.rawValue.lowercased())."
                : "Minimal, text-first, opinionated, \(project.tone.rawValue.lowercased())."
        }
    }

    private static func lighting(for project: ContentProject) -> String {
        switch project.tone {
        case .dark:
            return project.language == .german
                ? "Hartes Kontrastlicht mit tiefen Schatten und kalten Highlights."
                : "High contrast with deep shadows and cold highlights."
        case .luxury:
            return project.language == .german
                ? "Weiches Premium-Licht mit sauberen Reflexen und edlen Highlights."
                : "Soft premium light with polished reflections and refined highlights."
        case .emotional:
            return project.language == .german
                ? "Warme, gerichtete Beleuchtung mit sanftem Glow."
                : "Warm directional light with a soft glow."
        case .educational:
            return project.language == .german
                ? "Klares, helles Licht mit sauberer Trennung vom Hintergrund."
                : "Clean bright light with clear subject separation."
        default:
            return project.language == .german
                ? "Sauberes Kontrastlicht mit klarer Figur und starkem Fokus."
                : "Clean contrast lighting with strong subject focus."
        }
    }

    private static func sound(for project: ContentProject) -> String {
        switch project.platform {
        case .tiktok:
            return project.language == .german
                ? "Kurzer Impact, leichtes Whoosh, enge Atmo."
                : "Short impact hit, light whoosh, tight room tone."
        case .instagramReels:
            return project.language == .german
                ? "Sauberer Hit, weiche Atmo, dezenter Beat-Pulse."
                : "Clean hit, soft ambience, subtle beat pulse."
        case .youtubeShorts:
            return project.language == .german
                ? "Klarer Hit, dezente Atmo, fokussierter Voice space."
                : "Clean hit, subtle ambience, focused voice space."
        case .x:
            return project.language == .german
                ? "Minimaler Hit, dezente Tastatur- oder Screen-Textur."
                : "Minimal hit, subtle keyboard or screen texture."
        }
    }

    private static func primaryFocus(for project: ContentProject) -> String {
        preferredLine(
            from: [
                project.hook,
                project.contentAngle,
                project.overview,
                project.topic
            ],
            fallback: project.topic
        )
    }

    private static func secondaryFocus(for project: ContentProject) -> String {
        let beats = contentBeats(for: project)
        if beats.count > 1 {
            return beats[1]
        }
        return preferredLine(
            from: [
                project.cta,
                project.caption,
                project.overview,
                project.topic
            ],
            fallback: project.topic
        )
    }

    private static func topicFocus(for project: ContentProject) -> String {
        preferredLine(
            from: [
                project.topic,
                project.title,
                project.category
            ],
            fallback: project.category
        )
    }

    private static func sceneSetting(for project: ContentProject) -> String {
        let shot = primaryShot(for: project)
        if !shot.isEmpty {
            return shot
        }

        switch project.platform {
        case .tiktok:
            return project.language == .german
                ? "Intimes Creator-Setup mit direkter Naehe"
                : "Intimate creator setup with direct proximity"
        case .instagramReels:
            return project.language == .german
                ? "Sauberes Studio-Setup mit modernem Hintergrund"
                : "Clean studio setup with a modern backdrop"
        case .youtubeShorts:
            return project.language == .german
                ? "Fokussiertes Erklaer-Setup mit klarer Bildfuehrung"
                : "Focused explainer setup with clear framing"
        case .x:
            return project.language == .german
                ? "Minimaler Desk- oder Screen-Frame"
                : "Minimal desk or screen-led frame"
        }
    }

    private static func primaryShot(for project: ContentProject) -> String {
        let shots = project.shotList.isEmpty ? defaultShots(for: project) : project.shotList
        return preferredLine(from: shots, fallback: defaultShots(for: project).first ?? "")
    }

    private static func motionAction(for project: ContentProject) -> String {
        switch project.platform {
        case .tiktok:
            return project.language == .german
                ? "Schnelle Bewegung oder Reaktion zeigen"
                : "Show a fast reaction or movement"
        case .instagramReels:
            return project.language == .german
                ? "Sanfte, klare Bewegung mit sofortigem Fokus zeigen"
                : "Show a clean movement with immediate focus"
        case .youtubeShorts:
            return project.language == .german
                ? "Information in einer klaren Aktion verdichten"
                : "Compress the idea into one direct action"
        case .x:
            return project.language == .german
                ? "Text oder Screen-Moment klar und schnell ausspielen"
                : "Play the text or screen moment fast and clearly"
        }
    }

    private static func preferredLine(from candidates: [String], fallback: String) -> String {
        candidates
            .map(cleanedLine)
            .first(where: { !$0.isEmpty }) ?? cleanedLine(fallback)
    }

    private static func cleanedLine(_ text: String) -> String {
        text
            .replacingOccurrences(of: #"^\d+\.\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
    }

    private static func clipped(_ text: String, wordLimit: Int) -> String {
        let cleaned = cleanedLine(text)
        let words = cleaned.split(separator: " ")

        guard words.count > wordLimit else { return cleaned }
        return words.prefix(wordLimit).joined(separator: " ") + "..."
    }

    private static func defaultShots(for project: ContentProject) -> [String] {
        if project.language == .german {
            return [
                "eine starke Nahaufnahme im Hochformat",
                "ein klares Detail, das den Kernkonflikt sichtbar macht",
                "eine Mid-Shot-Erklaerung mit direkter Blickfuehrung",
                "ein Abschlussframe mit direktem CTA-Fokus"
            ]
        }

        return [
            "a strong vertical close-up",
            "a clear detail shot that shows the core tension",
            "a believable mid-shot explanation with direct eye-line",
            "a closing frame with CTA focus"
        ]
    }
}
