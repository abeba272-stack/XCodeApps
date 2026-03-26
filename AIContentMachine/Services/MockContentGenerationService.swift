import Foundation

struct MockContentGenerationService: ContentGenerationService {
    func generateContent(for request: GenerationRequest) async throws -> GeneratedContent {
        try validate(request: request)
        try await Task.sleep(for: .milliseconds(650))

        let topic = request.topic.trimmingCharacters(in: .whitespacesAndNewlines)
        let category = request.category.trimmingCharacters(in: .whitespacesAndNewlines)
        let templateHint = TemplateEngine.structureHint(templateName: request.templateName, rules: request.templateRules, language: request.language)
        let seed = "\(topic)|\(request.platform.rawValue)|\(request.tone.rawValue)|\(request.language.rawValue)|\(request.style.rawValue)|\(request.goal.rawValue)"

        let contentAngle = localizedAngle(topic: topic, category: category, request: request, seed: seed)
        let audienceSummary = localizedAudienceSummary(request: request)
        let hook = localizedHook(topic: topic, category: category, request: request, seed: seed)
        let alternateHooks = localizedAlternateHooks(topic: topic, category: category, request: request, seed: seed)
        let overview = localizedOverview(topic: topic, category: category, request: request, angle: contentAngle, templateHint: templateHint)
        let title = localizedTitle(topic: topic, request: request, hook: hook, seed: seed)
        let script = localizedScript(topic: topic, category: category, request: request, angle: contentAngle, hook: hook, seed: seed)
        let voiceover = localizedVoiceover(script: script, request: request)
        let caption = localizedCaption(topic: topic, request: request, angle: contentAngle, hook: hook, seed: seed)
        let hashtags = localizedHashtags(topic: topic, category: category, request: request)
        let cta = localizedCTA(topic: topic, request: request, seed: seed)
        let shotList = localizedShotList(topic: topic, request: request, seed: seed)
        let notes = localizedNotes(request: request)
        let postingChecklist = localizedPostingChecklist(request: request)
        let thumbnails = localizedThumbnailSuggestions(topic: topic, request: request)
        let postingTip = localizedPostingTip(request: request)
        let emotionalTrigger = localizedEmotionalTrigger(request: request, category: category)
        let rationale = localizedPerformanceRationale(request: request, category: category, hook: hook)
        let bestTime = BestTimeHeuristic.suggestion(for: request.platform, goal: request.goal, language: request.language)
        let batchIdeas = request.mode == .batchIdeas ? localizedBatchIdeas(topic: topic, category: category, request: request, seed: seed) : []

        var generated = GeneratedContent(
            title: title,
            topic: topic,
            contentAngle: contentAngle,
            audienceSummary: audienceSummary,
            overview: overview,
            hook: hook,
            alternateHooks: alternateHooks,
            script: request.mode == .singleIdea ? "" : script,
            voiceover: request.mode == .singleIdea ? "" : voiceover,
            caption: request.mode == .singleIdea ? "" : caption,
            hashtags: request.mode == .singleIdea ? [] : hashtags,
            cta: cta,
            shotList: request.mode == .fullPackage ? shotList : [],
            notes: notes,
            performanceRationale: request.mode == .singleIdea ? "" : rationale,
            bestPostingTime: request.mode == .singleIdea ? "" : bestTime,
            emotionalTrigger: request.mode == .singleIdea ? "" : emotionalTrigger,
            templateUsed: request.templateName,
            batchIdeas: batchIdeas,
            thumbnailSuggestions: request.mode == .fullPackage ? thumbnails : [],
            postingChecklist: request.mode == .fullPackage ? postingChecklist : [],
            postingTip: request.mode == .fullPackage ? postingTip : "",
            status: request.mode == .singleIdea ? .idea : .draft,
            score: 0
        )

        if request.mode == .batchIdeas {
            generated.title = request.language == .german ? "10 Ideen fuer \(topic)" : "10 ideas for \(topic)"
            generated.overview = request.language == .german
                ? "Schnelle Batch-Ideen mit klaren Hooks fuer \(request.platform.rawValue)."
                : "Fast batch ideas with strong hooks tailored to \(request.platform.rawValue)."
            generated.hook = request.language == .german
                ? "Hier sind 10 Formate, die du diese Woche sofort testen kannst."
                : "Here are 10 formats you can test this week."
        }

        if request.mode == .singleIdea {
            generated.overview = request.language == .german
                ? "Ein konzentrierter Content-Impuls fuer \(request.platform.rawValue), fokussiert auf \(request.goal.rawValue.lowercased())."
                : "A focused content prompt for \(request.platform.rawValue), optimized for \(request.goal.rawValue.lowercased())."
        }

        generated.score = ContentScoreCalculator.score(for: generated, request: request)
        return generated
    }

    func regenerateSection(_ section: ContentSection, for request: GenerationRequest) async throws -> GeneratedContent {
        try await generateContent(for: request)
    }
}

private extension MockContentGenerationService {
    func localizedTitle(topic: String, request: GenerationRequest, hook: String, seed: String) -> String {
        let variantsEn = [
            "Why \(topic) feels harder than it should",
            "The sharpest take on \(topic) right now",
            "\(request.style.rawValue): \(topic)",
            "What creators miss about \(topic)"
        ]

        let variantsDe = [
            "Warum \(topic) schwerer wirkt als es sein muss",
            "Der schaerfste Blick auf \(topic) gerade jetzt",
            "\(request.style.rawValue): \(topic)",
            "Was Creator bei \(topic) uebersehen"
        ]

        let selected = StablePicker.pick(request.language == .german ? variantsDe : variantsEn, seed: seed, salt: "title")
        return request.platform == .x ? String(selected.prefix(58)) : selected
    }

    func localizedAngle(topic: String, category: String, request: GenerationRequest, seed: String) -> String {
        let platformAngle: String
        switch request.platform {
        case .tiktok:
            platformAngle = request.language == .german ? "eine emotionale Spannung in den ersten zwei Sekunden" : "an emotional spike inside the first two seconds"
        case .instagramReels:
            platformAngle = request.language == .german ? "eine klare, speicherbare Erkenntnis mit visuell sauberem Flow" : "a clean, saveable insight with aesthetic pacing"
        case .youtubeShorts:
            platformAngle = request.language == .german ? "kompakte Autoritaet mit dichter Information" : "tight authority with high information density"
        case .x:
            platformAngle = request.language == .german ? "eine meinungsstarke Text-Perspektive" : "an opinionated text-first perspective"
        }

        if request.language == .german {
            return "Rahme \(topic) in \(category) so, dass der Zuschauer sofort \(platformAngle) spuert."
        }

        return "Frame \(topic) in \(category) so the audience instantly feels \(platformAngle)."
    }

    func localizedAudienceSummary(request: GenerationRequest) -> String {
        if request.language == .german {
            return "Primare Zielgruppe: \(request.audience). Sie wollen schnelle Klarheit, um ihr Ziel \(request.goal.rawValue.lowercased()) zu erreichen."
        }

        return "Primary audience: \(request.audience). They want fast clarity that moves them toward \(request.goal.rawValue.lowercased())."
    }

    func localizedOverview(topic: String, category: String, request: GenerationRequest, angle: String, templateHint: String) -> String {
        if request.language == .german {
            return "\(angle) Der Beitrag nutzt einen \(request.tone.descriptorDe) Ton, orientiert sich an \(request.platform.pacingDescription), und macht \(topic) fuer \(request.audience) sofort relevant. \(templateHint)"
        }

        return "\(angle) The piece uses a \(request.tone.descriptorEn) tone, follows a \(request.platform.pacingDescription) delivery, and makes \(topic) immediately relevant for \(request.audience). \(templateHint)"
    }

    func localizedHook(topic: String, category: String, request: GenerationRequest, seed: String) -> String {
        let en: [String]
        let de: [String]

        switch request.platform {
        case .tiktok:
            en = [
                "If you still think \(topic) is about discipline alone, you're already losing.",
                "Most people fail at \(topic) before they even notice the real problem.",
                "Nobody wants to admit this about \(topic), but it changes everything."
            ]
            de = [
                "Wenn du denkst, \(topic) hat nur mit Disziplin zu tun, verlierst du schon.",
                "Die meisten scheitern an \(topic), bevor sie das eigentliche Problem ueberhaupt sehen.",
                "Niemand spricht ehrlich ueber \(topic), aber genau das veraendert alles."
            ]
        case .instagramReels:
            en = [
                "The cleanest shortcut inside \(topic) is not what most people save.",
                "Here is the quiet shift inside \(topic) that makes people pay attention.",
                "This small change in \(topic) makes your content feel instantly smarter."
            ]
            de = [
                "Der sauberste Hebel in \(topic) ist nicht das, was die meisten abspeichern.",
                "Hier ist die stille Veraenderung in \(topic), die sofort Aufmerksamkeit erzeugt.",
                "Diese kleine Aenderung in \(topic) laesst deinen Content sofort intelligenter wirken."
            ]
        case .youtubeShorts:
            en = [
                "Here is the mechanism behind \(topic) in less than 30 seconds.",
                "If you want authority in \(category), understand this about \(topic).",
                "The fastest way to understand \(topic) is to stop looking at symptoms."
            ]
            de = [
                "Hier ist der Mechanismus hinter \(topic) in unter 30 Sekunden.",
                "Wenn du Autoritaet in \(category) willst, versteh das hier ueber \(topic).",
                "Der schnellste Weg, \(topic) zu verstehen, ist Symptome nicht mit Ursachen zu verwechseln."
            ]
        case .x:
            en = [
                "\(topic) is not a motivation problem. It's a design problem.",
                "Hot take: most advice about \(topic) rewards looking smart, not getting results.",
                "If \(topic) feels inconsistent, the system is the problem, not the ambition."
            ]
            de = [
                "\(topic) ist kein Motivationsproblem. Es ist ein Systemproblem.",
                "Hot Take: Der meiste Rat zu \(topic) belohnt kluge Worte, nicht echte Resultate.",
                "Wenn \(topic) inkonsistent wirkt, liegt das Problem im System, nicht im Ehrgeiz."
            ]
        }

        return StablePicker.pick(request.language == .german ? de : en, seed: seed, salt: "hook")
    }

    func localizedAlternateHooks(topic: String, category: String, request: GenerationRequest, seed: String) -> [String] {
        let en = [
            "You are not blocked by \(topic). You're blocked by the way you frame it.",
            "The real reason \(topic) stays messy has nothing to do with talent.",
            "Most people approach \(topic) backwards and pay for it later.",
            "You don't need more motivation around \(topic). You need a better trigger."
        ]

        let de = [
            "Du bist nicht von \(topic) blockiert, sondern von der falschen Perspektive darauf.",
            "Der echte Grund, warum \(topic) chaotisch bleibt, hat nichts mit Talent zu tun.",
            "Die meisten gehen \(topic) rueckwaerts an und zahlen spaeter den Preis.",
            "Du brauchst bei \(topic) nicht mehr Motivation, sondern einen besseren Ausloeser."
        ]

        return StablePicker.picks(request.language == .german ? de : en, count: 3, seed: seed, salt: "alternate-hooks")
    }

    func localizedScript(topic: String, category: String, request: GenerationRequest, angle: String, hook: String, seed: String) -> String {
        let credibility = request.language == .german
            ? "Das Problem ist nicht fehlender Wille, sondern ein falscher Aufbau."
            : "The issue is not low willpower. It's a weak setup."
        let contrast = request.language == .german
            ? "Die meisten reagieren auf Symptome, statt die eigentliche Ursache anzupacken."
            : "Most people react to the symptom instead of fixing the real cause."
        let example = request.language == .german
            ? "Wenn jemand \(topic) verbessern will, jagt er oft mehr Output, obwohl eigentlich Klarheit und Struktur fehlen."
            : "When someone tries to improve \(topic), they usually chase more output when they actually need clarity and structure."
        let payoff = request.language == .german
            ? "Darum performt ein klarer, fokusierter Ansatz besser: weniger Reibung, mehr Wiederholbarkeit, mehr Vertrauen."
            : "That is why a sharper, more focused approach performs better: less friction, more repeatability, more trust."

        let beats = [hook, credibility, contrast, example, payoff, localizedCTA(topic: topic, request: request, seed: seed)]
        let limit = request.durationSeconds <= 20 ? 4 : request.durationSeconds <= 35 ? 5 : 6
        return beats.prefix(limit).enumerated().map { index, line in
            "\(index + 1). \(line)"
        }.joined(separator: "\n")
    }

    func localizedVoiceover(script: String, request: GenerationRequest) -> String {
        let stripped = script
            .split(separator: "\n")
            .map { $0.replacingOccurrences(of: #"^\d+\.\s"#, with: "", options: .regularExpression) }
            .joined(separator: " ")

        if request.platform == .x { return stripped.prefix(260).description }
        return stripped
    }

    func localizedCaption(topic: String, request: GenerationRequest, angle: String, hook: String, seed: String) -> String {
        let endingsEn = [
            "Save this and test it in your next post.",
            "Comment \"plan\" if you want the next angle.",
            "Share this with the creator who needs sharper positioning."
        ]
        let endingsDe = [
            "Speichere das und teste es im naechsten Post.",
            "Schreib \"Plan\", wenn du den naechsten Angle willst.",
            "Teil das mit dem Creator, der eine schaerfere Positionierung braucht."
        ]
        let ending = StablePicker.pick(request.language == .german ? endingsDe : endingsEn, seed: seed, salt: "caption-ending")

        let intro = request.language == .german
            ? "\(topic) wird oft falsch verstanden. Der Hebel ist nicht mehr Lautstaerke, sondern ein klarerer Fokus."
            : "\(topic) is usually misunderstood. The lever is not more volume. It's sharper focus."

        switch request.platform {
        case .instagramReels:
            return "\(intro)\n\n\(angle)\n\n\(ending)"
        case .x:
            return String("\(hook)\n\n\(intro)\n\n\(ending)".prefix(275))
        default:
            return "\(hook)\n\n\(intro)\n\n\(ending)"
        }
    }

    func localizedHashtags(topic: String, category: String, request: GenerationRequest) -> [String] {
        let cleanTopic = topic
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
        let cleanCategory = category
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
        let goalTag = request.goal.rawValue.replacingOccurrences(of: " ", with: "")
        let languageTag = request.language == .german ? "decontent" : "creatorstrategy"

        switch request.platform {
        case .tiktok:
            return ["#\(cleanTopic.lowercased())", "#\(cleanCategory.lowercased())tips", "#viralhooks", "#\(goalTag.lowercased())", "#\(languageTag)"]
        case .instagramReels:
            return ["#\(cleanCategory.lowercased())creator", "#contentworkflow", "#reelstrategy", "#\(goalTag.lowercased())", "#\(cleanTopic.lowercased())"]
        case .youtubeShorts:
            return ["#shorts", "#\(cleanTopic.lowercased())", "#\(cleanCategory.lowercased())", "#authoritycontent", "#\(goalTag.lowercased())"]
        case .x:
            return ["#buildinpublic", "#\(cleanCategory.lowercased())", "#contentstrategy", "#\(goalTag.lowercased())"]
        }
    }

    func localizedCTA(topic: String, request: GenerationRequest, seed: String) -> String {
        let enByGoal: [ContentGoal: [String]] = [
            .views: ["Follow for sharper daily content systems.", "Save this for your next posting sprint."],
            .engagement: ["Comment \"next\" and I will build the sequel angle.", "Tell me which part hit hardest."],
            .followers: ["Follow if you want more frameworks like this.", "Follow for daily creator systems without fluff."],
            .leads: ["DM me \"strategy\" if you want this turned into your workflow.", "Message me if you want the implementation version."],
            .authority: ["Share this if you want more high-signal breakdowns.", "Save this as your reference before you post again."],
            .sales: ["Use this, then put your offer in the last line.", "Send this to a buyer who needs the problem framed clearly."]
        ]

        let deByGoal: [ContentGoal: [String]] = [
            .views: ["Folge fuer taegliche, schaerfere Content-Systeme.", "Speichere das fuer deinen naechsten Posting-Sprint."],
            .engagement: ["Schreib \"next\" und ich baue den Folge-Angle.", "Sag mir, welcher Teil dich am meisten getroffen hat."],
            .followers: ["Folge, wenn du mehr Frameworks wie dieses willst.", "Folge fuer taegliche Creator-Systeme ohne Bla Bla."],
            .leads: ["Schreib mir \"Strategie\", wenn du das als Workflow willst.", "Sende mir eine Nachricht, wenn du die Umsetzungs-Version willst."],
            .authority: ["Teil das, wenn du mehr High-Signal-Breakdowns willst.", "Speichere das als Referenz vor deinem naechsten Post."],
            .sales: ["Nutze das und setze dein Angebot in die letzte Zeile.", "Schick das an einen Kunden, der das Problem klar sehen muss."]
        ]

        let source = request.language == .german ? deByGoal : enByGoal
        return StablePicker.pick(source[request.goal] ?? [], seed: seed, salt: "cta")
    }

    func localizedShotList(topic: String, request: GenerationRequest, seed: String) -> [String] {
        let en = [
            "Tight close-up with the hook as on-screen text.",
            "Fast cut to a detail shot that visually represents the friction in \(topic).",
            "Mid shot while explaining the core mistake.",
            "Overlay 3 concise text beats with bold contrast words.",
            "End on a direct eye-contact CTA."
        ]
        let de = [
            "Nahaufnahme mit dem Hook als On-Screen-Text.",
            "Schneller Schnitt auf ein Detail, das die Reibung in \(topic) zeigt.",
            "Halbtotale waehrend du den Kernfehler erklaerst.",
            "Lege 3 kurze Text-Beats mit klaren Kontrastwoertern ein.",
            "Beende mit direktem Blickkontakt und CTA."
        ]

        return request.platform == .x ? [] : (request.language == .german ? de : en)
    }

    func localizedNotes(request: GenerationRequest) -> String {
        if request.language == .german {
            return "Mock-Modus aktiv. Dieser Entwurf wurde lokal generiert und kann vor dem Posten manuell verfeinert werden."
        }
        return "Mock mode active. This draft was generated locally and can be refined manually before posting."
    }

    func localizedPostingChecklist(request: GenerationRequest) -> [String] {
        if request.language == .german {
            return [
                "Hook in die ersten 2 Sekunden legen",
                "Untertitel kurz und kontraststark halten",
                "CTA in der letzten Zeile klar machen",
                "Caption vor dem Posten auf Lesefluss pruefen",
                "Nach 20 Minuten erste Kommentare beantworten"
            ]
        }
        return [
            "Put the hook inside the first 2 seconds",
            "Keep subtitles short and contrast-heavy",
            "Make the CTA explicit in the final line",
            "Review the caption for skim-read clarity",
            "Reply to early comments within 20 minutes"
        ]
    }

    func localizedThumbnailSuggestions(topic: String, request: GenerationRequest) -> [String] {
        if request.language == .german {
            return [
                "Der echte Grund",
                "Niemand sagt das ueber \(topic)",
                "Mach nicht diesen Fehler"
            ]
        }
        return [
            "The real reason",
            "Nobody says this about \(topic)",
            "Stop making this mistake"
        ]
    }

    func localizedPostingTip(request: GenerationRequest) -> String {
        if request.language == .german {
            return "Nutze ein statisches Cover mit 3 bis 5 starken Woertern, damit der Kontext sofort klar ist."
        }
        return "Use a static cover with 3 to 5 strong words so the context lands instantly."
    }

    func localizedEmotionalTrigger(request: GenerationRequest, category: String) -> String {
        if request.language == .german {
            return "Der Beitrag nutzt Spannung zwischen aktuellem Verhalten und gewuenschtem Ergebnis. Das erzeugt Relevanz und leichte Unruhe."
        }
        return "The piece creates tension between current behavior and desired outcome, which drives relevance and productive discomfort."
    }

    func localizedPerformanceRationale(request: GenerationRequest, category: String, hook: String) -> String {
        if request.language == .german {
            return "Warum es funktionieren kann: Der Hook erzeugt Reibung, der Mittelteil liefert Klarheit, und die CTA gibt dem Zuschauer einen einfachen naechsten Schritt. Das staerkt Plattform-Fit und Glaubwuerdigkeit."
        }
        return "Why it may perform well: the hook creates tension, the middle delivers clarity, and the CTA gives a low-friction next step. That improves platform fit and credibility."
    }

    func localizedBatchIdeas(topic: String, category: String, request: GenerationRequest, seed: String) -> [String] {
        let en = [
            "The 3 hidden reasons \(request.audience) keep failing at \(topic)",
            "POV: you finally stop overcomplicating \(topic)",
            "Myth vs fact: the biggest lie people repeat about \(topic)",
            "Nobody talks about this part of \(topic)",
            "Before / after: what changes when you redesign \(topic)",
            "Hot take: most advice on \(topic) optimizes ego, not results",
            "Tutorial: the simplest workflow to make \(topic) repeatable",
            "Question hook: why does \(topic) still feel hard even when you know the steps?",
            "3 mistakes beginners make with \(topic)",
            "The real reason behind inconsistent \(topic)"
        ]
        let de = [
            "Die 3 versteckten Gruende, warum \(request.audience) bei \(topic) scheitern",
            "POV: Du hoerst auf, \(topic) zu verkomplizieren",
            "Mythos vs Fakt: Die groesste Luege ueber \(topic)",
            "Niemand spricht ueber diesen Teil von \(topic)",
            "Vorher / Nachher: Was sich aendert, wenn du \(topic) neu aufbaust",
            "Hot Take: Der meiste Rat zu \(topic) pflegt das Ego, nicht das Ergebnis",
            "Tutorial: Der simpelste Workflow, um \(topic) wiederholbar zu machen",
            "Frage-Hook: Warum fuehlt sich \(topic) noch schwer an, obwohl du die Schritte kennst?",
            "3 Fehler, die Anfaenger bei \(topic) machen",
            "Der echte Grund hinter inkonsistentem \(topic)"
        ]

        return request.language == .german ? de : en
    }
}
