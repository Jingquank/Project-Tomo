import Foundation

struct SuggestedOption: Codable, Equatable, Identifiable {
    var id: String { key }
    let key: String
    let label: String
}

struct MagicalEntity: Codable, Identifiable, Equatable {
    var id: UUID
    var type: MagicalType
    var subtype: String?
    var subtypeKey: String?
    var value: String
    var label: String?
    var startIndex: Int
    var endIndex: Int
    var isConfirmed: Bool
    var suggestedOptions: [SuggestedOption]
    var message: String?

    init(
        type: MagicalType,
        subtype: String? = nil,
        subtypeKey: String? = nil,
        value: String,
        label: String? = nil,
        startIndex: Int,
        endIndex: Int,
        isConfirmed: Bool = false,
        suggestedOptions: [SuggestedOption] = [],
        message: String? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.subtype = subtype
        self.subtypeKey = subtypeKey
        self.value = value
        self.label = label
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.isConfirmed = isConfirmed
        self.suggestedOptions = suggestedOptions
        self.message = message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(MagicalType.self, forKey: .type)
        subtype = try container.decodeIfPresent(String.self, forKey: .subtype)
        subtypeKey = try container.decodeIfPresent(String.self, forKey: .subtypeKey)
        value = try container.decode(String.self, forKey: .value)
        label = try container.decodeIfPresent(String.self, forKey: .label)
        startIndex = try container.decode(Int.self, forKey: .startIndex)
        endIndex = try container.decode(Int.self, forKey: .endIndex)
        isConfirmed = try container.decode(Bool.self, forKey: .isConfirmed)
        suggestedOptions = try container.decodeIfPresent([SuggestedOption].self, forKey: .suggestedOptions) ?? []
        message = try container.decodeIfPresent(String.self, forKey: .message)
    }

    var daysUntilNextOccurrence: Int? {
        let dateFormats = ["MMM d, yyyy", "MMMM d, yyyy", "yyyy-MM-dd", "MM/dd/yyyy", "d MMM yyyy"]
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        for format in dateFormats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: value) {
                let calendar = Calendar.current
                let now = Date()
                var components = calendar.dateComponents([.month, .day], from: date)
                components.year = calendar.component(.year, from: now)
                if let thisYear = calendar.date(from: components) {
                    if thisYear >= calendar.startOfDay(for: now) {
                        return calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: thisYear).day
                    }
                    components.year = calendar.component(.year, from: now) + 1
                    if let nextYear = calendar.date(from: components) {
                        return calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: nextYear).day
                    }
                }
            }
        }
        return nil
    }
}

enum MagicalType: String, Codable, CaseIterable {
    case birthday
    case phoneNumber
    case location
    case importantDate
    case anniversary
    case mbti

    var displayName: String {
        switch self {
        case .birthday: return "Birthday"
        case .phoneNumber: return "Phone"
        case .location: return "Location"
        case .importantDate: return "Important Date"
        case .anniversary: return "Anniversary"
        case .mbti: return "MBTI"
        }
    }
}
