import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var path: [Friend] = []
    @State private var hasSeededData = false

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(path: $path)
                .navigationDestination(for: Friend.self) { friend in
                    FriendPageView(friend: friend, path: $path)
                }
        }
        .onAppear {
            if !hasSeededData {
                DummyDataSeeder.seedIfNeeded(context: modelContext)
                hasSeededData = true
            }
        }
    }
}
