import Foundation

enum ContentScoreCalculator {
    static func score(for content: GeneratedContent, request: GenerationRequest) -> Int {
        var score = 44
        let hookLength = content.hook.count
        let titleLength = content.title.count

        if (45...120).contains(hookLength) { score += 14 }
        if (18...70).contains(titleLength) { score += 8 }
        if content.cta.count > 12 { score += 10 }
        if !content.hashtags.isEmpty { score += 8 }
        if content.script.split(separator: "\n").count >= 4 { score += 8 }
        if !content.shotList.isEmpty { score += 8 }
        if request.platform == .x, content.caption.count <= 240 { score += 6 }
        if request.platform == .youtubeShorts, content.script.count >= 220 { score += 6 }
        if request.platform == .instagramReels, content.caption.count <= 220 { score += 6 }
        if request.platform == .tiktok, hookLength <= 90 { score += 6 }
        if request.goal == .sales, content.cta.localizedCaseInsensitiveContains("link") { score += 6 }
        if request.goal == .authority, content.performanceRationale.localizedCaseInsensitiveContains("credibility") { score += 4 }

        return min(max(score, 0), 100)
    }

    static func score(for project: ContentProject) -> Int {
        var score = 38
        if project.hook.count > 40 { score += 15 }
        if project.caption.count > 20 { score += 8 }
        if project.hashtags.count >= 3 { score += 10 }
        if project.cta.count > 10 { score += 10 }
        if project.shotList.count >= 4 { score += 8 }
        if !project.performanceRationale.isEmpty { score += 6 }
        if project.platform == .x, project.caption.count <= 280 { score += 5 }
        if project.platform == .instagramReels, project.caption.count <= 230 { score += 5 }
        return min(max(score, 0), 100)
    }
}
