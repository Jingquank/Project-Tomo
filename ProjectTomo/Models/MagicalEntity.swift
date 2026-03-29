import Foundation

struct MagicalEntity: Codable, Identifiable, Equatable {
    var id: UUID
    var type: MagicalType
    var subtype: String?
    var value: String
    var label: String?
    var startIndex: Int
    var endIndex: Int
    var isConfirmed: Bool

    init(
        type: MagicalType,
        subtype: String? = nil,
        value: String,
        label: String? = nil,
        startIndex: Int,
        endIndex: Int,
        isConfirmed: Bool = false
    ) {
        self.id = UUID()
        self.type = type
        self.subtype = subtype
        self.value = value
        self.label = label
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.isConfirmed = isConfirmed
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

    var subtypeOptions: [String] {
        switch self {
        case .birthday: return ["Birthday"]
        case .phoneNumber: return ["Phone"]
        case .location: return ["Current city", "Hometown", "Visiting"]
        case .importantDate: return ["Due date", "Important date"]
        case .anniversary: return ["Anniversary"]
        case .mbti: return ["MBTI"]
        }
    }
}
