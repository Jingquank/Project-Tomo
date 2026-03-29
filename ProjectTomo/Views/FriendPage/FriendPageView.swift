import SwiftUI

struct FriendPageView: View {
    @Bindable var friend: Friend
    var onBack: () -> Void
    var onStoryTapped: (Story) -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteConfirmation = false
    @State private var magicalDetector = MagicalContentDetector()

    private var pinnedStories: [Story] {
        friend.stories.filter(\.isPinned).sorted { $0.createdAt < $1.createdAt }
    }

    private var unpinnedStories: [Story] {
        friend.stories.filter { !$0.isPinned }.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TomoTheme.pageBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: TomoTheme.gridGutter) {
                    Spacer().frame(height: 52)
                    pinnedSection
                    unpinnedSection
                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, TomoTheme.gridGutter)
            }
            .scrollIndicators(.hidden)

            ScrollFadeOverlay(extendToSafeArea: true)

            navigationBar
                .padding(.horizontal, 12)
                .frame(maxHeight: .infinity, alignment: .top)

            StoryInputBar(
                friendName: friend.name,
                detector: magicalDetector,
                onSubmit: { text, imageData in
                    addStory(text: text, imageData: imageData)
                }
            )
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
        .alert("Delete \(friend.name)?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(friend)
                onBack()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all their stories. This cannot be undone.")
        }
    }

    private var navigationBar: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                    Text("Home")
                        .font(TomoTheme.bodyFont)
                }
                .foregroundStyle(TomoTheme.warmCharcoal)
            }

            Spacer()

            HStack(spacing: 12) {
                Text(friend.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(TomoTheme.warmCharcoal)

                AvatarView(friend: friend, size: TomoTheme.avatarSizeSmall)
            }

            Menu {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Friend", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(TomoTheme.warmCharcoal)
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.top, 8)
    }

    private var pinnedSection: some View {
        WaterfallLayout(columns: 2, spacing: TomoTheme.gridGutter) {
            ForEach(pinnedStories) { story in
                StoryCardView(
                    story: story,
                    isPinned: true,
                    detector: magicalDetector,
                    onTap: { onStoryTapped(story) },
                    onTogglePin: { togglePin(story) }
                )
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: StoryCardFrameKey.self,
                            value: [story.id: geo.frame(in: .global)]
                        )
                    }
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
                    detector: magicalDetector,
                    onTap: { onStoryTapped(story) },
                    onTogglePin: { togglePin(story) }
                )
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: StoryCardFrameKey.self,
                            value: [story.id: geo.frame(in: .global)]
                        )
                    }
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
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(TomoTheme.tomoTitle)
            }
            Button {
                withAnimation { magicalDetector.dismissError() }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(TomoTheme.secondaryText)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(.regular.tint(.red.opacity(0.15)), in: .capsule)
        .padding(.horizontal, 16)
        .padding(.top, 60)
    }

    private func addStory(text: String, imageData: Data?) {
        let story = Story(textContent: text, imageData: imageData)
        story.friend = friend
        modelContext.insert(story)

        Task {
            await magicalDetector.detect(
                text: text,
                friendName: friend.name,
                for: story
            )
        }
    }
}
