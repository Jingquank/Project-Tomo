import SwiftUI
import PhotosUI

struct FriendSettingsView: View {
    @Bindable var friend: Friend
    @Binding var path: [Friend]

    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteConfirmation = false
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    AvatarView(friend: friend, size: 80)
                    Spacer()
                }
                .listRowBackground(Color.clear)

                TextField("Name", text: $friend.name)
                    .font(TomoTheme.nameFont)
                    .foregroundStyle(TomoTheme.primaryText)
                    .multilineTextAlignment(.center)
                    .listRowBackground(TomoTheme.cardFill)
            }

            Section {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("Change Profile Picture", systemImage: "photo")
                }
                .listRowBackground(TomoTheme.cardFill)
            }

            Section {
                HStack {
                    Toggle("Push Notifications", isOn: .constant(false))
                        .tint(TomoTheme.tomoTitle)
                        .disabled(true)
                }
                .listRowBackground(TomoTheme.cardFill)

                Text("Coming soon")
                    .font(TomoTheme.captionFont)
                    .foregroundStyle(TomoTheme.secondaryText)
                    .listRowBackground(TomoTheme.cardFill)
            } header: {
                Text("Notifications")
            }

            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Delete Friend")
                        Spacer()
                    }
                }
                .listRowBackground(TomoTheme.cardFill)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .tomoBackground()
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    friend.thumbnailData = data
                    if let thumbStory = friend.thumbnailStory {
                        thumbStory.imageData = data
                        thumbStory.lastEditedAt = Date()
                    }
                }
            }
        }
        .alert("Delete \(friend.name)?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(friend)
                path = []
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all their stories. This cannot be undone.")
        }
    }
}
