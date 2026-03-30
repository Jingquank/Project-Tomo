import SwiftUI
import SwiftData
import PhotosUI

struct CreateStorySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var friends: [Friend]

    @State private var selectedFriend: Friend?
    @State private var isNewFriend = false
    @State private var newFriendName = ""
    @State private var newFriendPhoto: PhotosPickerItem?
    @State private var newFriendPhotoData: Data?

    @State private var storyText = ""
    @State private var storyPhoto: PhotosPickerItem?
    @State private var storyImageData: Data?
    @State private var showCamera = false
    @State private var showPhotoPicker = false

    @State private var detector = MagicalContentDetector()
    @State private var hasProceeded = false

    private var canProceed: Bool {
        let hasContent = !storyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || storyImageData != nil
        let hasFriend = selectedFriend != nil || (!newFriendName.trimmingCharacters(in: .whitespaces).isEmpty && isNewFriend)
        return hasContent && hasFriend && !detector.isDetecting
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    friendPickerSection
                    storyContentSection

                    if detector.showConfirmation {
                        MagicalConfirmationView(detector: detector) { confirmedEntities in
                            submitStory(entities: confirmedEntities)
                        }
                    }
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
            .tomoBackground()
            .navigationTitle("New Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        detector.reset()
                        dismiss()
                    }
                    .foregroundStyle(TomoTheme.secondaryText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if !hasProceeded || !detector.showConfirmation {
                        Button("Proceed") {
                            proceed()
                        }
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(TomoTheme.tomoTitle)
                        .disabled(!canProceed)
                    }
                }
            }
            .overlay {
                if detector.isDetecting {
                    ProgressView("Analyzing story...")
                        .padding(24)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .onAppear {
            if friends.isEmpty {
                isNewFriend = true
            }
        }
    }

    private var friendPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Who is this about?")
                .font(TomoTheme.emphasisFont)
                .foregroundStyle(TomoTheme.primaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(friends) { friend in
                        friendChip(friend: friend)
                    }
                    newFriendChip
                }
            }

            if isNewFriend {
                VStack(spacing: 12) {
                    TextField("Friend's name", text: $newFriendName)
                        .font(TomoTheme.nameFont)
                        .foregroundStyle(TomoTheme.primaryText)
                        .textInputAutocapitalization(.words)
                        .padding(12)
                        .background(TomoTheme.cardFill)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    PhotosPicker(selection: $newFriendPhoto, matching: .images) {
                        HStack(spacing: 8) {
                            if let data = newFriendPhotoData, let image = UIImage(data: data) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "camera")
                                    .font(TomoTheme.smallActionFont)
                                    .foregroundStyle(TomoTheme.secondaryText)
                                    .frame(width: 36, height: 36)
                                    .background(TomoTheme.cardFill)
                                    .clipShape(Circle())
                            }
                            Text(newFriendPhotoData != nil ? "Change photo" : "Add photo (optional)")
                                .font(TomoTheme.bodyFont)
                                .foregroundStyle(TomoTheme.secondaryText)
                        }
                    }
                    .onChange(of: newFriendPhoto) { _, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                newFriendPhotoData = data
                            }
                        }
                    }
                }
            }
        }
    }

    private func friendChip(friend: Friend) -> some View {
        let isSelected = selectedFriend?.id == friend.id && !isNewFriend
        return Button {
            selectedFriend = friend
            isNewFriend = false
        } label: {
            VStack(spacing: 6) {
                AvatarView(friend: friend, size: 44)
                    .overlay {
                        if isSelected {
                            Circle()
                                .stroke(TomoTheme.tomoTitle, lineWidth: 2)
                        }
                    }
                Text(friend.name.split(separator: " ").first.map(String.init) ?? friend.name)
                    .font(TomoTheme.captionFont)
                    .foregroundStyle(isSelected ? TomoTheme.tomoTitle : TomoTheme.secondaryText)
                    .lineLimit(1)
            }
            .frame(width: 60)
        }
    }

    private var newFriendChip: some View {
        Button {
            isNewFriend = true
            selectedFriend = nil
        } label: {
            VStack(spacing: 6) {
                Circle()
                    .fill(TomoTheme.cardFill)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(TomoTheme.secondaryText)

                    }
                    .overlay {
                        if isNewFriend {
                            Circle()
                                .stroke(TomoTheme.tomoTitle, lineWidth: 2)
                        }
                    }
                Text("New")
                    .font(TomoTheme.captionFont)
                    .foregroundStyle(isNewFriend ? TomoTheme.tomoTitle : TomoTheme.secondaryText)
            }
            .frame(width: 60)
        }
    }

    private var storyContentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What's the story?")
                .font(TomoTheme.emphasisFont)
                .foregroundStyle(TomoTheme.primaryText)

            TextEditor(text: $storyText)
                .font(TomoTheme.bodyFont)
                .foregroundStyle(TomoTheme.primaryText)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 100)
                .padding(12)
                .background(TomoTheme.cardFill)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(hasProceeded)

            HStack(spacing: 12) {
                if let data = storyImageData, let image = UIImage(data: data) {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        Button {
                            withAnimation { storyImageData = nil }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18, design: .rounded))
                                .foregroundStyle(.white)
                                .shadow(radius: 2)
                        }
                        .offset(x: 4, y: -4)
                        .disabled(hasProceeded)
                    }
                }

                if !hasProceeded {
                    Menu {
                        Button {
                            showCamera = true
                        } label: {
                            Label("Camera", systemImage: "camera")
                        }

                        Button {
                            showPhotoPicker = true
                        } label: {
                            Label("Photo Library", systemImage: "photo.on.rectangle")
                        }

                        Button {
                            if let image = UIPasteboard.general.image {
                                storyImageData = image.jpegData(compressionQuality: 0.8)
                            }
                        } label: {
                            Label("Paste", systemImage: "doc.on.clipboard")
                        }
                    } label: {
                        Label("Add Image", systemImage: "photo.badge.plus")
                            .font(TomoTheme.bodyFont)
                            .foregroundStyle(TomoTheme.secondaryText)
                    }
                }
            }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $storyPhoto, matching: .images)
        .onChange(of: storyPhoto) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    storyImageData = data
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(imageData: $storyImageData)
                .ignoresSafeArea()
        }
    }

    private func proceed() {
        let trimmed = storyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canProceed else { return }
        hasProceeded = true

        guard !trimmed.isEmpty else {
            submitStory(entities: [])
            return
        }

        let friendName = isNewFriend ? newFriendName.trimmingCharacters(in: .whitespaces) : (selectedFriend?.name ?? "")
        Task {
            await detector.detect(text: trimmed, friendName: friendName)
            if !detector.showConfirmation {
                submitStory(entities: [])
            }
        }
    }

    private func submitStory(entities: [MagicalEntity]) {
        let friend: Friend
        if isNewFriend {
            let trimmedName = newFriendName.trimmingCharacters(in: .whitespaces)
            guard !trimmedName.isEmpty else { return }
            friend = Friend(name: trimmedName, thumbnailData: newFriendPhotoData)
            modelContext.insert(friend)
        } else {
            guard let selected = selectedFriend else { return }
            friend = selected
        }

        let trimmedText = storyText.trimmingCharacters(in: .whitespacesAndNewlines)
        let story = Story(textContent: trimmedText, imageData: storyImageData)
        story.friend = friend
        if !entities.isEmpty {
            story.magicalEntities = entities
        }
        modelContext.insert(story)

        detector.reset()
        dismiss()
    }
}
