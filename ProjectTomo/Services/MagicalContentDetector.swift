import Foundation
import SwiftUI

@Observable
final class MagicalContentDetector {
    var detectedEntities: [MagicalEntity] = []
    var isDetecting = false
    var showConfirmation = false
    var lastError: String?
    var showError = false
    var currentEntityIndex: Int = 0
    var originalText: String?
    var isShowingSummary = false

    private var lastText: String?
    private var lastFriendName: String?

    var currentEntity: MagicalEntity? {
        guard currentEntityIndex >= 0, currentEntityIndex < detectedEntities.count else { return nil }
        return detectedEntities[currentEntityIndex]
    }

    func detect(text: String, friendName: String) async {
        await MainActor.run {
            isDetecting = true
            lastError = nil
            showError = false
        }

        lastText = text
        lastFriendName = friendName

        do {
            let entities = try await AnthropicService.shared.detectMagicalContent(
                in: text,
                friendName: friendName
            )

            await MainActor.run {
                isDetecting = false
                originalText = text
                if !entities.isEmpty {
                    detectedEntities = entities
                    currentEntityIndex = 0
                    isShowingSummary = false
                    showConfirmation = true
                }
            }
        } catch {
            await MainActor.run {
                isDetecting = false
                lastError = error.localizedDescription
                showError = true
            }
        }
    }

    @MainActor
    func confirmCurrentAndAdvance(option: SuggestedOption) {
        guard currentEntityIndex < detectedEntities.count else { return }
        detectedEntities[currentEntityIndex].isConfirmed = true
        detectedEntities[currentEntityIndex].subtype = option.label
        detectedEntities[currentEntityIndex].subtypeKey = option.key
        advance()
    }

    @MainActor
    func confirmCurrentWithCustom(label: String) {
        guard currentEntityIndex < detectedEntities.count else { return }
        detectedEntities[currentEntityIndex].isConfirmed = true
        detectedEntities[currentEntityIndex].subtype = label
        detectedEntities[currentEntityIndex].subtypeKey = "custom"
        advance()
    }

    @MainActor
    func skipCurrent() {
        guard currentEntityIndex < detectedEntities.count else { return }
        detectedEntities[currentEntityIndex].isConfirmed = false
        detectedEntities[currentEntityIndex].subtype = nil
        detectedEntities[currentEntityIndex].subtypeKey = nil
        advance()
    }

    @MainActor
    func goBack(to index: Int) {
        guard index >= 0, index < detectedEntities.count else { return }
        currentEntityIndex = index
        isShowingSummary = false
    }

    @MainActor
    func retry() {
        guard let text = lastText, let friendName = lastFriendName else { return }
        showError = false
        lastError = nil
        Task {
            await detect(text: text, friendName: friendName)
        }
    }

    @MainActor
    func dismissError() {
        showError = false
    }

    @MainActor
    func confirmedEntities() -> [MagicalEntity] {
        detectedEntities.filter(\.isConfirmed)
    }

    @MainActor
    func reset() {
        detectedEntities = []
        showConfirmation = false
        isDetecting = false
        lastError = nil
        showError = false
        currentEntityIndex = 0
        originalText = nil
        isShowingSummary = false
    }

    @MainActor
    private func advance() {
        let nextIndex = currentEntityIndex + 1
        if nextIndex >= detectedEntities.count {
            isShowingSummary = true
        } else {
            currentEntityIndex = nextIndex
        }
    }
}
