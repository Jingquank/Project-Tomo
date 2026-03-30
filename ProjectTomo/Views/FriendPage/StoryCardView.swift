import SwiftUI

struct StoryCardView: View {
    let story: Story
    var isPinned: Bool
    var showRotation: Bool = false
    var onTap: () -> Void
    var onTogglePin: (() -> Void)?
    var onSetAsProfilePic: (() -> Void)?
    var onSetAsName: (() -> Void)?

    private var rotation: Double {
        guard showRotation else { return 0 }
        let seed = story.id.hashValue
        return Double(seed % 5) - 2.0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if story.isThumbnailStory {
                thumbnailContent
            } else if story.isNameStory {
                nameContent
            } else if story.hasMagicalContent && hasCountdown {
                countdownContent
            } else {
                regularContent
            }
        }
        .padding(TomoTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: TomoTheme.cardCornerRadius, style: .continuous))
        .tomoCardShadow()
        .overlay(alignment: .topTrailing) {
            if isPinned {
                PaperClipView(size: 22)
                    .offset(x: -8, y: -4)
            }
        }
        .rotationEffect(.degrees(rotation))
        .onTapGesture { onTap() }
        .contextMenu {
            if !story.isDefaultStory {
                Button {
                    onTogglePin?()
                } label: {
                    Label(isPinned ? "Unpin" : "Pin", systemImage: isPinned ? "pin.slash" : "pin")
                }
            }

            if story.imageData != nil && !story.isThumbnailStory {
                Button {
                    onSetAsProfilePic?()
                } label: {
                    Label("Set as Profile Picture", systemImage: "person.crop.circle")
                }
            }

            if canBeSetAsName && !story.isNameStory {
                Button {
                    onSetAsName?()
                } label: {
                    Label("Set as Name", systemImage: "textformat")
                }
            }
        }
    }

    @ViewBuilder
    private var cardBackground: some View {
        if story.hasMagicalContent && hasCountdown {
            RoundedRectangle(cornerRadius: TomoTheme.cardCornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: TomoTheme.cardCornerRadius, style: .continuous)
                        .fill(TomoTheme.pageBackground.opacity(0.7))
                }
        } else {
            TomoTheme.cardFill
        }
    }

    private var thumbnailContent: some View {
        Group {
            if let data = story.imageData ?? story.friend?.thumbnailData,
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: TomoTheme.imageCornerRadius))
            } else if let friend = story.friend {
                AvatarView(friend: friend, size: 120)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var nameContent: some View {
        Text(story.textContent)
            .font(TomoTheme.subheadingFont)
            .foregroundStyle(TomoTheme.primaryText)
    }

    private var regularContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            MagicalTextView(story: story)

            if let data = story.imageData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 150)
                    .clipShape(RoundedRectangle(cornerRadius: TomoTheme.imageCornerRadius))
            }

            Text(story.displayDate)
                .font(TomoTheme.captionFont)
                .foregroundStyle(TomoTheme.secondaryText)
        }
    }

    private var canBeSetAsName: Bool {
        let text = story.textContent
        guard !text.isEmpty, text.count <= 50 else { return false }
        guard !text.contains("\n") else { return false }
        let sentenceEnders: Set<Character> = [".", "!", "?"]
        return !text.contains(where: { sentenceEnders.contains($0) })
    }

    private var hasCountdown: Bool {
        story.magicalEntities.contains { entity in
            entity.isConfirmed &&
            (entity.type == .importantDate || entity.type == .anniversary || entity.type == .birthday) &&
            entity.daysUntilNextOccurrence != nil
        }
    }

    private var countdownContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let entity = story.magicalEntities.first(where: { $0.daysUntilNextOccurrence != nil }),
               let days = entity.daysUntilNextOccurrence {
                Text("In \(days) Days")
                    .font(TomoTheme.countdownFont)
                    .foregroundStyle(TomoTheme.warmCharcoal)
                Text(entity.label ?? entity.value)
                    .font(TomoTheme.emphasisFont)
                    .foregroundStyle(TomoTheme.warmCharcoal)
            }
        }
    }
}
