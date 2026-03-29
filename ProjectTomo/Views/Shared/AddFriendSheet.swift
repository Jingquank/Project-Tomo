import SwiftUI
import PhotosUI

struct AddFriendSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var thumbnailData: Data?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    if let data = thumbnailData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(TomoTheme.pageBackground)
                            .frame(width: 80, height: 80)
                            .overlay {
                                Image(systemName: "camera")
                                    .font(.system(size: 24, weight: .medium, design: .rounded))
                                    .foregroundStyle(TomoTheme.secondaryText)
                            }
                    }
                }

                TextField("Their name", text: $name)
                    .font(TomoTheme.nameFont)
                    .foregroundStyle(TomoTheme.primaryText)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.words)

                Spacer()
            }
            .padding(.top, 32)
            .padding(.horizontal, 24)
            .background(TomoTheme.pageBackground)
            .navigationTitle("Remember someone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(TomoTheme.secondaryText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addFriend() }
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(TomoTheme.tomoTitle)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    thumbnailData = data
                }
            }
        }
    }

    private func addFriend() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let friend = Friend(name: trimmedName, thumbnailData: thumbnailData)
        modelContext.insert(friend)

        let thumbStory = Story(textContent: "", isPinned: true, isThumbnailStory: true)
        thumbStory.imageData = thumbnailData
        thumbStory.friend = friend
        modelContext.insert(thumbStory)

        let nameStory = Story(textContent: trimmedName, isPinned: true, isNameStory: true)
        nameStory.friend = friend
        modelContext.insert(nameStory)

        dismiss()
    }
}
