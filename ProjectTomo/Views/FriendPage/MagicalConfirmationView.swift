import SwiftUI

struct MagicalConfirmationView: View {
    @Bindable var detector: MagicalContentDetector

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()

            Text("I noticed something")
                .font(TomoTheme.emphasisFont)
                .foregroundStyle(TomoTheme.primaryText)

            ForEach(detector.detectedEntities.indices, id: \.self) { index in
                entityRow(index: index)
            }

            HStack {
                Spacer()
                Button("Done") {
                    detector.confirmEntities(detector.detectedEntities)
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(TomoTheme.tomoTitle)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(TomoTheme.pageBackground)
                .clipShape(Capsule())
            }
        }
    }

    @ViewBuilder
    private func entityRow(index: Int) -> some View {
        let entity = detector.detectedEntities[index]
        VStack(alignment: .leading, spacing: 8) {
            Text("\"\(entity.value)\"")
                .font(TomoTheme.bodyFont)
                .foregroundStyle(TomoTheme.primaryText)
                .underline(color: TomoTheme.magicalUnderline)

            categoryPicker(for: entity, index: index)
        }
    }

    @ViewBuilder
    private func categoryPicker(for entity: MagicalEntity, index: Int) -> some View {
        let options = pillOptions(for: entity.type)
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    let isSelected = entity.isConfirmed && (entity.subtype == option || entity.type.displayName == option)
                    Button {
                        toggleSelection(index: index, option: option)
                    } label: {
                        Text(option)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(isSelected ? .white : TomoTheme.warmCharcoal)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(isSelected ? TomoTheme.tomoTitle : TomoTheme.pageBackground)
                            )
                    }
                }

                Button {
                    markNotSpecial(index: index)
                } label: {
                    Text("Not special")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(!detector.detectedEntities[index].isConfirmed ? .white : TomoTheme.secondaryText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(!detector.detectedEntities[index].isConfirmed ? TomoTheme.secondaryText : TomoTheme.pageBackground)
                        )
                }
            }
        }
    }

    private func pillOptions(for type: MagicalType) -> [String] {
        switch type {
        case .birthday: return ["Birthday", "Anniversary", "Due date", "Important date"]
        case .location: return ["Current city", "Hometown", "Visiting"]
        case .mbti: return ["MBTI"]
        case .phoneNumber: return ["Phone"]
        case .importantDate: return ["Birthday", "Anniversary", "Due date", "Important date"]
        case .anniversary: return ["Anniversary", "Birthday", "Important date"]
        }
    }

    private func toggleSelection(index: Int, option: String) {
        detector.detectedEntities[index].isConfirmed = true
        detector.detectedEntities[index].subtype = option
    }

    private func markNotSpecial(index: Int) {
        detector.detectedEntities[index].isConfirmed = false
        detector.detectedEntities[index].subtype = nil
    }
}
