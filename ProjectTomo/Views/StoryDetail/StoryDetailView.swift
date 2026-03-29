import SwiftUI
import PhotosUI

struct StoryDetailView: View {
    @Bindable var story: Story
    var onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isEditing = false
    @State private var editText: String = ""
    @State private var showDeleteConfirmation = false
    @State private var selectedPhoto: PhotosPickerItem?

    @State private var showToolbar = false
    @State private var showContent = false

    @State private var overscrollOffset: CGFloat = 0
    @State private var isDismissing = false

    private var dragProgress: CGFloat {
        min(max(overscrollOffset, 0) / 300, 1.0)
    }

    private var dismissScale: CGFloat {
        1.0 - (dragProgress * 0.15)
    }

    private var dismissRadius: CGFloat {
        TomoTheme.cardCornerRadius + (dragProgress * 20)
    }

    var body: some View {
        ZStack {
            TomoTheme.pageBackground.ignoresSafeArea()
                .onTapGesture {
                    if isEditing { saveEdit() }
                }

            VStack(spacing: 0) {
                toolbar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .opacity(showToolbar ? 1 : 0)
                    .offset(y: showToolbar ? 0 : 10)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if story.isThumbnailStory {
                            thumbnailDetail
                        } else if story.isNameStory {
                            nameDetail
                        } else {
                            contentDetail
                        }
                    }
                    .padding(24)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
                .onScrollGeometryChange(for: CGFloat.self) { geo in
                    geo.contentOffset.y
                } action: { _, newOffset in
                    guard !isDismissing else { return }
                    if newOffset < 0 {
                        overscrollOffset = -newOffset
                    } else {
                        overscrollOffset = 0
                    }
                }
                .onScrollPhaseChange { oldPhase, newPhase in
                    guard !isDismissing else { return }
                    if oldPhase == .tracking && newPhase != .tracking {
                        if overscrollOffset > 120 {
                            performDismiss()
                        }
                    }
                }
                .overlay { ScrollFadeOverlay() }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 15)
            }
        }
        .scaleEffect(dismissScale)
        .clipShape(RoundedRectangle(cornerRadius: dismissRadius, style: .continuous))
        .opacity(1 - (dragProgress * 0.3))
        .onAppear {
            if reduceMotion {
                showToolbar = true
                showContent = true
            } else {
                withAnimation(.spring(duration: 0.45, bounce: 0.2).delay(0.1)) {
                    showToolbar = true
                }
                withAnimation(.spring(duration: 0.5, bounce: 0.2).delay(0.2)) {
                    showContent = true
                }
            }
        }
        .alert("Delete this story?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(story)
                performDismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func performDismiss() {
        isDismissing = true
        showToolbar = false
        showContent = false
        onDismiss()
    }

    private var toolbar: some View {
        GlassEffectContainer {
            HStack {
                Button(action: performDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(TomoTheme.warmCharcoal)
                        .frame(width: 36, height: 36)
                }
                .glassEffect(.regular.interactive(), in: .circle)

                Spacer()

                if !story.isDefaultStory {
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
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(TomoTheme.warmCharcoal)
                                .frame(width: 36, height: 36)
                        }
                        .glassEffect(.regular.interactive(), in: .circle)

                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(TomoTheme.warmCharcoal)
                                .frame(width: 36, height: 36)
                        }
                        .glassEffect(.regular.interactive(), in: .circle)
                    }
                }
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
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(TomoTheme.primaryText)
            } else {
                Text(story.textContent)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(TomoTheme.primaryText)
            }
        }
    }

    private var contentDetail: some View {
        VStack(alignment: .leading, spacing: 20) {
            if isEditing {
                TextEditor(text: $editText)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundStyle(TomoTheme.primaryText)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 200)
            } else {
                MagicalTextView(story: story)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
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
