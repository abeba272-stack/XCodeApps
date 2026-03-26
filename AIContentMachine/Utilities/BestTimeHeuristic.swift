import Foundation

enum BestTimeHeuristic {
    static func suggestion(for platform: ContentPlatform, goal: ContentGoal, language: ContentLanguage) -> String {
        let localeNote = language == .german ? "local audience time" : "your audience's local time"

        switch (platform, goal) {
        case (.tiktok, .views):
            return "7:30 PM to 9:00 PM (\(localeNote)) for fast-scroll discovery."
        case (.tiktok, _):
            return "12:15 PM or 8:00 PM (\(localeNote)) when short-form attention is high."
        case (.instagramReels, .engagement):
            return "6:30 PM to 8:30 PM (\(localeNote)) when save/share behavior spikes."
        case (.instagramReels, _):
            return "11:45 AM or 7:00 PM (\(localeNote)) for strong reach and saves."
        case (.youtubeShorts, .authority):
            return "8:00 AM or 5:30 PM (\(localeNote)) when informational viewing is steady."
        case (.youtubeShorts, _):
            return "9:00 AM to 11:00 AM (\(localeNote)) for quick authority-building hits."
        case (.x, .engagement):
            return "8:30 AM or 1:00 PM (\(localeNote)) when conversations restart."
        case (.x, _):
            return "7:45 AM or 6:15 PM (\(localeNote)) for opinion-led posting."
        }
    }
}
