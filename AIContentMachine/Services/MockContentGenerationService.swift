import Foundation

struct MockContentGenerationService: ContentGenerationService {
    func generateContent(for request: GenerationRequest) async throws -> GeneratedContent {
        try validate(request: request)
        try await Task.sleep(for: .milliseconds(520))

        let topic = request.topic.trimmingCharacters(in: .whitespacesAndNewlines)
        let category = request.category.trimmingCharacters(in: .whitespacesAndNewlines)
        let templateHint = TemplateEngine.structureHint(
            templateName: request.templateName,
            rules: request.templateRules,
            language: request.language
        )
        let seed = [
            topic,
            request.platform.rawValue,
            request.tone.rawValue,
            request.language.rawValue,
            request.style.rawValue,
            request.goal.rawValue
        ].joined(separator: "|")

        let contentAngle = localizedAngle(topic: topic, category: category, request: request, templateHint: templateHint)
        let audienceSummary = localizedAudienceSummary(request: request)
        let hook = localizedHook(topic: topic, category: category, request: request, seed: seed)
        let alternateHooks = localizedAlternateHooks(topic: topic, category: category, request: request, seed: seed)
        let title = localizedTitle(topic: topic, request: request, seed: seed)
        let overview = localizedOverview(topic: topic, category: category, request: request, angle: contentAngle, templateHint: templateHint)
        let script = localizedScript(topic: topic, category: category, request: request, hook: hook, seed: seed)
        let voiceover = localizedVoiceover(script: script, request: request)
        let caption = localizedCaption(topic: topic, category: category, request: request, hook: hook, seed: seed)
        let hashtags = localizedHashtags(topic: topic, category: category, request: request)
        let cta = localizedCTA(topic: topic, request: request, seed: seed)
        let shotList = localizedShotList(topic: topic, category: category, request: request)
        let notes = localizedNotes(request: request)
        let performanceRationale = localizedPerformanceRationale(request: request, hook: hook)
        let bestPostingTime = BestTimeHeuristic.suggestion(for: request.platform, goal: request.goal, language: request.language)
        let emotionalTrigger = localizedEmotionalTrigger(request: request, category: category)
        let thumbnails = localizedThumbnailSuggestions(topic: topic, request: request)
        let postingChecklist = localizedPostingChecklist(request: request)
        let postingTip = localizedPostingTip(request: request)
        let batchIdeas = request.mode == .batchIdeas ? localizedBatchIdeas(topic: topic, category: category, request: request, seed: seed) : []

        var generated = GeneratedContent(
            title: title,
            topic: topic,
            contentAngle: contentAngle,
            audienceSummary: audienceSummary,
            overview: overview,
            hook: hook,
            alternateHooks: alternateHooks,
            script: request.mode == .singleIdea || request.mode == .batchIdeas ? "" : script,
            voiceover: request.mode == .fullPackage ? voiceover : "",
            caption: request.mode == .singleIdea || request.mode == .batchIdeas ? "" : caption,
            hashtags: request.mode == .fullPackage ? hashtags : [],
            cta: cta,
            shotList: request.mode == .fullPackage ? shotList : [],
            notes: notes,
            performanceRationale: request.mode == .fullPackage ? performanceRationale : "",
            bestPostingTime: request.mode == .fullPackage ? bestPostingTime : "",
            emotionalTrigger: request.mode == .fullPackage ? emotionalTrigger : "",
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
                ? "Ein Batch aus 10 konkreten Content-Angles mit klaren Hooks, strukturiert fuer \(request.platform.rawValue)."
                : "A batch of 10 concrete content angles with clear hooks, structured for \(request.platform.rawValue)."
            generated.hook = request.language == .german
                ? "Hier sind 10 wiederholbare Formate, die du diese Woche direkt testen kannst."
                : "Here are 10 repeatable formats you can test this week."
        }

        if request.mode == .singleIdea {
            generated.overview = request.language == .german
                ? "Ein fokussierter Content-Impuls fuer \(request.platform.rawValue), gebaut fuer \(request.goal.rawValue.lowercased()) mit starkem Hook und klarer CTA."
                : "A focused content prompt for \(request.platform.rawValue), built for \(request.goal.rawValue.lowercased()) with a strong hook and clear CTA."
        }

        generated.score = ContentScoreCalculator.score(for: generated, request: request)
        return generated
    }

    func regenerateSection(_ section: ContentSection, for request: GenerationRequest) async throws -> GeneratedContent {
        try await generateContent(for: request)
    }
}

private extension MockContentGenerationService {
    struct ToneLexicon {
        let openerEn: String
        let openerDe: String
        let descriptorEn: String
        let descriptorDe: String
    }

    var toneLexicons: [ContentTone: ToneLexicon] {
        [
            .serious: .init(openerEn: "Cut the noise.", openerDe: "Streich das Rauschen.", descriptorEn: "measured and credible", descriptorDe: "sachlich und glaubwuerdig"),
            .dark: .init(openerEn: "This part is uncomfortable.", openerDe: "Dieser Teil ist unbequem.", descriptorEn: "dark with controlled edge", descriptorDe: "dunkel mit kontrollierter Schaerfe"),
            .funny: .init(openerEn: "This is where it gets a little ridiculous.", openerDe: "Ab hier wird es leicht absurd.", descriptorEn: "smart and light without losing clarity", descriptorDe: "clever und leicht, aber klar"),
            .confident: .init(openerEn: "Here is the real move.", openerDe: "Hier ist der echte Move.", descriptorEn: "sharp and self-assured", descriptorDe: "klar und selbstsicher"),
            .luxury: .init(openerEn: "Most people approach this cheaply.", openerDe: "Die meisten gehen das zu billig an.", descriptorEn: "refined and elevated", descriptorDe: "edel und hochwertig"),
            .educational: .init(openerEn: "Here is the simplest way to understand it.", openerDe: "So verstehst du es am einfachsten.", descriptorEn: "clear and structured", descriptorDe: "klar und strukturiert"),
            .emotional: .init(openerEn: "This hits because it feels personal.", openerDe: "Das trifft, weil es persoenlich fuehlt.", descriptorEn: "human and vivid", descriptorDe: "menschlich und intensiv"),
            .direct: .init(openerEn: "Most people are doing this backwards.", openerDe: "Die meisten machen das rueckwaerts.", descriptorEn: "brief and no-nonsense", descriptorDe: "knapp und kompromisslos")
        ]
    }

    func localizedTitle(topic: String, request: GenerationRequest, seed: String) -> String {
        let styleCueEn = styleCue(for: request.style, language: .english)
        let styleCueDe = styleCue(for: request.style, language: .german)

        let english = [
            "\(styleCueEn): \(topic)",
            "The real shift behind \(topic)",
            "What people still miss about \(topic)",
            "A better creator angle on \(topic)"
        ]
        let german = [
            "\(styleCueDe): \(topic)",
            "Die echte Verschiebung hinter \(topic)",
            "Was Menschen bei \(topic) noch immer uebersehen",
            "Ein besserer Creator-Angle auf \(topic)"
        ]

        let title = StablePicker.pick(request.language == .german ? german : english, seed: seed, salt: "title")
        return request.platform == .x ? String(title.prefix(58)) : title
    }

    func localizedAngle(topic: String, category: String, request: GenerationRequest, templateHint: String) -> String {
        let categoryLensEn = categoryLens(category, language: .english)
        let categoryLensDe = categoryLens(category, language: .german)
        let platformFitEn = platformFit(for: request.platform, language: .english)
        let platformFitDe = platformFit(for: request.platform, language: .german)

        if request.language == .german {
            return "Rahme \(topic) als \(categoryLensDe), damit der Beitrag auf \(request.platform.rawValue) sofort \(platformFitDe) ausloest. \(templateHint)"
        }

        return "Frame \(topic) as \(categoryLensEn) so the piece instantly feels \(platformFitEn) on \(request.platform.rawValue). \(templateHint)"
    }

    func localizedAudienceSummary(request: GenerationRequest) -> String {
        if request.language == .german {
            return "Primaere Zielgruppe: \(request.audience). Sie suchen schnelle Klarheit, konkrete Struktur und einen naechsten Schritt in Richtung \(request.goal.rawValue.lowercased())."
        }

        return "Primary audience: \(request.audience). They want fast clarity, concrete structure, and a next step toward \(request.goal.rawValue.lowercased())."
    }

    func localizedOverview(topic: String, category: String, request: GenerationRequest, angle: String, templateHint: String) -> String {
        let lexicon = toneLexicons[request.tone] ?? toneLexicons[.direct]!
        let styleCue = styleCue(for: request.style, language: request.language)
        let goalLine = goalOutcome(for: request.goal, language: request.language)

        if request.language == .german {
            return "\(angle) Der Beitrag nutzt einen \(lexicon.descriptorDe) Ton, folgt einem \(styleCue)-Aufbau und fuehrt den Zuschauer in Richtung \(goalLine)."
        }

        return "\(angle) The piece uses a \(lexicon.descriptorEn) tone, follows a \(styleCue) structure, and moves the viewer toward \(goalLine)."
    }

    func localizedHook(topic: String, category: String, request: GenerationRequest, seed: String) -> String {
        let english: [String]
        let german: [String]

        switch request.platform {
        case .tiktok:
            english = [
                "If you still think \(topic) is the surface problem, you're missing the real reason it breaks.",
                "Most people fail at \(topic) before they even notice the pattern causing it.",
                "This is the part of \(topic) nobody says out loud, and that is exactly why it works."
            ]
            german = [
                "Wenn du bei \(topic) immer noch das Symptom bekampfst, siehst du den eigentlichen Bruch nicht.",
                "Die meisten scheitern an \(topic), bevor sie das Muster dahinter ueberhaupt erkennen.",
                "Genau ueber diesen Teil von \(topic) spricht niemand offen und genau deshalb wirkt er."
            ]
        case .instagramReels:
            english = [
                "The cleanest shift inside \(topic) is smaller than people expect and stronger than they realize.",
                "This is the subtle fix inside \(topic) that makes content feel instantly more valuable.",
                "A more elegant way to approach \(topic) is hiding in one simple adjustment."
            ]
            german = [
                "Die sauberste Veraenderung in \(topic) ist kleiner als gedacht und staerker als erwartet.",
                "Das ist die subtile Korrektur in \(topic), die Content sofort wertvoller wirken laesst.",
                "Ein eleganterer Zugang zu \(topic) steckt in einer einzigen Anpassung."
            ]
        case .youtubeShorts:
            english = [
                "Here is the mechanism behind \(topic) in under a minute.",
                "If you want authority in \(category), understand this about \(topic) first.",
                "The fastest way to decode \(topic) is to stop treating the symptom as the system."
            ]
            german = [
                "Hier ist der Mechanismus hinter \(topic) in unter einer Minute.",
                "Wenn du Autoritaet in \(category) willst, versteh zuerst das hier ueber \(topic).",
                "Der schnellste Weg, \(topic) zu entschluesseln, ist das Symptom nicht mit dem System zu verwechseln."
            ]
        case .x:
            english = [
                "\(topic) is rarely a discipline problem. It is usually a system-design problem.",
                "Hot take: most advice on \(topic) rewards sounding smart instead of getting results.",
                "If \(topic) feels inconsistent, the setup is probably broken long before the effort is."
            ]
            german = [
                "\(topic) ist selten ein Disziplinproblem. Es ist meist ein Designproblem des Systems.",
                "Hot Take: Der meiste Rat zu \(topic) klingt klug, liefert aber keine Resultate.",
                "Wenn \(topic) inkonsistent wirkt, ist oft das Setup kaputt, nicht der Wille."
            ]
        }

        return StablePicker.pick(request.language == .german ? german : english, seed: seed, salt: "hook")
    }

    func localizedAlternateHooks(topic: String, category: String, request: GenerationRequest, seed: String) -> [String] {
        let english = [
            "You are not blocked by \(topic). You are blocked by how you frame it.",
            "The real reason \(topic) still feels messy has nothing to do with talent.",
            "Most people approach \(topic) in a way that looks productive but delays the result.",
            "The fastest fix inside \(topic) is not more effort. It is cleaner structure."
        ]

        let german = [
            "Du bist nicht von \(topic) blockiert, sondern von der falschen Perspektive darauf.",
            "Der echte Grund, warum \(topic) chaotisch wirkt, hat nichts mit Talent zu tun.",
            "Die meisten gehen \(topic) so an, dass es produktiv aussieht, aber Resultate verzoegert.",
            "Der schnellste Hebel in \(topic) ist nicht mehr Einsatz, sondern bessere Struktur."
        ]

        return StablePicker.picks(request.language == .german ? german : english, count: 3, seed: seed, salt: "alternate")
    }

    func localizedScript(topic: String, category: String, request: GenerationRequest, hook: String, seed: String) -> String {
        let lexicon = toneLexicons[request.tone] ?? toneLexicons[.direct]!
        let problem = request.language == .german
            ? "Das Problem ist nicht fehlender Wille. Das Setup rund um \(topic) erzeugt unnoetige Reibung."
            : "The issue is not low commitment. The setup around \(topic) creates unnecessary friction."
        let contrast = request.language == .german
            ? "Die meisten reagieren auf Symptome, statt das zugrunde liegende Muster zu korrigieren."
            : "Most people react to the symptom instead of correcting the underlying pattern."
        let example = request.language == .german
            ? "In \(category) sieht man das staendig: mehr Output, mehr Stress, aber keine sauberere Positionierung."
            : "You see it constantly in \(category): more output, more stress, but no cleaner positioning."
        let reframe = request.language == .german
            ? "\(lexicon.openerDe) Behandle \(topic) als Systemfrage, nicht als Stimmungsschwankung."
            : "\(lexicon.openerEn) Treat \(topic) like a system design question, not a mood problem."
        let payoff = request.language == .german
            ? "Dann wird der Content klarer, leichter wiederholbar und glaubwuerdiger fuer \(request.audience)."
            : "That makes the content clearer, easier to repeat, and more credible for \(request.audience)."
        let close = localizedCTA(topic: topic, request: request, seed: seed)

        let beats = [hook, reframe, problem, contrast, example, payoff, close]
        let maxBeats = request.durationSeconds <= 20 ? 4 : request.durationSeconds <= 35 ? 5 : 6

        return beats.prefix(maxBeats).enumerated().map { index, line in
            "\(index + 1). \(line)"
        }.joined(separator: "\n")
    }

    func localizedVoiceover(script: String, request: GenerationRequest) -> String {
        let stripped = script
            .split(separator: "\n")
            .map { $0.replacingOccurrences(of: #"^\d+\.\s"#, with: "", options: .regularExpression) }
            .joined(separator: " ")

        if request.platform == .x {
            return String(stripped.prefix(260))
        }
        return stripped
    }

    func localizedCaption(topic: String, category: String, request: GenerationRequest, hook: String, seed: String) -> String {
        let platformCloser = request.language == .german
            ? "Speicher das, teste es diese Woche, und beobachte was sich am Response veraendert."
            : "Save this, test it this week, and watch how the response changes."
        let teachingLine = request.language == .german
            ? "\(topic) wird oft wie ein Motivationsproblem behandelt, obwohl es in Wahrheit ein Strukturproblem ist."
            : "\(topic) is usually treated like a motivation problem when it is actually a structure problem."
        let angleLine = request.language == .german
            ? "Genau dieser Perspektivwechsel macht den Beitrag in \(category) relevanter und merkbarer."
            : "That perspective shift is what makes the piece more relevant and memorable inside \(category)."

        switch request.platform {
        case .x:
            return String("\(hook)\n\n\(teachingLine)\n\(angleLine)\n\n\(platformCloser)".prefix(275))
        case .instagramReels:
            return "\(teachingLine)\n\n\(angleLine)\n\n\(platformCloser)"
        default:
            return "\(hook)\n\n\(teachingLine)\n\(angleLine)\n\n\(platformCloser)"
        }
    }

    func localizedHashtags(topic: String, category: String, request: GenerationRequest) -> [String] {
        let cleanTopic = cleanTag(from: topic)
        let cleanCategory = cleanTag(from: category)
        let goal = cleanTag(from: request.goal.rawValue)
        let style = cleanTag(from: request.style.rawValue)

        switch request.platform {
        case .tiktok:
            return ["#\(cleanTopic)", "#\(cleanCategory)creator", "#viralhooks", "#\(goal)", "#\(style)"]
        case .instagramReels:
            return ["#\(cleanCategory)reels", "#contentstrategy", "#saveworthy", "#\(cleanTopic)", "#\(goal)"]
        case .youtubeShorts:
            return ["#shorts", "#\(cleanTopic)", "#\(cleanCategory)", "#authoritycontent", "#\(goal)"]
        case .x:
            return ["#contentstrategy", "#\(cleanCategory)", "#\(goal)", "#buildinpublic"]
        }
    }

    func localizedCTA(topic: String, request: GenerationRequest, seed: String) -> String {
        let english: [ContentGoal: [String]] = [
            .views: ["Follow for sharper daily content systems.", "Save this before your next posting sprint."],
            .engagement: ["Comment \"next\" and I will build the sequel angle.", "Tell me which line hit hardest."],
            .followers: ["Follow if you want more frameworks like this.", "Follow for daily creator systems without fluff."],
            .leads: ["DM me \"strategy\" if you want this turned into your workflow.", "Message me if you want the implementation version."],
            .authority: ["Share this if you want more high-signal breakdowns.", "Save this as a reference before your next post."],
            .sales: ["Use this, then put your offer in the last line.", "Send this to the buyer who still needs the problem framed clearly."]
        ]
        let german: [ContentGoal: [String]] = [
            .views: ["Folge fuer taegliche, schaerfere Content-Systeme.", "Speichere das vor deinem naechsten Posting-Sprint."],
            .engagement: ["Schreib \"next\" und ich baue den Folge-Angle.", "Sag mir, welche Zeile am staerksten war."],
            .followers: ["Folge, wenn du mehr Frameworks wie dieses willst.", "Folge fuer taegliche Creator-Systeme ohne Bla Bla."],
            .leads: ["Schreib mir \"Strategie\", wenn du das als Workflow willst.", "Sende mir eine Nachricht, wenn du die Umsetzungs-Version willst."],
            .authority: ["Teil das, wenn du mehr High-Signal-Breakdowns willst.", "Speichere das als Referenz fuer deinen naechsten Post."],
            .sales: ["Nutze das und setze dein Angebot in die letzte Zeile.", "Schick das an den Kunden, der das Problem klar sehen muss."]
        ]

        let source = request.language == .german ? german : english
        return StablePicker.pick(source[request.goal] ?? [], seed: seed, salt: "cta")
    }

    func localizedShotList(topic: String, category: String, request: GenerationRequest) -> [String] {
        guard request.platform != .x else { return [] }

        let english = [
            "Cold open close-up with the hook as bold on-screen text.",
            "Fast detail shot that visually represents the friction inside \(topic).",
            "Mid shot while explaining the real pattern people miss.",
            "Overlay 3 short text beats that simplify the argument.",
            "Close on direct eye contact for the CTA."
        ]
        let german = [
            "Cold-Open-Nahaufnahme mit dem Hook als fettem On-Screen-Text.",
            "Schneller Detailshot, der die Reibung in \(topic) sichtbar macht.",
            "Halbtotale waehrend du das uebersehene Muster erklaerst.",
            "Lege 3 kurze Text-Beats ein, die das Argument vereinfachen.",
            "Beende mit direktem Blickkontakt fuer die CTA."
        ]

        return request.language == .german ? german : english
    }

    func localizedNotes(request: GenerationRequest) -> String {
        if request.language == .german {
            return "Offline-Mock-Modus aktiv. Dieser Entwurf wurde lokal mit Plattform-, Ton- und Stilregeln erzeugt und kann vor dem Posten manuell geschaerft werden."
        }
        return "Offline mock mode is active. This draft was generated locally using platform, tone, and style heuristics and can be sharpened manually before posting."
    }

    func localizedPostingChecklist(request: GenerationRequest) -> [String] {
        if request.language == .german {
            return [
                "Hook in die ersten 2 Sekunden legen",
                "On-screen-Text kuerzer als den gesprochenen Satz halten",
                "CTA in der letzten Zeile klar formulieren",
                "Caption vor dem Posten auf Lesefluss pruefen",
                "In den ersten 20 Minuten aktiv auf Kommentare reagieren"
            ]
        }

        return [
            "Land the hook inside the first 2 seconds",
            "Keep on-screen text shorter than the spoken line",
            "Make the CTA explicit in the final beat",
            "Review the caption for skim-read clarity",
            "Reply to early comments inside the first 20 minutes"
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
        switch request.platform {
        case .tiktok:
            return request.language == .german
                ? "Halte den ersten Frame visuell ruhig und lass die Hook-Spannung den Scroll-Stopp erzeugen."
                : "Keep the first frame visually calm and let the tension in the hook create the scroll stop."
        case .instagramReels:
            return request.language == .german
                ? "Nutze ein klares Cover mit 3 bis 5 starken Woertern, damit der Save-Wert sofort sichtbar ist."
                : "Use a clean cover with 3 to 5 strong words so the save value is obvious immediately."
        case .youtubeShorts:
            return request.language == .german
                ? "Schneide jede Pause raus. Shorts gewinnen, wenn jede Sekunde neue Information traegt."
                : "Cut every dead pause. Shorts win when every second carries fresh information."
        case .x:
            return request.language == .german
                ? "Setze die staerkste Aussage in die erste Zeile und spare die Erklaerung fuer danach."
                : "Put the strongest claim in the first line and let the explanation follow."
        }
    }

    func localizedEmotionalTrigger(request: GenerationRequest, category: String) -> String {
        if request.language == .german {
            return "Der Beitrag erzeugt Spannung zwischen dem aktuellen Verhalten des Zuschauers und dem Ergebnis, das er eigentlich will. Diese kontrollierte Reibung macht \(category) sofort relevanter."
        }

        return "The piece creates tension between the viewer’s current behavior and the result they actually want. That controlled friction makes \(category) instantly more relevant."
    }

    func localizedPerformanceRationale(request: GenerationRequest, hook: String) -> String {
        let platformReason = platformFit(for: request.platform, language: request.language)

        if request.language == .german {
            return "Warum es funktionieren kann: Der Hook baut schnell Reibung auf, der Mittelteil liefert Klarheit, und die CTA gibt einen einfachen naechsten Schritt. Das passt zu \(platformReason) und staerkt Glaubwuerdigkeit."
        }

        return "Why it may perform well: the hook builds fast tension, the middle delivers clarity, and the CTA gives a low-friction next step. That matches \(platformReason) and strengthens credibility."
    }

    func localizedBatchIdeas(topic: String, category: String, request: GenerationRequest, seed: String) -> [String] {
        let englishFormats = [
            "The 3 hidden reasons \(request.audience) keep struggling with \(topic)",
            "POV: you finally stop overcomplicating \(topic)",
            "Myth vs fact: the biggest lie people repeat about \(topic)",
            "Nobody talks about this side of \(topic)",
            "Before / after: what changes when you redesign \(topic)",
            "Hot take: most advice on \(topic) optimizes ego, not results",
            "Tutorial: the simplest workflow to make \(topic) repeatable",
            "Question hook: why does \(topic) still feel hard even when you know the steps?",
            "3 mistakes beginners make with \(topic)",
            "The real reason behind inconsistent \(topic)"
        ]

        let germanFormats = [
            "Die 3 versteckten Gruende, warum \(request.audience) bei \(topic) haengen bleiben",
            "POV: Du hoerst auf, \(topic) zu verkomplizieren",
            "Mythos vs Fakt: Die groesste Luege ueber \(topic)",
            "Niemand spricht ueber diese Seite von \(topic)",
            "Vorher / Nachher: Was sich aendert, wenn du \(topic) neu aufsetzt",
            "Hot Take: Der meiste Rat zu \(topic) pflegt das Ego, nicht das Ergebnis",
            "Tutorial: Der einfachste Workflow, um \(topic) wiederholbar zu machen",
            "Frage-Hook: Warum fuehlt sich \(topic) noch schwer an, obwohl du die Schritte kennst?",
            "3 Fehler, die Einsteiger bei \(topic) machen",
            "Der echte Grund hinter inkonsistentem \(topic)"
        ]

        let source = request.language == .german ? germanFormats : englishFormats
        return StablePicker.shuffled(source, seed: seed, salt: "batch").prefix(10).map(\.self)
    }

    func styleCue(for style: ContentStyle, language: ContentLanguage) -> String {
        switch (style, language) {
        case (.hotTake, .german): return "Hot-Take"
        case (.storytime, .german): return "Storytime"
        case (.educational, .german): return "Erklaer-Format"
        case (.top3List, .german): return "Top-3-Liste"
        case (.mythVsFact, .german): return "Mythos-vs-Fakt"
        case (.comparison, .german): return "Vergleich"
        case (.motivational, .german): return "motivierenden"
        case (.controversialOpinion, .german): return "kontroversen Meinungs"
        case (.tutorial, .german): return "Tutorial"
        case (.pov, .german): return "POV"
        case (.questionBasedHook, .german): return "Frage-Hook"
        case (.beforeAfter, .german): return "Vorher-Nachher"
        case (.mistakesPeopleMake, .german): return "Fehler-Formats"
        case (.deepExplanation, .german): return "Deep-Dive"
        case (.shortPunchyHook, .german): return "kurzen Hook"
        case (.viralFormatClone, .german): return "viral inspirierten"
        default: return style.rawValue
        }
    }

    func categoryLens(_ category: String, language: ContentLanguage) -> String {
        if language == .german {
            return "einen klaren, creator-tauglichen Breakthrough in \(category)"
        }
        return "a clear, creator-ready breakthrough inside \(category)"
    }

    func platformFit(for platform: ContentPlatform, language: ContentLanguage) -> String {
        switch (platform, language) {
        case (.tiktok, .german): return "schneller, emotionaler Scroll-Spannung"
        case (.instagramReels, .german): return "sauberem, speicherbarem Reels-Pacing"
        case (.youtubeShorts, .german): return "dichter, autoritaetsstarker Shorts-Struktur"
        case (.x, .german): return "knapper, meinungsstarker Text-Schaerfe"
        case (.tiktok, .english): return "fast emotional scroll tension"
        case (.instagramReels, .english): return "clean, save-worthy reels pacing"
        case (.youtubeShorts, .english): return "dense authority-building shorts structure"
        case (.x, .english): return "tight opinionated text-first sharpness"
        }
    }

    func goalOutcome(for goal: ContentGoal, language: ContentLanguage) -> String {
        switch (goal, language) {
        case (.views, .german): return "mehr Reichweite"
        case (.engagement, .german): return "mehr Interaktion"
        case (.followers, .german): return "mehr Follower"
        case (.leads, .german): return "qualifiziertere Leads"
        case (.authority, .german): return "mehr Autoritaet"
        case (.sales, .german): return "mehr Kaufbereitschaft"
        case (.views, .english): return "more reach"
        case (.engagement, .english): return "more engagement"
        case (.followers, .english): return "more followers"
        case (.leads, .english): return "higher-quality leads"
        case (.authority, .english): return "more authority"
        case (.sales, .english): return "more buying intent"
        }
    }

    func cleanTag(from string: String) -> String {
        string
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }
}
