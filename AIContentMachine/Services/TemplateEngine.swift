import Foundation

struct TemplateQuickStart: Equatable {
    let topic: String
    let audience: String
    let category: String
    let mode: GenerationMode
    let durationSeconds: Double
}

enum TemplateEngine {
    static func makeDefaultTemplates() -> [TemplateModel] {
        [
            starter(
                seedKey: "controversial-truth",
                name: "Controversial truth",
                description: "Lead with a sharp truth that challenges lazy consensus and earns reactions fast.",
                category: "Authority / Thought Leadership",
                exampleHook: "The advice everyone repeats about growth is exactly why most people stay invisible.",
                structureRules: ["Hard truth", "Contrast", "Specific example", "Direct CTA"],
                idealPlatforms: [.tiktok, .x],
                recommendedTone: .confident,
                recommendedGoal: .engagement,
                recommendedStyle: .hotTake,
                blueprint: "Start with a sharp contrarian claim, support it with one believable example, then land the lesson with a clean CTA.",
                exampleScriptDirection: "Open on the hard truth, explain why common advice fails, then give one better operating principle.",
                exampleCaptionDirection: "Restate the controversy in one line, add the core reason, and invite debate or saves.",
                tier: .free,
                sortOrder: 1
            ),
            starter(
                seedKey: "three-mistakes-people-make",
                name: "3 mistakes people make",
                description: "Turn recurring beginner errors into a compact save-worthy list format.",
                category: "Education / Explainer",
                exampleHook: "Three mistakes creators make before they even hit record.",
                structureRules: ["Numbered list", "Short examples", "Actionable correction", "Save CTA"],
                idealPlatforms: [.instagramReels, .youtubeShorts],
                recommendedTone: .educational,
                recommendedGoal: .engagement,
                recommendedStyle: .top3List,
                blueprint: "Use a clean three-part structure with fast examples and one correction per point.",
                exampleScriptDirection: "Move quickly through mistake one, two, and three, and make the correction immediately useful.",
                exampleCaptionDirection: "Summarize the three errors and encourage the viewer to save before the next recording session.",
                tier: .free,
                sortOrder: 2
            ),
            starter(
                seedKey: "nobody-talks-about-this",
                name: "Nobody talks about this",
                description: "Frame an overlooked truth with emotional tension and creator credibility.",
                category: "Personal Brand",
                exampleHook: "Nobody talks about the emotional tax behind consistency.",
                structureRules: ["Hidden angle", "Emotional truth", "Reframe", "Comment CTA"],
                idealPlatforms: [.tiktok, .instagramReels],
                recommendedTone: .emotional,
                recommendedGoal: .engagement,
                recommendedStyle: .storytime,
                blueprint: "Reveal a hidden truth people feel but rarely say out loud, then connect it to a practical creator lesson.",
                exampleScriptDirection: "Open with the hidden angle, name the emotional cost, then explain what to do differently.",
                exampleCaptionDirection: "Use a short emotional summary and invite people to comment if they have felt the same tension.",
                tier: .free,
                sortOrder: 3
            ),
            starter(
                seedKey: "stop-doing-this-if-you-want-x",
                name: "Stop doing this if you want X",
                description: "Use a stop-start pattern to make conversion and decision content feel direct.",
                category: "Product / Offer / Conversion",
                exampleHook: "Stop posting random tips if you want followers who actually buy.",
                structureRules: ["Command", "Reason", "Replacement tactic", "Action CTA"],
                idealPlatforms: [.tiktok, .instagramReels],
                recommendedTone: .direct,
                recommendedGoal: .sales,
                recommendedStyle: .shortPunchyHook,
                blueprint: "Start with a command, name the hidden cost, replace it with a better move, then push a CTA.",
                exampleScriptDirection: "Say what to stop, explain what it breaks, then give the cleaner conversion-focused replacement.",
                exampleCaptionDirection: "Make the stop-start contrast obvious and end with a low-friction CTA.",
                tier: .free,
                sortOrder: 4
            ),
            starter(
                seedKey: "founder-lesson-from-a-hard-week",
                name: "Founder lesson from a hard week",
                description: "Turn a recent founder setback into a useful, trust-building creator lesson.",
                category: "Founder / Business",
                exampleHook: "Last week punched me in the face and it fixed how I build content.",
                structureRules: ["Real moment", "What went wrong", "Lesson", "Forward-looking CTA"],
                idealPlatforms: [.instagramReels, .x],
                recommendedTone: .serious,
                recommendedGoal: .authority,
                recommendedStyle: .storytime,
                blueprint: "Use one real hard week moment to show credibility, reflection, and a practical founder takeaway.",
                exampleScriptDirection: "Tell the failure moment fast, explain what it exposed, then frame the new operating rule.",
                exampleCaptionDirection: "Make it feel personal first, then pull out the lesson people can reuse immediately.",
                tier: .free,
                sortOrder: 5
            ),
            starter(
                seedKey: "mini-case-study-for-trust-building",
                name: "Mini case study for trust building",
                description: "Show proof through one small result story instead of abstract advice.",
                category: "Authority / Thought Leadership",
                exampleHook: "One small client win taught me more about trust than 100 content tips.",
                structureRules: ["Context", "Change", "Result", "Lesson"],
                idealPlatforms: [.youtubeShorts, .instagramReels],
                recommendedTone: .educational,
                recommendedGoal: .authority,
                recommendedStyle: .comparison,
                blueprint: "Ground the content in a small but believable case study, then extract a reusable rule.",
                exampleScriptDirection: "Set the before state, describe the change, show the result, and end on the insight.",
                exampleCaptionDirection: "Use the result as social proof and reinforce the lesson with one takeaway line.",
                tier: .free,
                sortOrder: 6
            ),
            starter(
                seedKey: "story-that-ends-in-a-lesson",
                name: "A story that ends in a lesson",
                description: "Use a compact narrative arc that lands on a clear takeaway for the viewer.",
                category: "Storytelling",
                exampleHook: "I thought this was a lucky break until I saw what actually caused it.",
                structureRules: ["Setup", "Tension", "Turn", "Lesson"],
                idealPlatforms: [.tiktok, .instagramReels],
                recommendedTone: .emotional,
                recommendedGoal: .followers,
                recommendedStyle: .storytime,
                blueprint: "Tell a short event with rising tension, then convert it into a sharp lesson worth remembering.",
                exampleScriptDirection: "Open inside the moment, add one twist, and close on the lesson instead of over-explaining.",
                exampleCaptionDirection: "Summarize the story in one emotional line and end with the takeaway.",
                tier: .free,
                sortOrder: 7
            ),
            starter(
                seedKey: "teach-one-tactical-insight-fast",
                name: "Teach one tactical insight fast",
                description: "Deliver one practical lesson with zero fluff for viewers who want clarity.",
                category: "Education / Explainer",
                exampleHook: "If you only fix one part of your content system this week, fix this.",
                structureRules: ["Single lesson", "Fast teaching", "Application", "Save CTA"],
                idealPlatforms: [.youtubeShorts, .tiktok],
                recommendedTone: .educational,
                recommendedGoal: .authority,
                recommendedStyle: .tutorial,
                blueprint: "Teach one tactical move fast enough to feel high-signal and easy to apply the same day.",
                exampleScriptDirection: "Name the tactic, explain why it matters, then show exactly where it changes the workflow.",
                exampleCaptionDirection: "State the tactic clearly and tell the viewer when to use it.",
                tier: .free,
                sortOrder: 8
            ),
            starter(
                seedKey: "this-is-why-people-fail-at-x",
                name: "This is why people fail at X",
                description: "Explain failure through a single overlooked mechanism and position yourself as the clearer voice.",
                category: "Authority / Thought Leadership",
                exampleHook: "This is why smart people still fail at audience growth.",
                structureRules: ["Failure pattern", "Core cause", "Proof", "Fix"],
                idealPlatforms: [.youtubeShorts, .x],
                recommendedTone: .serious,
                recommendedGoal: .authority,
                recommendedStyle: .deepExplanation,
                blueprint: "Take one failure everyone recognizes, reveal the mechanism behind it, then give the correction.",
                exampleScriptDirection: "Name the failure, expose the real cause, and guide the viewer toward the fix.",
                exampleCaptionDirection: "Frame the failure as a systems problem and reinforce the correction.",
                tier: .pro,
                sortOrder: 9
            ),
            starter(
                seedKey: "the-real-reason-behind-x",
                name: "The real reason behind X",
                description: "Pull back the curtain and explain the hidden driver behind a visible outcome.",
                category: "Authority / Thought Leadership",
                exampleHook: "The real reason some creators look effortless is boring, not magical.",
                structureRules: ["Reveal", "Mechanism", "Example", "Takeaway"],
                idealPlatforms: [.youtubeShorts, .tiktok],
                recommendedTone: .confident,
                recommendedGoal: .engagement,
                recommendedStyle: .deepExplanation,
                blueprint: "Use a reveal format that makes the viewer rethink the visible result they keep misreading.",
                exampleScriptDirection: "State the visible result, uncover the boring real cause, and end with a practical insight.",
                exampleCaptionDirection: "Restate the hidden reason and tie it to a creator behavior worth adopting.",
                tier: .pro,
                sortOrder: 10
            ),
            starter(
                seedKey: "you-think-x-but-actually-y",
                name: "You think X, but actually Y",
                description: "Use contrast framing to sharpen clarity and stop the scroll immediately.",
                category: "Education / Explainer",
                exampleHook: "You think discipline starts with motivation, but actually it starts with friction.",
                structureRules: ["Expectation", "Correction", "Reasoning", "CTA"],
                idealPlatforms: [.tiktok, .youtubeShorts],
                recommendedTone: .direct,
                recommendedGoal: .engagement,
                recommendedStyle: .mythVsFact,
                blueprint: "Open on a familiar assumption, flip it fast, then explain the better mental model.",
                exampleScriptDirection: "Name the wrong belief, replace it with the sharper truth, and give one proof point.",
                exampleCaptionDirection: "Lead with the contrast line and add one clean supporting insight.",
                tier: .pro,
                sortOrder: 11
            ),
            starter(
                seedKey: "if-i-had-to-start-again",
                name: "If I had to start again",
                description: "Compress experience into a reset framework that feels practical and authoritative.",
                category: "Founder / Business",
                exampleHook: "If I had to rebuild my audience from zero, I would ignore 90 percent of the usual advice.",
                structureRules: ["Reset frame", "Priorities", "Why", "CTA"],
                idealPlatforms: [.youtubeShorts, .x],
                recommendedTone: .confident,
                recommendedGoal: .followers,
                recommendedStyle: .comparison,
                blueprint: "Speak from experience and cut directly to the priorities that matter when starting from zero.",
                exampleScriptDirection: "Open with the reset premise, list the first priorities, and justify them quickly.",
                exampleCaptionDirection: "Summarize the starting priorities and tell viewers what to focus on first.",
                tier: .pro,
                sortOrder: 12
            ),
            starter(
                seedKey: "common-advice-that-is-wrong",
                name: "Common advice that is wrong",
                description: "Dismantle popular advice and replace it with a stronger creator operating rule.",
                category: "Authority / Thought Leadership",
                exampleHook: "Common advice says post more. The better move is usually publish with cleaner signal.",
                structureRules: ["Popular advice", "Why it fails", "Better rule", "Takeaway"],
                idealPlatforms: [.x, .tiktok],
                recommendedTone: .confident,
                recommendedGoal: .authority,
                recommendedStyle: .controversialOpinion,
                blueprint: "Challenge one accepted belief, explain the hidden cost, and replace it with a sharper rule.",
                exampleScriptDirection: "Name the advice everyone repeats, show why it breaks, then state the replacement.",
                exampleCaptionDirection: "Keep the contradiction visible and invite the viewer to rethink their default behavior.",
                tier: .pro,
                sortOrder: 13
            ),
            starter(
                seedKey: "before-after-transformation-breakdown",
                name: "Before / After transformation breakdown",
                description: "Show a clean transformation arc that makes the outcome feel concrete and believable.",
                category: "Motivation / Mindset",
                exampleHook: "Before I fixed this one pattern, my content felt noisy. After it, everything tightened.",
                structureRules: ["Before", "Change", "After", "Lesson"],
                idealPlatforms: [.instagramReels, .tiktok],
                recommendedTone: .confident,
                recommendedGoal: .followers,
                recommendedStyle: .beforeAfter,
                blueprint: "Use a visible before/after contrast and explain the one change that caused the shift.",
                exampleScriptDirection: "Paint the before state fast, reveal the single shift, then show the improved result.",
                exampleCaptionDirection: "Use the contrast to make the transformation easy to picture and save.",
                tier: .pro,
                sortOrder: 14
            ),
            starter(
                seedKey: "contrarian-opinion-in-20-seconds",
                name: "Contrarian opinion in 20 seconds",
                description: "Deliver a high-retention short hook that creates tension fast and ends clean.",
                category: "Trend / Short Hook",
                exampleHook: "Unpopular opinion: consistency is overrated when your signal is weak.",
                structureRules: ["Contrarian opener", "One supporting reason", "Punchline", "Comment CTA"],
                idealPlatforms: [.tiktok, .x],
                recommendedTone: .direct,
                recommendedGoal: .engagement,
                recommendedStyle: .shortPunchyHook,
                blueprint: "Keep it brutally short, highly opinionated, and built to trigger reaction or saves.",
                exampleScriptDirection: "State the contrarian claim, justify it with one sharp reason, then stop.",
                exampleCaptionDirection: "Keep the caption minimal and invite disagreement or proof-backed debate.",
                tier: .pro,
                sortOrder: 15
            ),
            starter(
                seedKey: "pain-agitate-solve-short-form",
                name: "Pain-agitate-solve short form",
                description: "Use a direct response structure that moves from pain to action quickly.",
                category: "Product / Offer / Conversion",
                exampleHook: "If your content gets views but no buyers, your message is probably stuck at the pain stage.",
                structureRules: ["Pain", "Agitate", "Solve", "CTA"],
                idealPlatforms: [.instagramReels, .youtubeShorts],
                recommendedTone: .direct,
                recommendedGoal: .leads,
                recommendedStyle: .tutorial,
                blueprint: "Start in the audience pain, intensify the cost, then present the clean solution and CTA.",
                exampleScriptDirection: "Name the pain, explain why it costs them, then reveal the solution as a next step.",
                exampleCaptionDirection: "Repeat the pain-solve path and push a more conversion-focused CTA.",
                tier: .pro,
                sortOrder: 16
            ),
            starter(
                seedKey: "behind-the-scenes-build-in-public",
                name: "Behind the scenes build in public",
                description: "Show progress, tradeoffs, and momentum in a way that feels transparent and credible.",
                category: "Founder / Business",
                exampleHook: "Behind the scenes, this is what building a creator system actually looks like on a messy week.",
                structureRules: ["Current build stage", "Real tradeoff", "Lesson", "Follow CTA"],
                idealPlatforms: [.instagramReels, .x],
                recommendedTone: .serious,
                recommendedGoal: .followers,
                recommendedStyle: .pov,
                blueprint: "Use build-in-public energy to turn messy progress into a trust-building update.",
                exampleScriptDirection: "Show what is being built, where friction is happening, and what that taught you.",
                exampleCaptionDirection: "Frame it as an honest progress update and invite people into the journey.",
                tier: .pro,
                sortOrder: 17
            ),
            starter(
                seedKey: "what-i-would-do-from-zero",
                name: "What I would do from zero",
                description: "Create a highly practical plan format for creators rebuilding attention from scratch.",
                category: "Founder / Business",
                exampleHook: "If I had zero audience and one month to get traction, this is the exact plan I would run.",
                structureRules: ["Constraint", "Plan", "Priority order", "CTA"],
                idealPlatforms: [.youtubeShorts, .instagramReels],
                recommendedTone: .educational,
                recommendedGoal: .authority,
                recommendedStyle: .tutorial,
                blueprint: "Use a clear constraint and give a practical reset plan with priority order and tradeoffs.",
                exampleScriptDirection: "State the constraint, move through priority one to three, and explain the sequence.",
                exampleCaptionDirection: "Summarize the zero-to-one plan and tell viewers which step comes first.",
                tier: .pro,
                sortOrder: 18
            ),
            starter(
                seedKey: "myth-vs-reality-in-your-niche",
                name: "Myth vs reality in your niche",
                description: "Correct common niche myths while sounding sharper and more community-aware.",
                category: "Niche Creator / Community",
                exampleHook: "Myth: your niche is too small. Reality: your signal is still too generic.",
                structureRules: ["Myth", "Reality", "Reason", "CTA"],
                idealPlatforms: [.tiktok, .x],
                recommendedTone: .confident,
                recommendedGoal: .engagement,
                recommendedStyle: .mythVsFact,
                blueprint: "Use myth-versus-reality framing to call out lazy beliefs inside a specific niche.",
                exampleScriptDirection: "Name the myth, cut to the reality, and show why the niche actually behaves differently.",
                exampleCaptionDirection: "Keep the myth and reality highly skimmable and invite niche-specific discussion.",
                tier: .pro,
                sortOrder: 19
            ),
            starter(
                seedKey: "hot-take-with-personal-proof",
                name: "Hot take with personal proof",
                description: "Pair a strong opinion with a real experience so it feels earned instead of empty.",
                category: "Personal Brand",
                exampleHook: "Hot take: most content advice is performance theater. I know because I used to follow it.",
                structureRules: ["Hot take", "Personal proof", "Lesson", "CTA"],
                idealPlatforms: [.tiktok, .instagramReels],
                recommendedTone: .confident,
                recommendedGoal: .engagement,
                recommendedStyle: .controversialOpinion,
                blueprint: "Back up the hot take with personal proof so the opinion carries trust instead of noise.",
                exampleScriptDirection: "Open with the opinion, add the personal proof, and explain the lesson cleanly.",
                exampleCaptionDirection: "Use the hot take as the first line and support it with one real proof point.",
                tier: .pro,
                sortOrder: 20
            ),
            starter(
                seedKey: "quick-authority-breakdown",
                name: "Quick authority breakdown",
                description: "Compress expertise into a fast high-signal explanation that makes the viewer trust your framing.",
                category: "Authority / Thought Leadership",
                exampleHook: "Here is the five-second signal that tells me whether a content strategy will work.",
                structureRules: ["Authority claim", "Signal", "Explanation", "CTA"],
                idealPlatforms: [.youtubeShorts, .x],
                recommendedTone: .serious,
                recommendedGoal: .authority,
                recommendedStyle: .deepExplanation,
                blueprint: "Teach one advanced signal fast and make the viewer feel they learned something insiders notice.",
                exampleScriptDirection: "State the signal, explain what it reveals, and tell the viewer how to apply it.",
                exampleCaptionDirection: "Summarize the insight sharply and tell people what to audit next.",
                tier: .pro,
                sortOrder: 21
            ),
            starter(
                seedKey: "direct-response-offer-cta",
                name: "Direct response offer CTA",
                description: "Frame an offer-led piece so the CTA feels natural, clear, and conversion-ready.",
                category: "Product / Offer / Conversion",
                exampleHook: "If your audience already feels the pain, the problem is usually how softly you present the solution.",
                structureRules: ["Pain signal", "Value frame", "Offer line", "Direct CTA"],
                idealPlatforms: [.instagramReels, .x],
                recommendedTone: .direct,
                recommendedGoal: .sales,
                recommendedStyle: .questionBasedHook,
                blueprint: "Build the clip around the offer outcome and make the CTA feel like the obvious next step.",
                exampleScriptDirection: "Lead with the pain signal, bridge to the solution, then state the offer directly.",
                exampleCaptionDirection: "Keep the value proposition tight and let the CTA remain explicit.",
                tier: .pro,
                sortOrder: 22
            )
        ]
    }

    static func quickStart(for template: TemplateModel) -> TemplateQuickStart? {
        switch template.seedKey {
        case "this-is-why-people-fail-at-x":
            return TemplateQuickStart(
                topic: "Why smart creators still fail to turn attention into qualified clients",
                audience: "Solo founders and personal-brand creators trying to monetize short-form content",
                category: "Authority / Thought Leadership",
                mode: .fullPackage,
                durationSeconds: 35
            )
        case "the-real-reason-behind-x":
            return TemplateQuickStart(
                topic: "The real reason consistent creators still look invisible online",
                audience: "Creators posting every week without meaningful growth",
                category: "Authority / Thought Leadership",
                mode: .fullPackage,
                durationSeconds: 30
            )
        case "you-think-x-but-actually-y":
            return TemplateQuickStart(
                topic: "You think more content fixes low reach, but clearer positioning does",
                audience: "Early-stage creators stuck below their next growth step",
                category: "Education / Explainer",
                mode: .fullPackage,
                durationSeconds: 25
            )
        case "if-i-had-to-start-again":
            return TemplateQuickStart(
                topic: "If I had to rebuild a founder audience from zero in 2026, this is where I would start",
                audience: "Founders starting a personal brand from scratch",
                category: "Founder / Business",
                mode: .fullPackage,
                durationSeconds: 40
            )
        case "common-advice-that-is-wrong":
            return TemplateQuickStart(
                topic: "Common content advice that keeps small creators generic",
                audience: "Creators following broad growth advice that never converts",
                category: "Authority / Thought Leadership",
                mode: .fullPackage,
                durationSeconds: 30
            )
        case "before-after-transformation-breakdown":
            return TemplateQuickStart(
                topic: "Before and after I turned random posting into a repeatable content system",
                audience: "Creators who feel inconsistent and scattered",
                category: "Motivation / Mindset",
                mode: .fullPackage,
                durationSeconds: 35
            )
        case "contrarian-opinion-in-20-seconds":
            return TemplateQuickStart(
                topic: "Unpopular opinion: consistency is overrated when your message is weak",
                audience: "Short-form creators obsessed with output volume",
                category: "Trend / Short Hook",
                mode: .fullPackage,
                durationSeconds: 20
            )
        case "pain-agitate-solve-short-form":
            return TemplateQuickStart(
                topic: "Why your content gets views but no qualified leads",
                audience: "Coaches and service founders who want buyers, not just reach",
                category: "Product / Offer / Conversion",
                mode: .fullPackage,
                durationSeconds: 30
            )
        case "behind-the-scenes-build-in-public":
            return TemplateQuickStart(
                topic: "What building an AI content system actually looks like during a messy founder week",
                audience: "Founders and indie builders who like build-in-public content",
                category: "Founder / Business",
                mode: .fullPackage,
                durationSeconds: 35
            )
        case "what-i-would-do-from-zero":
            return TemplateQuickStart(
                topic: "What I would do from zero to get my first 100 qualified followers in 30 days",
                audience: "Creators rebuilding from scratch with limited time",
                category: "Founder / Business",
                mode: .fullPackage,
                durationSeconds: 40
            )
        case "myth-vs-reality-in-your-niche":
            return TemplateQuickStart(
                topic: "Myth vs reality: your niche is not too small, your angle is too vague",
                audience: "Niche creators who think the market is too small",
                category: "Niche Creator / Community",
                mode: .fullPackage,
                durationSeconds: 25
            )
        case "hot-take-with-personal-proof":
            return TemplateQuickStart(
                topic: "Hot take: most content advice is performance theater unless it leads to a real action",
                audience: "Creators tired of generic social media tips",
                category: "Personal Brand",
                mode: .fullPackage,
                durationSeconds: 30
            )
        case "quick-authority-breakdown":
            return TemplateQuickStart(
                topic: "The fastest signal that tells me a content strategy will never convert",
                audience: "Experts and consultants using content to build authority",
                category: "Authority / Thought Leadership",
                mode: .fullPackage,
                durationSeconds: 25
            )
        case "direct-response-offer-cta":
            return TemplateQuickStart(
                topic: "How to present your offer on short-form video without sounding pushy",
                audience: "Creators and founders who need more sales conversations",
                category: "Product / Offer / Conversion",
                mode: .fullPackage,
                durationSeconds: 30
            )
        default:
            return nil
        }
    }

    static func structureHint(templateName: String?, rules: [String], language: ContentLanguage) -> String {
        guard let templateName, !rules.isEmpty else { return "" }

        let rules = rules.joined(separator: " • ")

        if language == .german {
            return "Vorlage: \(templateName). Struktur: \(rules)."
        }

        return "Template: \(templateName). Structure: \(rules)."
    }

    private static func starter(
        seedKey: String,
        name: String,
        description: String,
        category: String,
        exampleHook: String,
        structureRules: [String],
        idealPlatforms: [ContentPlatform],
        recommendedTone: ContentTone,
        recommendedGoal: ContentGoal,
        recommendedStyle: ContentStyle,
        blueprint: String,
        exampleScriptDirection: String,
        exampleCaptionDirection: String,
        tier: TemplateAccessTier,
        sortOrder: Int
    ) -> TemplateModel {
        TemplateModel(
            seedKey: seedKey,
            name: name,
            description: description,
            category: category,
            exampleHook: exampleHook,
            structureRules: structureRules,
            idealPlatforms: idealPlatforms,
            recommendedTone: recommendedTone,
            recommendedGoal: recommendedGoal,
            recommendedStyle: recommendedStyle,
            blueprint: blueprint,
            exampleScriptDirection: exampleScriptDirection,
            exampleCaptionDirection: exampleCaptionDirection,
            tier: tier,
            isStarterTemplate: true,
            sortOrder: sortOrder
        )
    }
}
