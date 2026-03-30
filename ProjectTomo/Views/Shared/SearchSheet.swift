import SwiftUI
import SwiftData

struct SearchSheet: View {
    var onFriendSelected: (Friend) -> Void

    @Environment(\.dismiss) private var dismiss
    @Query private var friends: [Friend]
    @State private var searchText = ""

    private var matchingFriends: [Friend] {
        guard !searchText.isEmpty else { return [] }
        let query = searchText.lowercased()
        return friends.filter { $0.name.lowercased().contains(query) }
    }

    private var matchingStories: [(Friend, Story)] {
        guard !searchText.isEmpty else { return [] }
        let query = searchText.lowercased()
        var results: [(Friend, Story)] = []
        for friend in friends {
            for story in friend.stories where story.textContent.lowercased().contains(query) && !story.isThumbnailStory {
                results.append((friend, story))
            }
        }
        return results
    }

    var body: some View {
        NavigationStack {
            List {
                if !matchingFriends.isEmpty {
                    Section("Friends") {
                        ForEach(matchingFriends) { friend in
                            Button {
                                onFriendSelected(friend)
                            } label: {
                                HStack(spacing: 12) {
                                    AvatarView(friend: friend, size: 36)
                                    Text(friend.name)
                                        .font(TomoTheme.nameFont)
                                        .foregroundStyle(TomoTheme.primaryText)
                                }
                            }
                        }
                    }
                }

                if !matchingStories.isEmpty {
                    Section("Stories") {
                        ForEach(matchingStories, id: \.1.id) { friend, story in
                            Button {
                                onFriendSelected(friend)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(friend.name)
                                        .font(TomoTheme.emphasisFont)
                                        .foregroundStyle(TomoTheme.primaryText)
                                    Text(story.textContent)
                                        .font(TomoTheme.bodyFont)
                                        .foregroundStyle(TomoTheme.secondaryText)
                                        .lineLimit(2)
                                }
                            }
                        }
                    }
                }

                if searchText.isEmpty {
                    ContentUnavailableView("Search", systemImage: "magnifyingglass", description: Text("Search friends and stories"))
                } else if matchingFriends.isEmpty && matchingStories.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .tomoBackground()
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Friends and stories")
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(TomoTheme.secondaryText)
                }
            }
        }
    }
}
