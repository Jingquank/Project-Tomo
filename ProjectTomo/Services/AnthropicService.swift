import Foundation
import os

private let logger = Logger(subsystem: "com.tomo.ProjectTomo", category: "AnthropicService")

actor AnthropicService {
    static let shared = AnthropicService()

    private let baseURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let debugLog = DebugLogStore.shared

    struct APIMessage: Codable {
        let role: String
        let content: String
    }

    struct APIRequest: Codable {
        let model: String
        let max_tokens: Int
        let system: String
        let messages: [APIMessage]
    }

    struct APIResponse: Codable {
        let content: [ContentBlock]

        struct ContentBlock: Codable {
            let type: String
            let text: String?
        }
    }

    struct DetectedOption: Codable {
        let key: String
        let label: String
    }

    struct DetectedEntity: Codable {
        let type: String
        let value: String
        let label: String?
        let startIndex: Int
        let endIndex: Int
        let suggestedSubtype: String?
        let message: String?
        let suggestedOptions: [DetectedOption]?
    }

    struct DetectionResult: Codable {
        let entities: [DetectedEntity]
    }

    func detectMagicalContent(in text: String, friendName: String) async throws -> [MagicalEntity] {
        let apiKey = Secrets.anthropicAPIKey
        guard !apiKey.isEmpty, apiKey != "YOUR_API_KEY_HERE" else {
            let msg = "API key not configured"
            logger.warning("\(msg)")
            debugLog.log(msg, level: .warning)
            return []
        }

        let systemPrompt = """
        You analyze text about a person and detect "magical" entities — structured information worth remembering.

        Detectable types:
        - birthday: A birth date (e.g. "born on Apr 6, 1995")
        - phoneNumber: A phone number
        - location: A city, country, or place (e.g. "lives in Guangzhou", "visiting Toronto")
        - importantDate: A significant upcoming date (due date, trip date, etc.)
        - anniversary: A relationship anniversary date
        - mbti: An MBTI personality type (e.g. INFJ, ENTP)

        For each entity found, return:
        1. Its exact text span with character indices (0-based) into the original text.
        2. "suggestedSubtype": a camelCase key for the most likely subtype (e.g. "currentCity", "hometown", "visiting", "dueDate", "importantDate").
        3. "message": a short, natural sentence (max ~10 words) describing what you noticed. Be specific to the context. Examples: "Looks like a birthday!", "I spotted a place", "This seems like an important date".
        4. "suggestedOptions": an array of 2-4 objects, each with "key" (camelCase identifier) and "label" (user-facing display string), ordered by confidence. These represent what this information likely means. Be specific to context.
           For example, for "England" in "She grew up in England": [{"key": "hometown", "label": "Hometown"}, {"key": "birthplace", "label": "Birthplace"}, {"key": "countryOfOrigin", "label": "Country of origin"}]
           For "Apr 6, 1995" in "born on Apr 6, 1995": [{"key": "birthday", "label": "Birthday"}, {"key": "importantDate", "label": "Important date"}]

        Return ONLY valid JSON, no markdown, no explanation:
        {"entities": [{"type": "birthday", "value": "Apr 6, 1995", "label": "birthday", "startIndex": 22, "endIndex": 33, "suggestedSubtype": "birthday", "message": "Looks like a birthday!", "suggestedOptions": [{"key": "birthday", "label": "Birthday"}, {"key": "importantDate", "label": "Important date"}]}]}

        If no entities found, return: {"entities": []}
        """

        let request = APIRequest(
            model: Secrets.anthropicModel,
            max_tokens: 1024,
            system: systemPrompt,
            messages: [
                APIMessage(role: "user", content: "The following is a note about \(friendName):\n\n\(text)")
            ]
        )

        var urlRequest = URLRequest(url: baseURL)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        urlRequest.timeoutInterval = 30

        debugLog.log("Sending request to Anthropic (model: \(Secrets.anthropicModel), text length: \(text.count))")
        logger.info("Sending detection request for friend '\(friendName)', text length: \(text.count)")

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            let msg = "Invalid response type (not HTTP)"
            logger.error("\(msg)")
            debugLog.log(msg, level: .error)
            throw AnthropicError.apiError(statusCode: 0, message: msg)
        }

        let statusCode = httpResponse.statusCode

        guard (200...299).contains(statusCode) else {
            let bodyText = String(data: data, encoding: .utf8) ?? "<unreadable>"
            let serverMessage = parseErrorMessage(from: data) ?? bodyText
            logger.error("API error \(statusCode): \(serverMessage)")
            debugLog.log("HTTP \(statusCode): \(serverMessage)", level: .error)
            throw AnthropicError.apiError(statusCode: statusCode, message: serverMessage)
        }

        let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
        guard let text = apiResponse.content.first?.text else {
            debugLog.log("Response had no text content", level: .warning)
            return []
        }

        let cleanJSON = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        logger.debug("Raw LLM JSON: \(cleanJSON)")
        debugLog.log("Response JSON: \(cleanJSON.prefix(500))")

        guard let jsonData = cleanJSON.data(using: .utf8) else {
            debugLog.log("Could not convert response to UTF-8 data", level: .error)
            throw AnthropicError.decodingError(detail: "Invalid UTF-8 in response")
        }

        let result: DetectionResult
        do {
            result = try JSONDecoder().decode(DetectionResult.self, from: jsonData)
        } catch {
            logger.error("JSON decode failed: \(error.localizedDescription)")
            debugLog.log("Decode error: \(error.localizedDescription)\nJSON: \(cleanJSON.prefix(300))", level: .error)
            throw AnthropicError.decodingError(detail: error.localizedDescription)
        }

        let entities = result.entities.compactMap { detected in
            guard let type = MagicalType(rawValue: detected.type) else { return nil as MagicalEntity? }
            let options = (detected.suggestedOptions ?? []).map {
                SuggestedOption(key: $0.key, label: $0.label)
            }
            return MagicalEntity(
                type: type,
                subtype: detected.suggestedSubtype,
                subtypeKey: detected.suggestedSubtype,
                value: detected.value,
                label: detected.label,
                startIndex: detected.startIndex,
                endIndex: detected.endIndex,
                isConfirmed: false,
                suggestedOptions: options,
                message: detected.message
            )
        }

        debugLog.log("Detected \(entities.count) entities")
        logger.info("Detection complete: \(entities.count) entities found")
        return entities
    }

    private func parseErrorMessage(from data: Data) -> String? {
        struct ErrorResponse: Codable {
            struct ErrorDetail: Codable {
                let message: String
            }
            let error: ErrorDetail
        }
        return try? JSONDecoder().decode(ErrorResponse.self, from: data).error.message
    }
}

enum AnthropicError: Error, LocalizedError {
    case apiError(statusCode: Int, message: String)
    case decodingError(detail: String)

    var errorDescription: String? {
        switch self {
        case .apiError(let code, let message):
            return "API error (\(code)): \(message)"
        case .decodingError(let detail):
            return "Failed to parse response: \(detail)"
        }
    }
}
