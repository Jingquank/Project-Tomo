import Foundation
import SwiftData

@Model
final class Story {
    var id: UUID
    var textContent: String
    var imageData: Data?
    var isPinned: Bool
    var isNameStory: Bool
    var isThumbnailStory: Bool
    var createdAt: Date
    var lastEditedAt: Date
    var magicalEntitiesData: Data?

    var friend: Friend?

    init(
        textContent: String = "",
        imageData: Data? = nil,
        isPinned: Bool = false,
        isNameStory: Bool = false,
        isThumbnailStory: Bool = false
    ) {
        self.id = UUID()
        self.textContent = textContent
        self.imageData = imageData
        self.isPinned = isPinned
        self.isNameStory = isNameStory
        self.isThumbnailStory = isThumbnailStory
        self.createdAt = Date()
        self.lastEditedAt = Date()
    }

    var magicalEntities: [MagicalEntity] {
        get {
            guard let data = magicalEntitiesData else { return [] }
            return (try? JSONDecoder().decode([MagicalEntity].self, from: data)) ?? []
        }
        set {
            magicalEntitiesData = try? JSONEncoder().encode(newValue)
        }
    }

    var isDefaultStory: Bool {
        isNameStory || isThumbnailStory
    }

    var hasMagicalContent: Bool {
        !magicalEntities.isEmpty
    }

    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: createdAt)
    }
}
