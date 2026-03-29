import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedFriend: Friend?
    @State private var selectedStory: Story?
    @State private var showFriendPage = false
    @State private var showStoryDetail = false
    @State private var hasSeededData = false
    @State private var storyCardFrames: [UUID: CGRect] = [:]
    @State private var rootSize: CGSize = .zero

    @Namespace private var heroNamespace

    private var storyCardAnchor: UnitPoint {
        guard let story = selectedStory,
              let frame = storyCardFrames[story.id],
              rootSize.width > 0, rootSize.height > 0 else { return .center }
        return UnitPoint(
            x: frame.midX / rootSize.width,
            y: frame.midY / rootSize.height
        )
    }

    private var bloomOpenSpring: Animation {
        reduceMotion ? .easeInOut(duration: 0.25) : .spring(duration: 0.5, bounce: 0.25)
    }

    private var bloomCloseSpring: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.4, bounce: 0.15)
    }

    var body: some View {
        GeometryReader { rootGeo in
            ZStack {
                TomoTheme.pageBackground
                    .ignoresSafeArea()

                HomeView(
                    namespace: heroNamespace,
                    onFriendTapped: { friend in
                        selectedFriend = friend
                        withAnimation(.spring(duration: 0.45, bounce: 0.2)) {
                            showFriendPage = true
                        }
                    }
                )
                .opacity(showFriendPage ? 0 : 1)

                if showFriendPage, let friend = selectedFriend {
                    FriendPageView(
                        friend: friend,
                        onBack: {
                            withAnimation(.spring(duration: 0.45, bounce: 0.2)) {
                                showFriendPage = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                selectedFriend = nil
                            }
                        },
                        onStoryTapped: { story in
                            selectedStory = story
                            withAnimation(bloomOpenSpring) {
                                showStoryDetail = true
                            }
                        }
                    )
                    .blur(radius: showStoryDetail ? 6 : 0)
                    .scaleEffect(showStoryDetail ? 0.96 : 1.0)
                    .overlay {
                        Color.black.opacity(showStoryDetail ? 0.15 : 0)
                            .ignoresSafeArea()
                            .allowsHitTesting(false)
                    }
                    .animation(
                        reduceMotion
                            ? .easeInOut(duration: 0.2)
                            : .spring(duration: 0.5, bounce: 0.2),
                        value: showStoryDetail
                    )
                    .transition(.opacity)
                    .onPreferenceChange(StoryCardFrameKey.self) { frames in
                        storyCardFrames = frames
                    }
                }

                if showStoryDetail, let story = selectedStory {
                    StoryDetailView(
                        story: story,
                        onDismiss: {
                            withAnimation(bloomCloseSpring) {
                                showStoryDetail = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                                selectedStory = nil
                            }
                        }
                    )
                    .transition(
                        reduceMotion
                            ? .opacity
                            : .scale(scale: 0.85, anchor: storyCardAnchor)
                                .combined(with: .opacity)
                    )
                }
            }
            .onAppear {
                rootSize = rootGeo.size
                if !hasSeededData {
                    DummyDataSeeder.seedIfNeeded(context: modelContext)
                    hasSeededData = true
                }
            }
            .onChange(of: rootGeo.size) { _, newSize in
                rootSize = newSize
            }
        }
    }
}
