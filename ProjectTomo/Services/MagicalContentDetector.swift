import Foundation
import SwiftUI

@Observable
final class MagicalContentDetector {
    var detectedEntities: [MagicalEntity] = []
    var isDetecting = false
    var showConfirmation = false
    var currentStory: Story?
    var lastError: String?
    var showError = false

    private var lastText: String?
    private var lastFriendName: String?

    func detect(text: String, friendName: String, for story: Story) async {
        await MainActor.run {
            isDetecting = true
            currentStory = story
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
                if !entities.isEmpty {
                    detectedEntities = entities
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
    func retry() {
        guard let text = lastText, let friendName = lastFriendName, let story = currentStory else { return }
        showError = false
        lastError = nil
        Task {
            await detect(text: text, friendName: friendName, for: story)
        }
    }

    @MainActor
    func dismissError() {
        showError = false
    }

    @MainActor
    func confirmEntities(_ confirmed: [MagicalEntity]) {
        guard let story = currentStory else { return }
        story.magicalEntities = confirmed.filter(\.isConfirmed)
        reset()
    }

    @MainActor
    func reset() {
        detectedEntities = []
        showConfirmation = false
        currentStory = nil
        isDetecting = false
        lastError = nil
        showError = false
    }
}
