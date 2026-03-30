import SwiftUI

struct MagicalConfirmationView: View {
    @Bindable var detector: MagicalContentDetector
    var onConfirm: ([MagicalEntity]) -> Void

    @State private var isTypingCustom = false
    @State private var customText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()

            if let text = detector.originalText {
                quoteBlock(text: text)
            }

            if detector.isShowingSummary {
                summaryContent
            } else if let entity = detector.currentEntity {
                entityQuestionContent(entity: entity)
                    .id(detector.currentEntityIndex)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .animation(.spring(duration: 0.35), value: detector.currentEntityIndex)
        .animation(.spring(duration: 0.35), value: detector.isShowingSummary)
    }

    // MARK: - Quote Block

    @ViewBuilder
    private func quoteBlock(text: String) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(TomoTheme.tomoTitle)
                .frame(width: 3)

            Text(text)
                .font(TomoTheme.bodyFont)
                .foregroundStyle(TomoTheme.secondaryText)
                .padding(.leading, 12)
                .padding(.vertical, 4)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Entity Question (State A)

    @ViewBuilder
    private func entityQuestionContent(entity: MagicalEntity) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(entity.message ?? "I noticed something")
                    .font(TomoTheme.emphasisFont)
                    .foregroundStyle(TomoTheme.primaryText)

                Spacer()

                if detector.detectedEntities.count > 1 {
                    Text("\(detector.currentEntityIndex + 1) of \(detector.detectedEntities.count)")
                        .font(TomoTheme.captionFont)
                        .foregroundStyle(TomoTheme.secondaryText)
                }
            }

            Text("\"\(entity.value)\"")
                .font(TomoTheme.bodyFont)
                .foregroundStyle(TomoTheme.primaryText)
                .underline(color: TomoTheme.magicalUnderline)

            if isTypingCustom {
                customInputArea
            } else {
                optionPills(for: entity)
            }
        }
    }

    @ViewBuilder
    private func optionPills(for entity: MagicalEntity) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(entity.suggestedOptions) { option in
                    Button {
                        withAnimation(.spring(duration: 0.35)) {
                            detector.confirmCurrentAndAdvance(option: option)
                        }
                        resetCustomInput()
                    } label: {
                        Text(option.label)
                            .font(TomoTheme.pillFont)
                            .foregroundStyle(TomoTheme.warmCharcoal)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(TomoTheme.pageBackground)
                            )
                    }
                }

                Button {
                    withAnimation(.spring(duration: 0.35)) {
                        detector.skipCurrent()
                    }
                    resetCustomInput()
                } label: {
                    Text("Not special")
                        .font(TomoTheme.pillFont)
                        .foregroundStyle(TomoTheme.secondaryText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(TomoTheme.pageBackground)
                        )
                }

                Button {
                    withAnimation(.spring(duration: 0.25)) {
                        isTypingCustom = true
                    }
                } label: {
                    Text("Let me type...")
                        .font(TomoTheme.pillFont)
                        .foregroundStyle(TomoTheme.secondaryText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                                .foregroundStyle(TomoTheme.secondaryText)
                        )
                }
            }
        }
    }

    private var customInputArea: some View {
        HStack(spacing: 8) {
            TextField("e.g. Place she studied", text: $customText)
                .font(TomoTheme.bodyFont)
                .foregroundStyle(TomoTheme.primaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(TomoTheme.pageBackground)
                .clipShape(Capsule())

            Button {
                let trimmed = customText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                withAnimation(.spring(duration: 0.35)) {
                    detector.confirmCurrentWithCustom(label: trimmed)
                }
                resetCustomInput()
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24, weight: .regular, design: .rounded))
                    .foregroundStyle(TomoTheme.tomoTitle)
            }
            .disabled(customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Button {
                withAnimation(.spring(duration: 0.25)) {
                    resetCustomInput()
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(TomoTheme.subheadingFont)
                    .foregroundStyle(TomoTheme.secondaryText)
            }
        }
    }

    // MARK: - Summary (State B)

    private var summaryContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Here's what I found")
                .font(TomoTheme.emphasisFont)
                .foregroundStyle(TomoTheme.primaryText)

            ForEach(Array(detector.detectedEntities.enumerated()), id: \.element.id) { index, entity in
                Button {
                    withAnimation(.spring(duration: 0.35)) {
                        detector.goBack(to: index)
                    }
                    resetCustomInput()
                } label: {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(entity.isConfirmed ? TomoTheme.magicalUnderline : TomoTheme.secondaryText.opacity(0.3))
                            .frame(width: 6, height: 6)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\"\(entity.value)\"")
                                .font(TomoTheme.bodyFont)
                                .foregroundStyle(TomoTheme.primaryText)

                            Text(entity.isConfirmed ? (entity.subtype ?? entity.type.displayName) : "Skipped")
                                .font(TomoTheme.captionFont)
                                .foregroundStyle(TomoTheme.secondaryText)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(TomoTheme.secondaryText)
                    }
                    .padding(.vertical, 6)
                }
            }

            HStack {
                Spacer()
                Button("Done") {
                    onConfirm(detector.confirmedEntities())
                }
                .font(TomoTheme.emphasisFont)
                .foregroundStyle(TomoTheme.tomoTitle)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(TomoTheme.pageBackground)
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Helpers

    private func resetCustomInput() {
        isTypingCustom = false
        customText = ""
    }
}
