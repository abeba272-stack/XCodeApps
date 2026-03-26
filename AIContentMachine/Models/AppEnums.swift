import Foundation
import SwiftUI

enum ContentPlatform: String, CaseIterable, Codable, Identifiable {
    case tiktok = "TikTok"
    case instagramReels = "Instagram Reels"
    case youtubeShorts = "YouTube Shorts"
    case x = "X / Twitter"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .tiktok: "sparkles.tv"
        case .instagramReels: "camera.filters"
        case .youtubeShorts: "play.rectangle.fill"
        case .x: "text.bubble.fill"
        }
    }

    var accentStartHex: String {
        switch self {
        case .tiktok: "#53F3C3"
        case .instagramReels: "#FF7A59"
        case .youtubeShorts: "#FF4D57"
        case .x: "#9CB2FF"
        }
    }

    var accentEndHex: String {
        switch self {
        case .tiktok: "#3A57FF"
        case .instagramReels: "#FF3D9A"
        case .youtubeShorts: "#FF8A00"
        case .x: "#63E5FF"
        }
    }

    var pacingDescription: String {
        switch self {
        case .tiktok: "fast, emotionally sharp, and scroll-stopping"
        case .instagramReels: "clean, aesthetic, and save-worthy"
        case .youtubeShorts: "dense, authoritative, and tightly framed"
        case .x: "punchy, opinionated, and text-forward"
        }
    }
}

enum ContentTone: String, CaseIterable, Codable, Identifiable {
    case serious = "Serious"
    case dark = "Dark"
    case funny = "Funny"
    case confident = "Confident"
    case luxury = "Luxury"
    case educational = "Educational"
    case emotional = "Emotional"
    case direct = "Direct"

    var id: String { rawValue }

    var descriptorEn: String {
        switch self {
        case .serious: "measured and credible"
        case .dark: "edgy with controlled intensity"
        case .funny: "smart and light without losing clarity"
        case .confident: "assertive and decisive"
        case .luxury: "refined, elevated, and premium"
        case .educational: "clear, useful, and structured"
        case .emotional: "human, vulnerable, and vivid"
        case .direct: "brief, sharp, and no-nonsense"
        }
    }

    var descriptorDe: String {
        switch self {
        case .serious: "sachlich und glaubwuerdig"
        case .dark: "kantig mit kontrollierter Intensitaet"
        case .funny: "clever und leicht, aber klar"
        case .confident: "selbstbewusst und entschlossen"
        case .luxury: "edel, hochwertig und stilvoll"
        case .educational: "klar, hilfreich und strukturiert"
        case .emotional: "menschlich, nahbar und intensiv"
        case .direct: "kurz, scharf und direkt"
        }
    }
}

enum ContentGoal: String, CaseIterable, Codable, Identifiable {
    case views = "Views"
    case engagement = "Engagement"
    case followers = "Followers"
    case leads = "Leads"
    case authority = "Authority"
    case sales = "Sales"

    var id: String { rawValue }
}

enum ContentLanguage: String, CaseIterable, Codable, Identifiable {
    case german = "German"
    case english = "English"

    var id: String { rawValue }

    var localeIdentifier: String {
        switch self {
        case .german: "de_DE"
        case .english: "en_US"
        }
    }

    var shortCode: String {
        switch self {
        case .german: "DE"
        case .english: "EN"
        }
    }
}

enum ContentStyle: String, CaseIterable, Codable, Identifiable {
    case hotTake = "Hot Take"
    case storytime = "Storytime"
    case educational = "Educational"
    case top3List = "Top 3 List"
    case mythVsFact = "Myth vs Fact"
    case comparison = "Comparison"
    case motivational = "Motivational"
    case controversialOpinion = "Controversial Opinion"
    case tutorial = "Tutorial"
    case pov = "POV"
    case questionBasedHook = "Question-Based Hook"
    case beforeAfter = "Before / After"
    case mistakesPeopleMake = "Mistakes People Make"
    case deepExplanation = "Deep Explanation"
    case shortPunchyHook = "Short Punchy Hook"
    case viralFormatClone = "Viral Format Clone"

    var id: String { rawValue }
}

enum GenerationMode: String, CaseIterable, Codable, Identifiable {
    case singleIdea = "Single Idea"
    case batchIdeas = "Batch of Ideas"
    case fullPackage = "Full Content Package"

    var id: String { rawValue }
}

enum ProjectStatus: String, CaseIterable, Codable, Identifiable {
    case idea = "Idea"
    case draft = "Draft"
    case ready = "Ready"
    case posted = "Posted"
    case archived = "Archived"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .idea: Color(hex: "#6EA8FF")
        case .draft: Color(hex: "#FFB357")
        case .ready: Color(hex: "#70E1A1")
        case .posted: Color(hex: "#8AE2FF")
        case .archived: Color(hex: "#8C91A7")
        }
    }
}

enum AppThemePreference: String, CaseIterable, Codable, Identifiable {
    case system = "System"
    case dark = "Dark"
    case light = "Light"

    var id: String { rawValue }
}

enum AIProviderMode: String, CaseIterable, Codable, Identifiable {
    case mock = "Offline Mock"
    case customEndpoint = "Custom Endpoint"

    var id: String { rawValue }
}

enum ContentSection: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case hook = "Hook"
    case script = "Script"
    case caption = "Caption"
    case hashtags = "Hashtags"
    case cta = "CTA"
    case shotList = "Shot List"
    case notes = "Notes"

    var id: String { rawValue }
}

enum ContentSortOption: String, CaseIterable, Identifiable {
    case newest = "Newest"
    case oldest = "Oldest"
    case favorites = "Favorites"

    var id: String { rawValue }
}
