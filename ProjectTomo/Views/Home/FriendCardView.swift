import SwiftUI

struct FriendCardView: View {
    let friend: Friend

    @State private var currentSubtitleIndex = 0
    @State private var displayedText = ""
    @State private var hasAppeared = false
    @State private var transitionId = 0
    @State private var cycleTask: Task<Void, Never>?

    private var subtitles: [String] {
        friend.allSubtitles
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AvatarView(friend: friend, size: TomoTheme.avatarSizeLarge)

            Text(friend.name)
                .font(TomoTheme.nameFont)
                .foregroundStyle(TomoTheme.primaryText)
                .lineLimit(1)

            if !subtitles.isEmpty {
                Text(displayedText)
                    .font(TomoTheme.bodyFont)
                    .foregroundStyle(TomoTheme.secondaryText)
                    .lineLimit(3)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .id(transitionId)
                    .transition(.push(from: .bottom))
                    .frame(height: 54)
                    .clipped()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(TomoTheme.cardPadding)
        .tomoCardStyle()
        .onAppear {
            guard !subtitles.isEmpty else { return }
            if !hasAppeared {
                hasAppeared = true
                let stagger = Double(abs(friend.id.hashValue) % 5)
                cycleTask = Task {
                    try? await Task.sleep(for: .seconds(stagger))
                    guard !Task.isCancelled else { return }
                    advanceSubtitle()
                    scheduleAdvance()
                }
            } else {
                scheduleAdvance()
            }
        }
        .onDisappear {
            cycleTask?.cancel()
        }
    }

    private func scheduleAdvance() {
        cycleTask?.cancel()
        var holdDuration: TimeInterval
        if subtitles.count <= 1 {
            holdDuration = 8
        } else {
            holdDuration = min(10, max(4, Double(displayedText.count) / 8.0))
        }
        holdDuration += Double.random(in: 0...1.5)

        cycleTask = Task {
            try? await Task.sleep(for: .seconds(holdDuration))
            guard !Task.isCancelled else { return }
            advanceSubtitle()
            scheduleAdvance()
        }
    }

    private func advanceSubtitle() {
        guard !subtitles.isEmpty else { return }
        currentSubtitleIndex = (currentSubtitleIndex + 1) % subtitles.count
        withAnimation(.easeInOut(duration: 0.35)) {
            transitionId += 1
            displayedText = subtitles[currentSubtitleIndex]
        }
    }
}
