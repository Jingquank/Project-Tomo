import SwiftUI
import PhotosUI

struct StoryInputBar: View {
    let friendName: String
    var detector: MagicalContentDetector
    var onSubmit: (String, Data?, [MagicalEntity]) -> Void

    @State private var text = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var pendingText: String?
    @State private var pendingImageData: Data?

    var body: some View {
        VStack(spacing: 0) {
            if detector.showConfirmation {
                confirmationArea
            }

            if !detector.showConfirmation {
                if let data = imageData, let image = UIImage(data: data) {
                    HStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        Spacer()

                        Button {
                            withAnimation { imageData = nil }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(TomoTheme.secondaryText)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }

                HStack(spacing: 12) {
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
                            pasteFromClipboard()
                        } label: {
                            Label("Paste", systemImage: "doc.on.clipboard")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(TomoTheme.iconFont.bold())
                            .foregroundStyle(TomoTheme.warmCharcoal)
                            .frame(width: 36, height: 36)
                    }
                    .disabled(detector.isDetecting)

                    TextField("Add some story about \(friendName)", text: $text, axis: .vertical)
                        .font(TomoTheme.bodyFont)
                        .foregroundStyle(TomoTheme.primaryText)
                        .lineLimit(1...5)
                        .onSubmit { beginSubmit() }
                        .disabled(detector.isDetecting)

                    if !text.isEmpty || imageData != nil {
                        Button(action: beginSubmit) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(TomoTheme.largeIconFont)
                                .foregroundStyle(TomoTheme.tomoTitle)
                        }
                        .disabled(detector.isDetecting)
                    }

                    if detector.isDetecting {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }
        }
        .glassEffect(.regular, in: .rect(cornerRadius: TomoTheme.bottomBarCornerRadius))
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto, matching: .images)
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    imageData = data
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(imageData: $imageData)
                .ignoresSafeArea()
        }
    }

    private var confirmationArea: some View {
        VStack(spacing: 0) {
            MagicalConfirmationView(detector: detector) { confirmedEntities in
                if let pt = pendingText {
                    onSubmit(pt, pendingImageData, confirmedEntities)
                }
                pendingText = nil
                pendingImageData = nil
                detector.reset()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    private func beginSubmit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || imageData != nil else { return }

        pendingText = trimmed
        pendingImageData = imageData
        text = ""
        imageData = nil
        selectedPhoto = nil

        guard !trimmed.isEmpty else {
            onSubmit(trimmed, pendingImageData, [])
            pendingText = nil
            pendingImageData = nil
            return
        }

        Task {
            await detector.detect(text: trimmed, friendName: friendName)
            if !detector.showConfirmation {
                await MainActor.run {
                    onSubmit(pendingText ?? trimmed, pendingImageData, [])
                    pendingText = nil
                    pendingImageData = nil
                }
            }
        }
    }

    private func pasteFromClipboard() {
        if let image = UIPasteboard.general.image {
            imageData = image.jpegData(compressionQuality: 0.8)
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.modalPresentationStyle = .fullScreen
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.imageData = image.jpegData(compressionQuality: 0.8)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
