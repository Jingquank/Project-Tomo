import SwiftUI
import PhotosUI

struct StoryDetailView: View {
    @Bindable var story: Story

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var editText: String = ""
    @State private var showDeleteConfirmation = false
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: TomoTheme.sectionSpacing) {
                    if story.isThumbnailStory {
                        thumbnailDetail
                    } else if story.isNameStory {
                        nameDetail
                    } else {
                        contentDetail
                    }
                }
                .padding(TomoTheme.contentPadding)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .tomoBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        if isEditing { saveEdit() }
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(TomoTheme.emphasisFont)
                            .foregroundStyle(TomoTheme.warmCharcoal)
                    }
                }

                if !story.isDefaultStory {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 12) {
                            Button {
                                if isEditing {
                                    saveEdit()
                                } else {
                                    editText = story.textContent
                                    isEditing = true
                                }
                            } label: {
                                Image(systemName: isEditing ? "checkmark" : "pencil")
                                    .font(TomoTheme.emphasisFont)
                                    .foregroundStyle(TomoTheme.warmCharcoal)
                            }

                            Button {
                                showDeleteConfirmation = true
                            } label: {
                                Image(systemName: "trash")
                                    .font(TomoTheme.emphasisFont)
                                    .foregroundStyle(TomoTheme.warmCharcoal)
                            }
                        }
                    }
                }
            }
            .alert("Delete this story?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    modelContext.delete(story)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var thumbnailDetail: some View {
        VStack(spacing: 20) {
            if let data = story.imageData ?? story.friend?.thumbnailData,
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: TomoTheme.imageCornerRadius))
            } else if let friend = story.friend {
                AvatarView(friend: friend, size: 200)
            }

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Text("Change photo")
                    .font(TomoTheme.bodyFont)
                    .foregroundStyle(TomoTheme.tomoTitle)
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        story.imageData = data
                        story.friend?.thumbnailData = data
                        story.lastEditedAt = Date()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var nameDetail: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isEditing {
                TextField("Name", text: $editText)
                    .font(TomoTheme.headingFont)
                    .foregroundStyle(TomoTheme.primaryText)
            } else {
                Text(story.textContent)
                    .font(TomoTheme.headingFont)
                    .foregroundStyle(TomoTheme.primaryText)
            }
        }
    }

    private var contentDetail: some View {
        VStack(alignment: .leading, spacing: TomoTheme.sectionSpacing) {
            if isEditing {
                TextEditor(text: $editText)
                    .font(TomoTheme.nameFont)
                    .foregroundStyle(TomoTheme.primaryText)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 200)
            } else {
                MagicalTextView(story: story)
                    .font(TomoTheme.nameFont)
            }

            if let data = story.imageData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: TomoTheme.imageCornerRadius))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Created \(story.displayDate)")
                    .font(TomoTheme.captionFont)
                    .foregroundStyle(TomoTheme.secondaryText)

                if story.lastEditedAt != story.createdAt {
                    Text("Edited \(formattedDate(story.lastEditedAt))")
                        .font(TomoTheme.captionFont)
                        .foregroundStyle(TomoTheme.secondaryText)
                }
            }

            if !story.magicalEntities.filter(\.isConfirmed).isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(story.magicalEntities.filter(\.isConfirmed)) { entity in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(TomoTheme.magicalUnderline)
                                .frame(width: 6, height: 6)
                            Text("\(entity.type.displayName): \(entity.value)")
                                .font(TomoTheme.captionFont)
                                .foregroundStyle(TomoTheme.secondaryText)
                        }
                    }
                }
            }
        }
    }

    private func saveEdit() {
        let trimmed = editText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        story.textContent = trimmed
        story.lastEditedAt = Date()
        if story.isNameStory {
            story.friend?.name = trimmed
        }
        isEditing = false
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
}
