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

        let pool = ContentPool.resolve(category: category, language: request.language)

        let contentAngle = localizedAngle(topic: topic, category: category, request: request, templateHint: templateHint)
        let audienceSummary = localizedAudienceSummary(request: request)
        let hook = buildHook(topic: topic, pool: pool, request: request, seed: seed)
        let alternateHooks = buildAlternateHooks(topic: topic, pool: pool, request: request, seed: seed)
        let title = buildTitle(topic: topic, pool: pool, request: request, seed: seed)
        let overview = localizedOverview(topic: topic, category: category, request: request, angle: contentAngle, templateHint: templateHint)
        let script = buildScript(topic: topic, category: category, pool: pool, request: request, hook: hook, seed: seed)
        let voiceover = buildVoiceover(script: script, request: request)
        let caption = buildCaption(topic: topic, category: category, pool: pool, request: request, hook: hook, seed: seed)
        let hashtags = buildHashtags(topic: topic, category: category, pool: pool, request: request)
        let cta = buildCTA(topic: topic, pool: pool, request: request, seed: seed)
        let shotList = buildShotList(topic: topic, category: category, pool: pool, request: request)
        let notes = buildNotes(request: request)
        let performanceRationale = localizedPerformanceRationale(request: request, hook: hook)
        let bestPostingTime = BestTimeHeuristic.suggestion(for: request.platform, goal: request.goal, language: request.language)
        let emotionalTrigger = localizedEmotionalTrigger(request: request, category: category)
        let thumbnails = localizedThumbnailSuggestions(topic: topic, request: request)
        let postingChecklist = localizedPostingChecklist(request: request)
        let postingTip = localizedPostingTip(request: request)
        let videoAIPrompt = buildVideoAIPrompt(topic: topic, request: request, hook: hook, shotList: shotList)
        let batchIdeas = request.mode == .batchIdeas ? buildBatchIdeas(topic: topic, category: category, pool: pool, request: request, seed: seed) : []

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

// MARK: - Category-aware content pool

private struct ContentPool {
    let hooks: [String]
    let alternateHooks: [String]
    let scriptBeats: [String]
    let captionOpeners: [String]
    let ctas: [String]
    let shotDirections: [String]
    let batchFormats: [String]
    let nicheTags: [String]

    static func resolve(category: String, language: ContentLanguage) -> ContentPool {
        let key = matchCategory(category)
        return language == .german ? germanPools[key]! : englishPools[key]!
    }

    private static func matchCategory(_ category: String) -> String {
        let lower = category.lowercased()
        for (key, keywords) in categoryKeywords {
            if keywords.contains(where: { lower.contains($0) }) { return key }
        }
        return "general"
    }

    private static let categoryKeywords: [String: [String]] = [
        "motivation": ["motivation", "mindset", "self improvement", "self-improvement", "personal development", "mental health"],
        "business": ["business", "founder", "startup", "entrepreneur", "money", "finance", "product", "offer", "conversion", "sales"],
        "fitness": ["fitness", "health", "workout", "gym", "nutrition", "sport", "wellness"],
        "tech": ["tech", "programming", "code", "software", "ai", "machine learning", "developer", "app"],
        "lifestyle": ["lifestyle", "travel", "fashion", "food", "beauty", "design", "creative", "art", "anime", "storytelling"]
    ]

    // MARK: English pools

    static let englishPools: [String: ContentPool] = [
        "motivation": ContentPool(
            hooks: [
                "The real reason you feel stuck has nothing to do with discipline",
                "Stop waiting for motivation. Build the system that replaces it",
                "Most people quit right before the pattern clicks",
                "Your comfort zone is not protecting you. It is shrinking you",
                "The gap between knowing and doing is not laziness. It is fear of clarity",
                "Nobody tells you this about consistency: it only works after the setup is right",
                "You are not burned out. You are misaligned",
                "Hard truth: your habits are not broken. Your environment is"
            ],
            alternateHooks: [
                "What if the block is not you but the frame around you?",
                "The smallest shift today compounds into a different life in 90 days",
                "Discipline is a symptom of clarity, not a cause",
                "Everyone is optimizing effort. Almost nobody is optimizing direction",
                "Growth does not feel like growth when you are inside it",
                "The version of you that succeeds already exists in a better system"
            ],
            scriptBeats: [
                "The real friction is not effort. It is the gap between what you want and what your current system supports",
                "Most people try harder instead of building smarter. That is why burnout feels inevitable",
                "Replace the pressure loop with a clarity loop: define one outcome, remove two distractions, and repeat",
                "The shift happens when you stop treating motivation as fuel and start treating it as a signal",
                "Consistency without direction is just busy work disguised as progress",
                "The simplest version of your next step is the one you should take right now"
            ],
            captionOpeners: [
                "The difference between stuck and moving is usually one structural change",
                "You do not need more motivation. You need a cleaner system",
                "Progress is invisible until the pattern locks in",
                "This is the mindset correction most people skip"
            ],
            ctas: [
                "Save this for the next time you feel stuck",
                "Follow for daily clarity systems that replace motivation",
                "Comment \"shift\" if this hit different",
                "Share this with someone who needs to hear it today",
                "Follow for frameworks that make discipline optional"
            ],
            shotDirections: [
                "Close-up on eye contact with bold hook text overlay",
                "Medium shot explaining the core friction with animated text beats",
                "Detail shot of workspace or hands while delivering the reframe",
                "Pull-back shot with direct CTA and follow prompt on screen",
                "Fast montage of real routine moments cut to the script rhythm",
                "Slow zoom on face during the emotional pivot line"
            ],
            batchFormats: [
                "The silent reason {{audience}} keep self-sabotaging around {{topic}}",
                "POV: you finally stop forcing {{topic}} and let the system work",
                "3 mindset traps that make {{topic}} feel harder than it is",
                "Nobody warns you about this side of {{topic}}",
                "Before / after: what changes when you redesign your approach to {{topic}}",
                "Hot take: most advice on {{topic}} rewards sounding deep instead of being useful",
                "Tutorial: the simplest daily system to make {{topic}} automatic",
                "Why does {{topic}} still feel heavy even when you know the steps?",
                "The one habit shift that unlocked {{topic}} for me",
                "The uncomfortable truth about consistency and {{topic}}"
            ],
            nicheTags: ["mindset", "selfgrowth", "discipline", "personaldevelopment", "growthmindset"]
        ),
        "business": ContentPool(
            hooks: [
                "Your offer is not weak. Your positioning makes it invisible",
                "Stop building features. Start framing outcomes",
                "Most founders fail at content because they talk about process instead of results",
                "The fastest path to revenue is not more traffic. It is a clearer message",
                "If your audience understands your offer in 5 seconds, conversion doubles",
                "You are not lacking leads. You are lacking a system that qualifies them before the call",
                "The real bottleneck is not marketing. It is that your value prop sounds like everyone else's",
                "Revenue solves most startup problems. Clarity solves revenue"
            ],
            alternateHooks: [
                "The best founders do not sell harder. They position sharper",
                "Your funnel is not broken. Your first sentence is",
                "Most business advice optimizes for ego metrics, not buying decisions",
                "If you cannot explain the transformation in one line, the offer needs work",
                "The gap between good product and good sales is usually one positioning fix",
                "Stop treating content as marketing. Start treating it as a trust accelerator"
            ],
            scriptBeats: [
                "The issue is not that people do not see your offer. It is that they do not feel the urgency",
                "Most founders confuse being busy with being strategic. That is why growth stalls after the first spike",
                "Reframe the pitch: lead with the cost of staying stuck, then show the path forward",
                "One clear case study beats ten generic testimonials every time",
                "Your pricing is not the problem. The perceived value gap is",
                "Build content that makes the decision obvious, not content that explains the features"
            ],
            captionOpeners: [
                "The difference between revenue and noise is positioning clarity",
                "Stop chasing followers. Start converting the ones you already have",
                "This is how founders turn attention into pipeline",
                "Most offers fail in the first line, not the last"
            ],
            ctas: [
                "DM me \"strategy\" to get the implementation version",
                "Follow for founder-tested business systems",
                "Save this before your next launch",
                "Comment \"pipeline\" if you want the deeper breakdown",
                "Share this with a founder who needs sharper positioning"
            ],
            shotDirections: [
                "Clean desk setup with bold statement as text overlay",
                "Screen recording walkthrough showing the framework in action",
                "Medium shot with whiteboard or sticky notes visible",
                "Split screen before/after showing positioning improvement",
                "Fast-cut montage of workflow tools with voiceover",
                "Direct-to-camera close-up for authority delivery"
            ],
            batchFormats: [
                "The 3 revenue leaks {{audience}} never notice in their {{topic}} system",
                "POV: you stop overthinking {{topic}} and simplify the offer",
                "Myth vs fact: the biggest misconception about {{topic}} in business",
                "Why most founders fail at {{topic}} even with a great product",
                "Before / after: how one positioning shift fixed {{topic}} completely",
                "Hot take: the usual advice on {{topic}} is keeping you stuck",
                "Tutorial: the lean framework that makes {{topic}} repeatable",
                "The hidden cost of ignoring {{topic}} in your business",
                "3 mistakes early founders make with {{topic}}",
                "The real reason your {{topic}} strategy is not converting"
            ],
            nicheTags: ["business", "founder", "startup", "entrepreneur", "revenue"]
        ),
        "fitness": ContentPool(
            hooks: [
                "You are not plateauing because of effort. Your program design is the bottleneck",
                "Stop chasing soreness. Start chasing progressive overload",
                "The simplest nutrition fix most people ignore is also the most effective",
                "If your warmup takes 2 minutes, your training is already compromised",
                "Most people train hard. Almost nobody trains smart. Here is the difference",
                "The real reason your gains stalled is not genetics. It is recovery design",
                "You do not need a new program. You need better execution of the one you have",
                "The fastest way to look better is not more cardio. It is less noise in your plan"
            ],
            alternateHooks: [
                "Your body is not ignoring effort. It is responding to the wrong signals",
                "The gap between training and results is usually one variable",
                "Forget motivation. Build a routine that survives bad days",
                "The strongest people in the gym share one trait: boring consistency",
                "What looks like a plateau is usually a programming error",
                "Recovery is not a rest day. It is a strategy"
            ],
            scriptBeats: [
                "The problem is not that you are not working hard enough. Your training variables are fighting each other",
                "Most people add volume when they should be adding quality. That single switch changes everything",
                "Think of your body like a system: stress, recover, adapt. Break the loop and progress stops",
                "One properly periodized month beats three months of random effort",
                "Stop copying influencer programs. Build around your recovery capacity and schedule",
                "The fastest visible change comes from fixing the fundamentals you skipped"
            ],
            captionOpeners: [
                "The gap between effort and results is usually one adjustment",
                "Most people overtrain and underrecover. Fix that first",
                "This is the programming mistake holding back 90 percent of lifters",
                "Your body responds to signals, not wishes"
            ],
            ctas: [
                "Save this for your next training block",
                "Follow for evidence-based training systems",
                "Comment \"program\" and I will share the template",
                "Share this with your training partner",
                "Follow if you want results without the noise"
            ],
            shotDirections: [
                "Gym POV shot with bold hook text on screen",
                "Slow motion exercise demo with form cue overlay",
                "Medium shot explaining the principle with whiteboard",
                "Before/after physique comparison with data overlay",
                "Quick-cut montage of exercises matching the script beats",
                "Close-up on face during the direct CTA"
            ],
            batchFormats: [
                "The 3 hidden reasons {{audience}} plateau on {{topic}}",
                "POV: you finally stop overcomplicating {{topic}} and see results",
                "Myth vs fact: the biggest lie about {{topic}} in fitness",
                "Nobody talks about this side of {{topic}} in training",
                "Before / after: what changes when you fix your approach to {{topic}}",
                "Hot take: popular advice on {{topic}} is making you weaker",
                "Tutorial: the simplest system to make {{topic}} consistent",
                "Why does {{topic}} still feel hard even after months of training?",
                "3 beginner mistakes with {{topic}} that even intermediates make",
                "The real reason your {{topic}} progress keeps stalling"
            ],
            nicheTags: ["fitness", "training", "gym", "health", "gains"]
        ),
        "tech": ContentPool(
            hooks: [
                "The tool is not the problem. The workflow around it is",
                "Stop learning frameworks. Start understanding patterns",
                "Most developers write code that works. Few write code that communicates",
                "If your architecture needs a diagram to explain, it is probably too complex",
                "The fastest way to ship better software is to delete unnecessary abstractions",
                "You are not slow because of the language. You are slow because of the decisions before the code",
                "AI will not replace developers. Developers who understand systems will replace those who do not",
                "The best technical decision is usually the boring one"
            ],
            alternateHooks: [
                "Clean code is not about style. It is about reducing cognitive load",
                "The 10x developer myth hides the real skill: knowing what not to build",
                "Every abstraction you add is a bet that the future will need it",
                "The gap between junior and senior is not syntax. It is decision quality",
                "Debugging is not a skill. It is a symptom of understanding depth",
                "Most tech debt is not technical. It is communication debt"
            ],
            scriptBeats: [
                "The issue is not the tech stack. It is the decision framework that chose it",
                "Developers optimize for cleverness when they should optimize for readability and deletion",
                "Simplify the interface, contain the complexity, and document the tradeoffs",
                "One well-scoped function beats a perfect abstraction that nobody understands",
                "The biggest productivity gain is not a new tool. It is fewer meetings and clearer requirements",
                "Write code for the next person who reads it, not for the compiler"
            ],
            captionOpeners: [
                "The real bottleneck in most projects is not code. It is clarity",
                "This is the engineering principle most teams learn too late",
                "Stop optimizing the wrong layer of the stack",
                "Simpler systems are not weaker. They are faster to fix"
            ],
            ctas: [
                "Follow for developer systems that actually ship",
                "Save this before your next architecture review",
                "Comment \"stack\" if you want the full breakdown",
                "Share this with your engineering team",
                "Follow for clean engineering without the hype"
            ],
            shotDirections: [
                "Screen recording of IDE with code highlighted and narrated",
                "Clean desk shot with laptop showing the concept diagram",
                "Split screen: messy code vs clean refactored version",
                "Whiteboard sketch explaining the architecture principle",
                "Fast terminal commands montage with voiceover",
                "Direct-to-camera close-up for the key insight delivery"
            ],
            batchFormats: [
                "The 3 architectural mistakes {{audience}} keep making with {{topic}}",
                "POV: you finally simplify {{topic}} and everything gets faster",
                "Myth vs fact: the biggest misconception about {{topic}} in tech",
                "Nobody warns you about this side of {{topic}} in production",
                "Before / after: what changes when you rethink {{topic}}",
                "Hot take: the popular approach to {{topic}} creates more problems than it solves",
                "Tutorial: the minimal setup to make {{topic}} work cleanly",
                "Why does {{topic}} still feel fragile even with tests?",
                "3 mistakes every developer makes with {{topic}}",
                "The real reason {{topic}} fails in most teams"
            ],
            nicheTags: ["tech", "developer", "coding", "engineering", "software"]
        ),
        "lifestyle": ContentPool(
            hooks: [
                "The thing nobody tells you about creating content you actually enjoy",
                "Your creative block is not a motivation problem. It is a direction problem",
                "Stop copying trends. Start building a style that compounds over time",
                "The most magnetic creators share one thing: they stopped trying to appeal to everyone",
                "If your content feels forced, the system behind it probably is too",
                "The fastest way to grow as a creator is to get specific about who you serve",
                "Your aesthetic is not your brand. Your perspective is",
                "The gap between creating and connecting is usually one shift in framing"
            ],
            alternateHooks: [
                "The best content comes from constraints, not freedom",
                "Creativity is not random. It is a structured habit",
                "Your audience does not want perfection. They want perspective",
                "The most underrated creative skill is knowing what to leave out",
                "Stop polishing. Start publishing. Refinement comes from volume",
                "The version of your content that resonates is often the one that felt risky"
            ],
            scriptBeats: [
                "The problem is not a lack of ideas. It is trying to serve too many audiences at once",
                "Narrow the lens: pick one viewer, one feeling, and one takeaway per piece",
                "The pieces that perform best are usually the ones that felt most personal to make",
                "Trends give you reach. Perspective gives you retention. Build for the second one",
                "Visual quality matters less than emotional clarity. Fix the message first",
                "Build a content rhythm you can sustain for six months, not a sprint you abandon in three weeks"
            ],
            captionOpeners: [
                "The shift from creating to connecting starts with this",
                "Your content does not need to be louder. It needs to be clearer",
                "This is the creative principle I wish I learned earlier",
                "Stop chasing the algorithm. Start serving the human"
            ],
            ctas: [
                "Save this for your next creative reset",
                "Follow for creator systems without the burnout",
                "Comment \"create\" if you want the full framework",
                "Share this with a creator who needs to hear it",
                "Follow for creative strategy that actually sticks"
            ],
            shotDirections: [
                "Aesthetic workspace shot with hook text as overlay",
                "Close-up of hands working on creative project during narration",
                "Soft-lit medium shot sharing the key insight directly",
                "B-roll montage of creative process cut to script rhythm",
                "Pull-back shot revealing full setup for the CTA",
                "Slow pan across mood board or inspiration wall"
            ],
            batchFormats: [
                "The 3 hidden reasons {{audience}} feel blocked around {{topic}}",
                "POV: you stop overthinking {{topic}} and just create",
                "Myth vs fact: the biggest lie creators tell themselves about {{topic}}",
                "Nobody talks about this side of {{topic}} in the creator space",
                "Before / after: what changes when you simplify {{topic}}",
                "Hot take: popular advice on {{topic}} is killing your creativity",
                "Tutorial: the easiest daily system for {{topic}}",
                "Why does {{topic}} still feel draining even when you love it?",
                "3 creative mistakes everyone makes with {{topic}}",
                "The real reason your {{topic}} content is not landing"
            ],
            nicheTags: ["creator", "lifestyle", "creative", "contentcreator", "storytelling"]
        ),
        "general": ContentPool(
            hooks: [
                "The real problem behind {{topic}} is not what most people think",
                "If you still approach {{topic}} this way, you are leaving results on the table",
                "Most people fail at {{topic}} before they even notice the pattern causing it",
                "This is the part of {{topic}} nobody says out loud",
                "The fastest fix for {{topic}} is not more effort. It is better structure",
                "Stop treating {{topic}} like a willpower problem. It is a design problem",
                "Here is the mechanism behind {{topic}} that changes everything",
                "The one adjustment that makes {{topic}} finally click"
            ],
            alternateHooks: [
                "You are not blocked by {{topic}}. You are blocked by how you frame it",
                "The real reason {{topic}} still feels messy has nothing to do with talent",
                "Most people approach {{topic}} in a way that looks productive but delays the result",
                "The fastest fix inside {{topic}} is not more effort. It is cleaner structure",
                "What if everything you believe about {{topic}} is slightly wrong?",
                "The version of {{topic}} that works is simpler than you think"
            ],
            scriptBeats: [
                "The issue is not low commitment. The setup around {{topic}} creates unnecessary friction",
                "Most people react to the symptom instead of correcting the underlying pattern",
                "In this space you see it constantly: more output, more stress, but no cleaner positioning",
                "Treat {{topic}} like a system design question, not a mood problem",
                "Then the content becomes clearer, easier to repeat, and more credible for the audience",
                "The simplest next step is the one that removes the most friction from the current system"
            ],
            captionOpeners: [
                "{{topic}} is usually treated like a motivation problem when it is actually a structure problem",
                "That perspective shift is what makes the piece more relevant and memorable",
                "The difference between stuck and moving is usually one structural change",
                "This is the correction most people skip and it costs them months"
            ],
            ctas: [
                "Follow for sharper daily content systems",
                "Save this before your next posting sprint",
                "Comment \"next\" and I will build the sequel angle",
                "Tell me which line hit hardest",
                "Share this if you want more high-signal breakdowns"
            ],
            shotDirections: [
                "Cold open close-up with the hook as bold on-screen text",
                "Fast detail shot that visually represents the friction",
                "Mid shot while explaining the real pattern people miss",
                "Overlay 3 short text beats that simplify the argument",
                "Close on direct eye contact for the CTA",
                "B-roll transition showing the concept in action"
            ],
            batchFormats: [
                "The 3 hidden reasons {{audience}} keep struggling with {{topic}}",
                "POV: you finally stop overcomplicating {{topic}}",
                "Myth vs fact: the biggest lie people repeat about {{topic}}",
                "Nobody talks about this side of {{topic}}",
                "Before / after: what changes when you redesign {{topic}}",
                "Hot take: most advice on {{topic}} optimizes ego, not results",
                "Tutorial: the simplest workflow to make {{topic}} repeatable",
                "Question hook: why does {{topic}} still feel hard even when you know the steps?",
                "3 mistakes beginners make with {{topic}}",
                "The real reason behind inconsistent {{topic}}"
            ],
            nicheTags: ["contentstrategy", "creatorlife", "growthhacks", "contentcreation", "onlinebusiness"]
        )
    ]

    // MARK: German pools

    static let germanPools: [String: ContentPool] = [
        "motivation": ContentPool(
            hooks: [
                "Der wahre Grund, warum du dich blockiert fuehlst, hat nichts mit Disziplin zu tun",
                "Hoer auf, auf Motivation zu warten. Bau das System, das sie ersetzt",
                "Die meisten geben genau dann auf, wenn das Muster anfaengt zu greifen",
                "Deine Komfortzone schuetzt dich nicht. Sie macht dich kleiner",
                "Die Luecke zwischen Wissen und Handeln ist keine Faulheit. Es ist Angst vor Klarheit",
                "Niemand sagt dir das ueber Konsistenz: sie funktioniert erst, wenn das Setup stimmt",
                "Du bist nicht ausgebrannt. Du bist falsch ausgerichtet",
                "Harte Wahrheit: deine Gewohnheiten sind nicht kaputt. Dein Umfeld ist es"
            ],
            alternateHooks: [
                "Was, wenn die Blockade nicht du bist, sondern der Rahmen um dich herum?",
                "Die kleinste Veraenderung heute multipliziert sich in 90 Tagen",
                "Disziplin ist ein Symptom von Klarheit, nicht die Ursache",
                "Alle optimieren Aufwand. Fast niemand optimiert die Richtung",
                "Wachstum fuehlt sich nicht wie Wachstum an, wenn man mittendrin steckt",
                "Die Version von dir, die es schafft, existiert bereits in einem besseren System"
            ],
            scriptBeats: [
                "Die eigentliche Reibung ist nicht der Aufwand. Es ist die Luecke zwischen dem, was du willst, und was dein System unterstuetzt",
                "Die meisten versuchen haerter statt smarter. Deshalb fuehlt sich Burnout unvermeidlich an",
                "Ersetze den Druck-Loop durch einen Klarheits-Loop: definiere ein Ergebnis, entferne zwei Ablenkungen, wiederhole",
                "Der Wandel passiert, wenn du Motivation nicht als Treibstoff behandelst, sondern als Signal",
                "Konsistenz ohne Richtung ist Beschaeftigungstherapie, getarnt als Fortschritt",
                "Die einfachste Version deines naechsten Schritts ist die, die du jetzt gehen solltest"
            ],
            captionOpeners: [
                "Der Unterschied zwischen Stillstand und Bewegung ist meist eine strukturelle Aenderung",
                "Du brauchst nicht mehr Motivation. Du brauchst ein saubereres System",
                "Fortschritt ist unsichtbar, bis das Muster greift",
                "Das ist die Mindset-Korrektur, die die meisten ueberspringen"
            ],
            ctas: [
                "Speichere das fuer den naechsten Moment, in dem du dich blockiert fuehlst",
                "Folge fuer taegliche Klarheits-Systeme, die Motivation ersetzen",
                "Schreib \"Shift\", wenn das bei dir anders ankam",
                "Teil das mit jemandem, der es heute hoeren muss",
                "Folge fuer Frameworks, die Disziplin optional machen"
            ],
            shotDirections: [
                "Nahaufnahme mit Blickkontakt und fettem Hook-Text als Overlay",
                "Halbtotale waehrend der Erklaerung mit animierten Text-Beats",
                "Detail-Shot von Arbeitsplatz waehrend des Reframes",
                "Rueckwaertsfahrt mit direkter CTA und Follow-Aufforderung",
                "Schnitt-Montage aus echten Alltags-Momenten im Script-Rhythmus",
                "Langsamer Zoom aufs Gesicht beim emotionalen Pivot"
            ],
            batchFormats: [
                "Die 3 versteckten Gruende, warum {{audience}} bei {{topic}} nicht weiterkommen",
                "POV: Du hoerst endlich auf, {{topic}} zu erzwingen, und laesst das System arbeiten",
                "3 Mindset-Fallen, die {{topic}} schwerer machen als noetig",
                "Niemand warnt dich vor dieser Seite von {{topic}}",
                "Vorher / Nachher: Was sich aendert, wenn du {{topic}} neu aufsetzt",
                "Hot Take: Der meiste Rat zu {{topic}} belohnt Tiefe statt Nutzen",
                "Tutorial: Das einfachste Tagessystem, um {{topic}} automatisch zu machen",
                "Warum fuehlt sich {{topic}} noch schwer an, obwohl du die Schritte kennst?",
                "Die eine Gewohnheits-Aenderung, die {{topic}} fuer mich entsperrt hat",
                "Die unbequeme Wahrheit ueber Konsistenz und {{topic}}"
            ],
            nicheTags: ["mindset", "selbstwachstum", "disziplin", "persoenlichkeitsentwicklung", "wachstum"]
        ),
        "business": ContentPool(
            hooks: [
                "Dein Angebot ist nicht schwach. Deine Positionierung macht es unsichtbar",
                "Hoer auf, Features zu bauen. Fang an, Ergebnisse zu rahmen",
                "Die meisten Gruender scheitern an Content, weil sie ueber Prozesse reden statt ueber Resultate",
                "Der schnellste Weg zu Umsatz ist nicht mehr Traffic. Es ist eine klarere Botschaft",
                "Wenn dein Publikum dein Angebot in 5 Sekunden versteht, verdoppelt sich die Conversion",
                "Dir fehlen keine Leads. Dir fehlt ein System, das sie vor dem Call qualifiziert",
                "Der echte Engpass ist nicht Marketing. Es ist, dass dein Value Prop wie alle anderen klingt",
                "Umsatz loest die meisten Startup-Probleme. Klarheit loest den Umsatz"
            ],
            alternateHooks: [
                "Die besten Gruender verkaufen nicht haerter. Sie positionieren schaerfer",
                "Dein Funnel ist nicht kaputt. Dein erster Satz ist es",
                "Der meiste Business-Rat optimiert Eitelkeitsmetriken, nicht Kaufentscheidungen",
                "Wenn du die Transformation nicht in einem Satz erklaeren kannst, muss das Angebot nachgebessert werden",
                "Die Luecke zwischen gutem Produkt und gutem Vertrieb ist meist ein Positionierungs-Fix",
                "Behandle Content nicht als Marketing. Behandle ihn als Vertrauens-Beschleuniger"
            ],
            scriptBeats: [
                "Das Problem ist nicht, dass Leute dein Angebot nicht sehen. Sie fuehlen die Dringlichkeit nicht",
                "Die meisten Gruender verwechseln Beschaeftigtsein mit Strategie. Deshalb stagniert das Wachstum",
                "Rahme den Pitch um: fuehre mit den Kosten des Stillstands, dann zeig den Weg",
                "Eine klare Fallstudie schlaegt zehn generische Testimonials jedes Mal",
                "Dein Preis ist nicht das Problem. Die wahrgenommene Wertluecke ist es",
                "Baue Content, der die Entscheidung offensichtlich macht, nicht Content, der Features erklaert"
            ],
            captionOpeners: [
                "Der Unterschied zwischen Umsatz und Rauschen ist Positionierungs-Klarheit",
                "Hoer auf, Followern hinterherzulaufen. Konvertiere die, die du schon hast",
                "So verwandeln Gruender Aufmerksamkeit in Pipeline",
                "Die meisten Angebote scheitern in der ersten Zeile, nicht in der letzten"
            ],
            ctas: [
                "Schreib mir \"Strategie\" fuer die Umsetzungsversion",
                "Folge fuer gruender-getestete Business-Systeme",
                "Speichere das vor deinem naechsten Launch",
                "Schreib \"Pipeline\", wenn du den tieferen Breakdown willst",
                "Teil das mit einem Gruender, der schaerfere Positionierung braucht"
            ],
            shotDirections: [
                "Sauberer Schreibtisch mit fettem Statement als Text-Overlay",
                "Screen-Recording des Frameworks in Aktion",
                "Halbtotale mit Whiteboard oder Sticky Notes im Bild",
                "Split Screen Vorher/Nachher der Positionierungsverbesserung",
                "Schnitt-Montage von Workflow-Tools mit Voiceover",
                "Direkt-in-die-Kamera Nahaufnahme fuer Autoritaets-Delivery"
            ],
            batchFormats: [
                "Die 3 Umsatz-Lecks, die {{audience}} bei {{topic}} nie bemerken",
                "POV: Du hoerst auf, {{topic}} zu ueberdenken, und vereinfachst das Angebot",
                "Mythos vs Fakt: Das groesste Missverstaendnis ueber {{topic}} im Business",
                "Warum die meisten Gruender an {{topic}} scheitern, obwohl das Produkt gut ist",
                "Vorher / Nachher: Wie ein Positionierungs-Shift {{topic}} komplett gefixt hat",
                "Hot Take: Der uebliche Rat zu {{topic}} haelt dich fest",
                "Tutorial: Das schlanke Framework, das {{topic}} wiederholbar macht",
                "Die versteckten Kosten, {{topic}} in deinem Business zu ignorieren",
                "3 Fehler, die fruehe Gruender bei {{topic}} machen",
                "Der echte Grund, warum deine {{topic}}-Strategie nicht konvertiert"
            ],
            nicheTags: ["business", "gruender", "startup", "unternehmer", "umsatz"]
        ),
        "fitness": ContentPool(
            hooks: [
                "Du stagnierst nicht wegen mangelndem Einsatz. Dein Programmdesign ist der Engpass",
                "Hoer auf, Muskelkater zu jagen. Fang an, progressive Ueberlastung zu verfolgen",
                "Die einfachste Ernaehrungs-Korrektur, die die meisten ignorieren, ist auch die wirksamste",
                "Wenn dein Aufwaermen 2 Minuten dauert, ist dein Training schon kompromittiert",
                "Die meisten trainieren hart. Fast niemand trainiert klug. Hier ist der Unterschied",
                "Der wahre Grund fuer dein Plateau ist nicht Genetik. Es ist Recovery-Design",
                "Du brauchst kein neues Programm. Du brauchst bessere Ausfuehrung des vorhandenen",
                "Der schnellste Weg, besser auszusehen, ist nicht mehr Cardio. Es ist weniger Rauschen im Plan"
            ],
            alternateHooks: [
                "Dein Koerper ignoriert nicht den Einsatz. Er reagiert auf die falschen Signale",
                "Die Luecke zwischen Training und Ergebnissen ist meistens eine Variable",
                "Vergiss Motivation. Bau eine Routine, die schlechte Tage ueberlebt",
                "Die Staerksten im Gym teilen eine Eigenschaft: langweilige Konsistenz",
                "Was wie ein Plateau aussieht, ist meistens ein Programmierfehler",
                "Recovery ist kein Ruhetag. Es ist eine Strategie"
            ],
            scriptBeats: [
                "Das Problem ist nicht, dass du nicht hart genug trainierst. Deine Trainingsvariablen kaempfen gegeneinander",
                "Die meisten fuegen Volumen hinzu, wenn sie Qualitaet hinzufuegen sollten. Dieser eine Wechsel aendert alles",
                "Denk an deinen Koerper wie ein System: Stress, Erholung, Anpassung. Brich den Loop und Fortschritt stoppt",
                "Ein sauber periodisierter Monat schlaegt drei Monate zufaelligen Einsatz",
                "Hoer auf, Influencer-Programme zu kopieren. Bau um deine Recovery-Kapazitaet und deinen Zeitplan",
                "Die schnellste sichtbare Veraenderung kommt davon, die Basics zu fixen, die du uebersprungen hast"
            ],
            captionOpeners: [
                "Die Luecke zwischen Einsatz und Ergebnissen ist meist eine Anpassung",
                "Die meisten uebertrainieren und untererholen. Fix das zuerst",
                "Das ist der Programmier-Fehler, der 90 Prozent der Trainierenden zurueckhaelt",
                "Dein Koerper reagiert auf Signale, nicht auf Wuensche"
            ],
            ctas: [
                "Speichere das fuer deinen naechsten Trainingsblock",
                "Folge fuer evidenzbasierte Trainings-Systeme",
                "Schreib \"Programm\" und ich teile das Template",
                "Teil das mit deinem Trainingspartner",
                "Folge, wenn du Ergebnisse ohne Rauschen willst"
            ],
            shotDirections: [
                "Gym-POV-Shot mit fettem Hook-Text auf dem Bildschirm",
                "Zeitlupe der Uebungsausfuehrung mit Form-Cue-Overlay",
                "Halbtotale mit Erklaerung am Whiteboard",
                "Vorher/Nachher-Koerpervergleich mit Daten-Overlay",
                "Schnitt-Montage von Uebungen passend zum Script-Rhythmus",
                "Nahaufnahme aufs Gesicht fuer die direkte CTA"
            ],
            batchFormats: [
                "Die 3 versteckten Gruende, warum {{audience}} bei {{topic}} stagnieren",
                "POV: Du hoerst endlich auf, {{topic}} zu verkomplizieren, und siehst Resultate",
                "Mythos vs Fakt: Die groesste Luege ueber {{topic}} im Fitness",
                "Niemand spricht ueber diese Seite von {{topic}} im Training",
                "Vorher / Nachher: Was sich aendert, wenn du {{topic}} richtig angehst",
                "Hot Take: Der populaere Ansatz zu {{topic}} macht dich schwaecher",
                "Tutorial: Das einfachste System, um {{topic}} konstant zu halten",
                "Warum fuehlt sich {{topic}} nach Monaten Training immer noch schwer an?",
                "3 Anfaengerfehler bei {{topic}}, die auch Fortgeschrittene machen",
                "Der echte Grund, warum dein {{topic}}-Fortschritt immer wieder stockt"
            ],
            nicheTags: ["fitness", "training", "gym", "gesundheit", "muskelaufbau"]
        ),
        "tech": ContentPool(
            hooks: [
                "Das Tool ist nicht das Problem. Der Workflow drumherum ist es",
                "Hoer auf, Frameworks zu lernen. Fang an, Muster zu verstehen",
                "Die meisten Entwickler schreiben Code, der funktioniert. Wenige schreiben Code, der kommuniziert",
                "Wenn deine Architektur ein Diagramm braucht, ist sie wahrscheinlich zu komplex",
                "Der schnellste Weg, bessere Software auszuliefern, ist unnoetige Abstraktionen zu loeschen",
                "Du bist nicht langsam wegen der Sprache. Du bist langsam wegen der Entscheidungen vor dem Code",
                "KI wird Entwickler nicht ersetzen. Entwickler, die Systeme verstehen, werden die ersetzen, die es nicht tun",
                "Die beste technische Entscheidung ist meistens die langweilige"
            ],
            alternateHooks: [
                "Sauberer Code ist keine Stilfrage. Es geht um kognitive Last",
                "Der 10x-Entwickler-Mythos verbirgt die wahre Faehigkeit: wissen, was man nicht bauen sollte",
                "Jede Abstraktion ist eine Wette, dass die Zukunft sie braucht",
                "Der Unterschied zwischen Junior und Senior ist nicht Syntax. Es ist Entscheidungsqualitaet",
                "Debugging ist keine Faehigkeit. Es ist ein Symptom fuer Verstaendnistiefe",
                "Die meisten technischen Schulden sind keine technischen. Es sind Kommunikationsschulden"
            ],
            scriptBeats: [
                "Das Problem ist nicht der Tech Stack. Es ist das Entscheidungs-Framework, das ihn gewaehlt hat",
                "Entwickler optimieren fuer Cleverness, wenn sie fuer Lesbarkeit und Loeschbarkeit optimieren sollten",
                "Vereinfache die Schnittstelle, begrenze die Komplexitaet, dokumentiere die Tradeoffs",
                "Eine gut abgegrenzte Funktion schlaegt eine perfekte Abstraktion, die niemand versteht",
                "Der groesste Produktivitaetsgewinn ist kein neues Tool. Es sind weniger Meetings und klarere Requirements",
                "Schreib Code fuer die naechste Person, die ihn liest, nicht fuer den Compiler"
            ],
            captionOpeners: [
                "Der echte Engpass in den meisten Projekten ist nicht Code. Es ist Klarheit",
                "Das ist das Engineering-Prinzip, das die meisten Teams zu spaet lernen",
                "Hoer auf, die falsche Schicht des Stacks zu optimieren",
                "Einfachere Systeme sind nicht schwaecher. Sie sind schneller zu fixen"
            ],
            ctas: [
                "Folge fuer Entwickler-Systeme, die wirklich ausliefern",
                "Speichere das vor deinem naechsten Architektur-Review",
                "Schreib \"Stack\", wenn du den vollen Breakdown willst",
                "Teil das mit deinem Engineering-Team",
                "Folge fuer sauberes Engineering ohne den Hype"
            ],
            shotDirections: [
                "Screen-Recording der IDE mit hervorgehobenem Code und Narration",
                "Sauberer Schreibtisch mit Laptop und Konzeptdiagramm",
                "Split Screen: unordentlicher Code vs sauber refactored",
                "Whiteboard-Skizze zur Erklaerung des Architekturprinzips",
                "Schnelle Terminal-Befehle-Montage mit Voiceover",
                "Direkt-in-die-Kamera Nahaufnahme fuer die Kern-Einsicht"
            ],
            batchFormats: [
                "Die 3 Architektur-Fehler, die {{audience}} bei {{topic}} immer wieder machen",
                "POV: Du vereinfachst endlich {{topic}} und alles wird schneller",
                "Mythos vs Fakt: Das groesste Missverstaendnis ueber {{topic}} in Tech",
                "Niemand warnt dich vor dieser Seite von {{topic}} in Produktion",
                "Vorher / Nachher: Was sich aendert, wenn du {{topic}} neu denkst",
                "Hot Take: Der populaere Ansatz zu {{topic}} schafft mehr Probleme als er loest",
                "Tutorial: Das minimale Setup, damit {{topic}} sauber funktioniert",
                "Warum fuehlt sich {{topic}} trotz Tests immer noch fragil an?",
                "3 Fehler, die jeder Entwickler bei {{topic}} macht",
                "Der echte Grund, warum {{topic}} in den meisten Teams scheitert"
            ],
            nicheTags: ["tech", "entwickler", "coding", "engineering", "software"]
        ),
        "lifestyle": ContentPool(
            hooks: [
                "Was dir niemand ueber Content-Erstellung erzaehlt, den du wirklich geniesst",
                "Deine kreative Blockade ist kein Motivationsproblem. Es ist ein Richtungsproblem",
                "Hoer auf, Trends zu kopieren. Bau einen Stil auf, der sich ueber Zeit multipliziert",
                "Die magnetischsten Creator teilen eins: sie haben aufgehoert, allen gefallen zu wollen",
                "Wenn sich dein Content gezwungen anfuehlt, ist es das System dahinter wahrscheinlich auch",
                "Der schnellste Weg, als Creator zu wachsen, ist spezifisch zu werden, wen du bedienst",
                "Deine Aesthetik ist nicht deine Marke. Deine Perspektive ist es",
                "Die Luecke zwischen Erstellen und Verbinden ist meistens ein Framing-Shift"
            ],
            alternateHooks: [
                "Der beste Content entsteht aus Einschraenkungen, nicht aus Freiheit",
                "Kreativitaet ist nicht zufaellig. Es ist eine strukturierte Gewohnheit",
                "Dein Publikum will keine Perfektion. Es will Perspektive",
                "Die unterschaetzteste kreative Faehigkeit ist zu wissen, was man weglassen soll",
                "Hoer auf zu polieren. Fang an zu veroeffentlichen. Verfeinerung kommt durch Volumen",
                "Die Version deines Contents, die ankommt, ist oft die, die sich riskant anfuehlte"
            ],
            scriptBeats: [
                "Das Problem ist kein Ideenmangel. Es ist der Versuch, zu viele Zielgruppen gleichzeitig zu bedienen",
                "Verengte die Linse: waehle einen Zuschauer, ein Gefuehl und ein Takeaway pro Beitrag",
                "Die Beitraege, die am besten performen, sind meistens die, die sich am persoenlichsten anfuehlten",
                "Trends geben dir Reichweite. Perspektive gibt dir Retention. Bau fuer das Zweite",
                "Visuelle Qualitaet zaehlt weniger als emotionale Klarheit. Fix die Botschaft zuerst",
                "Bau einen Content-Rhythmus, den du sechs Monate halten kannst, keinen Sprint, den du nach drei Wochen aufgibst"
            ],
            captionOpeners: [
                "Der Shift vom Erstellen zum Verbinden beginnt hiermit",
                "Dein Content muss nicht lauter sein. Er muss klarer sein",
                "Das ist das kreative Prinzip, das ich frueh gern gelernt haette",
                "Hoer auf, dem Algorithmus hinterherzulaufen. Fang an, dem Menschen zu dienen"
            ],
            ctas: [
                "Speichere das fuer deinen naechsten kreativen Reset",
                "Folge fuer Creator-Systeme ohne Burnout",
                "Schreib \"Create\", wenn du das volle Framework willst",
                "Teil das mit einem Creator, der es hoeren muss",
                "Folge fuer kreative Strategie, die wirklich haelt"
            ],
            shotDirections: [
                "Aesthetischer Workspace-Shot mit Hook-Text als Overlay",
                "Nahaufnahme der Haende beim Arbeiten am kreativen Projekt",
                "Sanft beleuchtete Halbtotale mit direktem Key-Insight",
                "B-Roll-Montage des kreativen Prozesses im Script-Rhythmus",
                "Rueckwaertsfahrt, die das volle Setup fuer die CTA zeigt",
                "Langsamer Schwenk ueber Moodboard oder Inspirationswand"
            ],
            batchFormats: [
                "Die 3 versteckten Gruende, warum {{audience}} sich bei {{topic}} blockiert fuehlen",
                "POV: Du hoerst auf, {{topic}} zu ueberdenken, und erschaffst einfach",
                "Mythos vs Fakt: Die groesste Luege, die Creator sich ueber {{topic}} erzaehlen",
                "Niemand spricht ueber diese Seite von {{topic}} im Creator-Space",
                "Vorher / Nachher: Was sich aendert, wenn du {{topic}} vereinfachst",
                "Hot Take: Populaerer Rat zu {{topic}} toetet deine Kreativitaet",
                "Tutorial: Das einfachste Tagessystem fuer {{topic}}",
                "Warum fuehlt sich {{topic}} noch anstrengend an, obwohl du es liebst?",
                "3 kreative Fehler, die jeder bei {{topic}} macht",
                "Der echte Grund, warum dein {{topic}}-Content nicht landet"
            ],
            nicheTags: ["creator", "lifestyle", "kreativ", "contentcreator", "storytelling"]
        ),
        "general": ContentPool(
            hooks: [
                "Das wahre Problem hinter {{topic}} ist nicht, was die meisten denken",
                "Wenn du {{topic}} immer noch so angehst, verschenkst du Resultate",
                "Die meisten scheitern an {{topic}}, bevor sie das Muster dahinter ueberhaupt erkennen",
                "Genau ueber diesen Teil von {{topic}} spricht niemand offen",
                "Der schnellste Fix fuer {{topic}} ist nicht mehr Aufwand. Es ist bessere Struktur",
                "Hoer auf, {{topic}} wie ein Willensproblem zu behandeln. Es ist ein Designproblem",
                "Hier ist der Mechanismus hinter {{topic}}, der alles aendert",
                "Die eine Anpassung, die {{topic}} endlich zum Klicken bringt"
            ],
            alternateHooks: [
                "Du bist nicht von {{topic}} blockiert, sondern von der falschen Perspektive darauf",
                "Der echte Grund, warum {{topic}} chaotisch wirkt, hat nichts mit Talent zu tun",
                "Die meisten gehen {{topic}} so an, dass es produktiv aussieht, aber Resultate verzoegert",
                "Der schnellste Hebel in {{topic}} ist nicht mehr Einsatz, sondern bessere Struktur",
                "Was, wenn alles, was du ueber {{topic}} glaubst, leicht daneben liegt?",
                "Die Version von {{topic}}, die funktioniert, ist einfacher als du denkst"
            ],
            scriptBeats: [
                "Das Problem ist nicht fehlender Wille. Das Setup rund um {{topic}} erzeugt unnoetige Reibung",
                "Die meisten reagieren auf Symptome, statt das zugrunde liegende Muster zu korrigieren",
                "Man sieht es in diesem Bereich staendig: mehr Output, mehr Stress, aber keine sauberere Positionierung",
                "Behandle {{topic}} als Systemfrage, nicht als Stimmungsschwankung",
                "Dann wird der Content klarer, leichter wiederholbar und glaubwuerdiger fuer das Publikum",
                "Der einfachste naechste Schritt ist der, der die meiste Reibung aus dem aktuellen System entfernt"
            ],
            captionOpeners: [
                "{{topic}} wird oft wie ein Motivationsproblem behandelt, obwohl es in Wahrheit ein Strukturproblem ist",
                "Genau dieser Perspektivwechsel macht den Beitrag relevanter und merkbarer",
                "Der Unterschied zwischen Stillstand und Bewegung ist meistens eine strukturelle Aenderung",
                "Das ist die Korrektur, die die meisten ueberspringen, und sie kostet Monate"
            ],
            ctas: [
                "Folge fuer taegliche, schaerfere Content-Systeme",
                "Speichere das vor deinem naechsten Posting-Sprint",
                "Schreib \"next\" und ich baue den Folge-Angle",
                "Sag mir, welche Zeile am staerksten war",
                "Teil das, wenn du mehr High-Signal-Breakdowns willst"
            ],
            shotDirections: [
                "Cold-Open-Nahaufnahme mit dem Hook als fettem On-Screen-Text",
                "Schneller Detailshot, der die Reibung sichtbar macht",
                "Halbtotale waehrend du das uebersehene Muster erklaerst",
                "Lege 3 kurze Text-Beats ein, die das Argument vereinfachen",
                "Beende mit direktem Blickkontakt fuer die CTA",
                "B-Roll-Uebergang, der das Konzept in Aktion zeigt"
            ],
            batchFormats: [
                "Die 3 versteckten Gruende, warum {{audience}} bei {{topic}} haengen bleiben",
                "POV: Du hoerst auf, {{topic}} zu verkomplizieren",
                "Mythos vs Fakt: Die groesste Luege ueber {{topic}}",
                "Niemand spricht ueber diese Seite von {{topic}}",
                "Vorher / Nachher: Was sich aendert, wenn du {{topic}} neu aufsetzt",
                "Hot Take: Der meiste Rat zu {{topic}} pflegt das Ego, nicht das Ergebnis",
                "Tutorial: Der einfachste Workflow, um {{topic}} wiederholbar zu machen",
                "Frage-Hook: Warum fuehlt sich {{topic}} noch schwer an, obwohl du die Schritte kennst?",
                "3 Fehler, die Einsteiger bei {{topic}} machen",
                "Der echte Grund hinter inkonsistentem {{topic}}"
            ],
            nicheTags: ["contentstrategy", "creatorleben", "wachstumstipps", "contentcreation", "onlinebusiness"]
        )
    ]
}

// MARK: - Tone modifier

private struct ToneModifier {
    let openerEn: String
    let openerDe: String
    let adjectiveEn: String
    let adjectiveDe: String

    static func resolve(_ tone: ContentTone) -> ToneModifier {
        modifiers[tone] ?? modifiers[.direct]!
    }

    private static let modifiers: [ContentTone: ToneModifier] = [
        .serious: .init(openerEn: "Cut the noise.", openerDe: "Streich das Rauschen.", adjectiveEn: "measured and credible", adjectiveDe: "sachlich und glaubwuerdig"),
        .dark: .init(openerEn: "This part is uncomfortable.", openerDe: "Dieser Teil ist unbequem.", adjectiveEn: "dark with controlled edge", adjectiveDe: "dunkel mit kontrollierter Schaerfe"),
        .funny: .init(openerEn: "This is where it gets a little ridiculous.", openerDe: "Ab hier wird es leicht absurd.", adjectiveEn: "smart and light without losing clarity", adjectiveDe: "clever und leicht, aber klar"),
        .confident: .init(openerEn: "Here is the real move.", openerDe: "Hier ist der echte Move.", adjectiveEn: "sharp and self-assured", adjectiveDe: "klar und selbstsicher"),
        .luxury: .init(openerEn: "Most people approach this cheaply.", openerDe: "Die meisten gehen das zu billig an.", adjectiveEn: "refined and elevated", adjectiveDe: "edel und hochwertig"),
        .educational: .init(openerEn: "Here is the simplest way to understand it.", openerDe: "So verstehst du es am einfachsten.", adjectiveEn: "clear and structured", adjectiveDe: "klar und strukturiert"),
        .emotional: .init(openerEn: "This hits because it feels personal.", openerDe: "Das trifft, weil es persoenlich fuehlt.", adjectiveEn: "human and vivid", adjectiveDe: "menschlich und intensiv"),
        .direct: .init(openerEn: "Most people are doing this backwards.", openerDe: "Die meisten machen das rueckwaerts.", adjectiveEn: "brief and no-nonsense", adjectiveDe: "knapp und kompromisslos")
    ]
}

// MARK: - Content builders with platform and tone awareness

private extension MockContentGenerationService {
    func fillTemplate(_ template: String, topic: String, audience: String) -> String {
        template
            .replacingOccurrences(of: "{{topic}}", with: topic)
            .replacingOccurrences(of: "{{audience}}", with: audience)
    }

    func buildTitle(topic: String, pool: ContentPool, request: GenerationRequest, seed: String) -> String {
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

    func buildHook(topic: String, pool: ContentPool, request: GenerationRequest, seed: String) -> String {
        let candidates = pool.hooks.map { fillTemplate($0, topic: topic, audience: request.audience) }
        var hook = StablePicker.pick(candidates, seed: seed, salt: "hook")

        // Platform constraints
        switch request.platform {
        case .tiktok:
            hook = String(hook.prefix(90))
        case .instagramReels:
            hook = String(hook.prefix(150))
        default:
            break
        }

        return hook
    }

    func buildAlternateHooks(topic: String, pool: ContentPool, request: GenerationRequest, seed: String) -> [String] {
        let candidates = pool.alternateHooks.map { fillTemplate($0, topic: topic, audience: request.audience) }
        return StablePicker.picks(candidates, count: 3, seed: seed, salt: "alternate")
    }

    func buildScript(topic: String, category: String, pool: ContentPool, request: GenerationRequest, hook: String, seed: String) -> String {
        let tone = ToneModifier.resolve(request.tone)
        let beats = pool.scriptBeats.map { fillTemplate($0, topic: topic, audience: request.audience) }

        let reframe = request.language == .german
            ? "\(tone.openerDe) Behandle \(topic) als Systemfrage, nicht als Stimmungsschwankung."
            : "\(tone.openerEn) Treat \(topic) like a system design question, not a mood problem."

        let close = buildCTA(topic: topic, pool: pool, request: request, seed: seed)

        var scriptBeats = [hook, reframe]
        let shuffledBeats = StablePicker.picks(beats, count: min(beats.count, 4), seed: seed, salt: "script")
        scriptBeats.append(contentsOf: shuffledBeats)
        scriptBeats.append(close)

        let maxBeats = request.durationSeconds <= 20 ? 4 : request.durationSeconds <= 35 ? 5 : 6

        let result = scriptBeats.prefix(maxBeats).enumerated().map { index, line in
            "\(index + 1). \(line)"
        }.joined(separator: "\n")

        // Platform: YouTube scripts should be at least 220 characters
        if request.platform == .youtubeShorts && result.count < 220 {
            let filler = request.language == .german
                ? "\(maxBeats + 1). Dieser Punkt macht den Unterschied fuer \(request.audience) in \(category) klar und umsetzbar."
                : "\(maxBeats + 1). This point makes the difference clear and actionable for \(request.audience) in \(category)."
            return result + "\n" + filler
        }

        return result
    }

    func buildVoiceover(script: String, request: GenerationRequest) -> String {
        let stripped = script
            .split(separator: "\n")
            .map { $0.replacingOccurrences(of: #"^\d+\.\s"#, with: "", options: .regularExpression) }
            .joined(separator: " ")

        if request.platform == .x {
            return String(stripped.prefix(260))
        }
        return stripped
    }

    func buildCaption(topic: String, category: String, pool: ContentPool, request: GenerationRequest, hook: String, seed: String) -> String {
        let captionOpeners = pool.captionOpeners.map { fillTemplate($0, topic: topic, audience: request.audience) }
        let opener = StablePicker.pick(captionOpeners, seed: seed, salt: "caption")

        let platformCloser = request.language == .german
            ? "Speicher das, teste es diese Woche, und beobachte was sich am Response veraendert."
            : "Save this, test it this week, and watch how the response changes."

        let angleLine = request.language == .german
            ? "Genau dieser Perspektivwechsel macht den Beitrag in \(category) relevanter und merkbarer."
            : "That perspective shift is what makes the piece more relevant and memorable inside \(category)."

        let caption: String
        switch request.platform {
        case .x:
            caption = String("\(hook)\n\n\(opener)\n\(angleLine)\n\n\(platformCloser)".prefix(275))
        case .instagramReels:
            // Instagram captions max 220 chars
            let full = "\(opener)\n\n\(angleLine)\n\n\(platformCloser)"
            caption = String(full.prefix(220))
        default:
            caption = "\(hook)\n\n\(opener)\n\(angleLine)\n\n\(platformCloser)"
        }

        return caption
    }

    func buildHashtags(topic: String, category: String, pool: ContentPool, request: GenerationRequest) -> [String] {
        let cleanTopic = cleanTag(from: topic)
        let cleanCategory = cleanTag(from: category)
        let goal = cleanTag(from: request.goal.rawValue)
        let style = cleanTag(from: request.style.rawValue)

        var tags: [String] = []

        // Platform-specific base tags
        switch request.platform {
        case .tiktok:
            tags = ["#\(cleanTopic)", "#\(cleanCategory)creator", "#viralhooks", "#\(goal)", "#\(style)"]
        case .instagramReels:
            tags = ["#\(cleanCategory)reels", "#contentstrategy", "#saveworthy", "#\(cleanTopic)", "#\(goal)"]
        case .youtubeShorts:
            tags = ["#shorts", "#\(cleanTopic)", "#\(cleanCategory)", "#authoritycontent", "#\(goal)"]
        case .x:
            tags = ["#contentstrategy", "#\(cleanCategory)", "#\(goal)", "#buildinpublic"]
        }

        // Add category-specific niche tags to reach 8-12
        for nicheTag in pool.nicheTags {
            if tags.count >= 12 { break }
            let tag = "#\(nicheTag)"
            if !tags.contains(tag) {
                tags.append(tag)
            }
        }

        // Fill up to at least 8 with common tags
        let fillers = request.language == .german
            ? ["#contentcreator", "#wachstum", "#creatorlife"]
            : ["#contentcreator", "#growth", "#creatorlife"]
        for filler in fillers {
            if tags.count >= 8 { break }
            if !tags.contains(filler) { tags.append(filler) }
        }

        return tags
    }

    func buildCTA(topic: String, pool: ContentPool, request: GenerationRequest, seed: String) -> String {
        let candidates = pool.ctas.map { fillTemplate($0, topic: topic, audience: request.audience) }
        return StablePicker.pick(candidates, seed: seed, salt: "cta")
    }

    func buildShotList(topic: String, category: String, pool: ContentPool, request: GenerationRequest) -> [String] {
        guard request.platform != .x else { return [] }

        let candidates = pool.shotDirections.map { fillTemplate($0, topic: topic, audience: request.audience) }
        let count = min(candidates.count, request.durationSeconds <= 20 ? 4 : 6)
        return Array(candidates.prefix(count))
    }

    func buildNotes(request: GenerationRequest) -> String {
        if request.language == .german {
            return "Offline-Mock-Modus aktiv. Dieser Entwurf wurde lokal mit Plattform-, Ton- und Stilregeln erzeugt und kann vor dem Posten manuell geschaerft werden."
        }
        return "Offline mock mode is active. This draft was generated locally using platform, tone, and style heuristics and can be sharpened manually before posting."
    }

    func buildVideoAIPrompt(topic: String, request: GenerationRequest, hook: String, shotList: [String]) -> String {
        let scenes = shotList.enumerated().map { i, shot in
            "Scene \(i + 1): \(shot)"
        }.joined(separator: "\n")

        return """
        [TOPIC] \(topic)
        [PLATFORM] \(request.platform.rawValue)
        [TONE] \(request.tone.rawValue)
        [HOOK_VISUAL] \(hook)
        \(scenes)
        [DURATION] \(request.durationSeconds)s
        """
    }

    func buildBatchIdeas(topic: String, category: String, pool: ContentPool, request: GenerationRequest, seed: String) -> [String] {
        let source = pool.batchFormats.map { fillTemplate($0, topic: topic, audience: request.audience) }
        return StablePicker.shuffled(source, seed: seed, salt: "batch").prefix(10).map(\.self)
    }

    // MARK: - Shared helpers

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
        let tone = ToneModifier.resolve(request.tone)
        let styleCue = styleCue(for: request.style, language: request.language)
        let goalLine = goalOutcome(for: request.goal, language: request.language)

        if request.language == .german {
            return "\(angle) Der Beitrag nutzt einen \(tone.adjectiveDe) Ton, folgt einem \(styleCue)-Aufbau und fuehrt den Zuschauer in Richtung \(goalLine)."
        }

        return "\(angle) The piece uses a \(tone.adjectiveEn) tone, follows a \(styleCue) structure, and moves the viewer toward \(goalLine)."
    }

    func localizedPerformanceRationale(request: GenerationRequest, hook: String) -> String {
        let platformReason = platformFit(for: request.platform, language: request.language)

        if request.language == .german {
            return "Warum es funktionieren kann: Der Hook baut schnell Reibung auf, der Mittelteil liefert Klarheit, und die CTA gibt einen einfachen naechsten Schritt. Das passt zu \(platformReason) und staerkt Glaubwuerdigkeit."
        }

        return "Why it may perform well: the hook builds fast tension, the middle delivers clarity, and the CTA gives a low-friction next step. That matches \(platformReason) and strengthens credibility."
    }

    func localizedEmotionalTrigger(request: GenerationRequest, category: String) -> String {
        if request.language == .german {
            return "Der Beitrag erzeugt Spannung zwischen dem aktuellen Verhalten des Zuschauers und dem Ergebnis, das er eigentlich will. Diese kontrollierte Reibung macht \(category) sofort relevanter."
        }

        return "The piece creates tension between the viewer's current behavior and the result they actually want. That controlled friction makes \(category) instantly more relevant."
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
