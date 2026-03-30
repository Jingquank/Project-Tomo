import SwiftUI

struct FriendPageView: View {
    @Bindable var friend: Friend
    @Binding var path: [Friend]

    @Environment(\.modelContext) private var modelContext
    @State private var selectedStory: Story?
    @State private var magicalDetector = MagicalContentDetector()

    private var pinnedStories: [Story] {
        friend.stories.filter(\.isPinned).sorted { $0.createdAt < $1.createdAt }
    }

    private var unpinnedStories: [Story] {
        friend.stories.filter { !$0.isPinned }.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: TomoTheme.gridGutter) {
                    Spacer().frame(height: 12)
                    pinnedSection
                    unpinnedSection
                    Spacer().frame(height: TomoTheme.scrollBottomInset)
                }
                .padding(.horizontal, TomoTheme.gridGutter)
            }
            .scrollIndicators(.hidden)

            ScrollFadeOverlay(extendToSafeArea: true)

            StoryInputBar(
                friendName: friend.name,
                detector: magicalDetector,
                onSubmit: { text, imageData, entities in
                    addStory(text: text, imageData: imageData, entities: entities)
                }
            )
        }
        .tomoBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: FriendSettingsView(friend: friend, path: $path)) {
                    HStack(spacing: 12) {
                        Text(friend.name)
                            .font(TomoTheme.emphasisFont)
                            .foregroundStyle(TomoTheme.warmCharcoal)

                        AvatarView(friend: friend, size: TomoTheme.avatarSizeSmall)
                    }
                }
            }
        }
        .overlay(alignment: .top) {
            if magicalDetector.showError {
                errorToast
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            withAnimation { magicalDetector.dismissError() }
                        }
                    }
            }
        }
        .animation(.spring(duration: 0.35), value: magicalDetector.showError)
        .sheet(item: $selectedStory) { story in
            StoryDetailView(story: story)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var pinnedSection: some View {
        WaterfallLayout(columns: 2, spacing: TomoTheme.gridGutter) {
            ForEach(pinnedStories) { story in
                StoryCardView(
                    story: story,
                    isPinned: true,
                    onTap: { selectedStory = story },
                    onTogglePin: { togglePin(story) },
                    onSetAsProfilePic: { setAsProfilePic(story) },
                    onSetAsName: { setAsName(story) }
                )
            }
        }
    }

    private var unpinnedSection: some View {
        WaterfallLayout(columns: 2, spacing: TomoTheme.gridGutter) {
            ForEach(unpinnedStories) { story in
                StoryCardView(
                    story: story,
                    isPinned: false,
                    onTap: { selectedStory = story },
                    onTogglePin: { togglePin(story) },
                    onSetAsProfilePic: { setAsProfilePic(story) },
                    onSetAsName: { setAsName(story) }
                )
            }
        }
    }

    private func togglePin(_ story: Story) {
        guard !story.isDefaultStory else { return }
        withAnimation(.spring(duration: 0.35)) {
            story.isPinned.toggle()
        }
    }

    private var errorToast: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red.opacity(0.8))
            Text("Could not analyze story")
                .font(TomoTheme.bodyFont)
                .foregroundStyle(TomoTheme.primaryText)
            Spacer()
            Button {
                magicalDetector.retry()
            } label: {
                Text("Retry")
                    .font(TomoTheme.smallActionFont)
                    .foregroundStyle(TomoTheme.tomoTitle)
            }
            Button {
                withAnimation { magicalDetector.dismissError() }
            } label: {
                Image(systemName: "xmark")
                    .font(TomoTheme.captionFont)
                    .foregroundStyle(TomoTheme.secondaryText)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(.regular.tint(.red.opacity(0.15)), in: .capsule)
        .padding(.horizontal, 16)
        .padding(.top, 60)
    }

    private func setAsProfilePic(_ story: Story) {
        if let existing = friend.thumbnailStory, existing.id != story.id {
            existing.isThumbnailStory = false
        }
        story.isThumbnailStory = true
        story.isPinned = true
        friend.thumbnailData = story.imageData
    }

    private func setAsName(_ story: Story) {
        if let existing = friend.nameStory, existing.id != story.id {
            existing.isNameStory = false
        }
        story.isNameStory = true
        story.isPinned = true
        friend.name = story.textContent
    }

    private func addStory(text: String, imageData: Data?, entities: [MagicalEntity]) {
        let story = Story(textContent: text, imageData: imageData)
        story.friend = friend
        if !entities.isEmpty {
            story.magicalEntities = entities
        }
        modelContext.insert(story)
    }
}
