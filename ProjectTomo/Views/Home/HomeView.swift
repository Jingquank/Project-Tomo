import SwiftUI
import SwiftData

struct HomeView: View {
    @Binding var path: [Friend]

    @Environment(\.modelContext) private var modelContext
    @Query private var friends: [Friend]

    @State private var showAddSheet = false
    @State private var showSearchSheet = false
    @State private var showSortOptions = false
    @State private var showSettings = false
    @State private var sortMode: SortMode = .name

    enum SortMode: String, CaseIterable {
        case name = "Name"
        case recentlyAdded = "Recently Added"
    }

    private var sortedFriends: [Friend] {
        switch sortMode {
        case .name:
            return friends.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        case .recentlyAdded:
            return friends.sorted { $0.createdAt > $1.createdAt }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    Text("Tomo")
                        .font(TomoTheme.titleFont)
                        .foregroundStyle(TomoTheme.tomoTitle)
                        .padding(.top, TomoTheme.titleTopPadding)
                        .padding(.bottom, TomoTheme.titleBottomPadding)

                    if friends.isEmpty {
                        emptyState
                    } else {
                        WaterfallLayout(columns: 2, spacing: TomoTheme.gridGutter) {
                            ForEach(sortedFriends) { friend in
                                FriendCardView(friend: friend)
                                    .onTapGesture {
                                        path.append(friend)
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            deleteFriend(friend)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, TomoTheme.gridGutter)
                    }

                    Spacer().frame(height: TomoTheme.scrollBottomInset + 20)
                }
            }
            .scrollIndicators(.hidden)

            ScrollFadeOverlay(extendToSafeArea: true)

            settingsButton

            BottomBarView(
                onSearch: { showSearchSheet = true },
                onAdd: { showAddSheet = true },
                onSort: { showSortOptions = true }
            )
        }
        .tomoBackground()
        .navigationTitle("Tomo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showAddSheet) {
            CreateStorySheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSearchSheet) {
            SearchSheet(
                onFriendSelected: { friend in
                    showSearchSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        path.append(friend)
                    }
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .confirmationDialog("Sort by", isPresented: $showSortOptions) {
            ForEach(SortMode.allCases, id: \.self) { mode in
                Button(mode.rawValue) {
                    withAnimation(.spring(duration: 0.3)) {
                        sortMode = mode
                    }
                }
            }
        }
    }

    private var settingsButton: some View {
        VStack {
            HStack {
                Spacer()
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                        .font(TomoTheme.iconFont)
                        .foregroundStyle(TomoTheme.warmCharcoal)
                        .frame(width: 40, height: 40)
                }
                .glassEffect(.regular.interactive(), in: .circle)
            }
            .padding(.trailing, 16)
            .padding(.top, 8)
            Spacer()
        }
    }

    private var emptyState: some View {
        VStack(spacing: TomoTheme.titleTopPadding) {
            Spacer().frame(height: TomoTheme.scrollBottomInset + 20)
            Image(systemName: "heart.text.clipboard")
                .font(.system(size: 48, weight: .light, design: .rounded))
                .foregroundStyle(TomoTheme.secondaryText.opacity(0.5))
            Text("Your memory box is empty.\nTap + to remember someone.")
                .font(TomoTheme.bodyFont)
                .foregroundStyle(TomoTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
    }

    private func deleteFriend(_ friend: Friend) {
        withAnimation {
            modelContext.delete(friend)
        }
    }
}
