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

    var liveSubtitle: String {
        let magical = stories.flatMap(\.magicalEntities)

        for entity in magical where entity.isConfirmed {
            switch entity.type {
            case .birthday:
                if let days = entity.daysUntilNextOccurrence {
                    if days == 0 { return "\(name.split(separator: " ").first ?? "")'s birthday is today!" }
                    return "\(name.split(separator: " ").first ?? "")'s birthday in \(days) days"
                }
            case .importantDate, .anniversary:
                if let days = entity.daysUntilNextOccurrence {
                    return "\(entity.label ?? entity.value) in \(days) days"
                }
            case .location:
                if entity.subtype == "currentCity" {
                    return "Lives in \(entity.value)"
                }
            default:
                break
            }
        }

        if let latest = unpinnedStories.first {
            let text = latest.textContent
            if text.count > 60 {
                return String(text.prefix(57)) + "..."
            }
            return text
        }

        return ""
    }
}
