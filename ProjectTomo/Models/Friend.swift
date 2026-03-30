import Foundation
import SwiftData

@Model
final class Friend {
    var id: UUID
    var name: String
    var thumbnailData: Data?
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Story.friend)
    var stories: [Story] = []

    init(name: String, thumbnailData: Data? = nil) {
        self.id = UUID()
        self.name = name
        self.thumbnailData = thumbnailData
        self.createdAt = Date()
    }

    var pinnedStories: [Story] {
        stories.filter(\.isPinned).sorted { $0.createdAt < $1.createdAt }
    }

    var unpinnedStories: [Story] {
        stories.filter { !$0.isPinned }.sorted { $0.createdAt > $1.createdAt }
    }

    var nameStory: Story? {
        stories.first(where: \.isNameStory)
    }

    var thumbnailStory: Story? {
        stories.first(where: \.isThumbnailStory)
    }

    var displayInitials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    var allSubtitles: [String] {
        let magical = stories.flatMap(\.magicalEntities)
        let firstName = String(name.split(separator: " ").first ?? "")
        var results: [String] = []

        for entity in magical where entity.isConfirmed {
            switch entity.type {
            case .birthday:
                if let days = entity.daysUntilNextOccurrence {
                    if days == 0 {
                        results.append("\(firstName)'s birthday is today!")
                    } else {
                        results.append("\(firstName)'s birthday in \(days) days")
                    }
                }
            case .importantDate, .anniversary:
                if let days = entity.daysUntilNextOccurrence {
                    results.append("\(entity.label ?? entity.value) in \(days) days")
                }
            case .location:
                switch entity.subtypeKey {
                case "currentCity":
                    results.append("Lives in \(entity.value)")
                case "hometown":
                    results.append("From \(entity.value)")
                case "visiting":
                    results.append("Visiting \(entity.value)")
                case "birthplace":
                    results.append("Born in \(entity.value)")
                default:
                    results.append("Based in \(entity.value)")
                }
            case .mbti:
                results.append("Personality: \(entity.value)")
            case .phoneNumber:
                break
            }
        }

        if let latest = unpinnedStories.first {
            let text = latest.textContent
            if !text.isEmpty {
                results.append(text)
            }
        }

        return results
    }

    var liveSubtitle: String {
        allSubtitles.first ?? ""
    }
}
