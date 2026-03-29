import SwiftUI

struct MagicalTextView: View {
    let story: Story

    var body: some View {
        Text(attributedText)
            .font(TomoTheme.bodyFont)
            .foregroundStyle(TomoTheme.secondaryText)
    }

    private var attributedText: AttributedString {
        let text = story.textContent
        var attributed = AttributedString(text)

        let entities = story.magicalEntities
            .filter(\.isConfirmed)
            .sorted { $0.startIndex < $1.startIndex }

        for entity in entities {
            guard entity.startIndex >= 0,
                  entity.endIndex <= text.count,
                  entity.startIndex < entity.endIndex else { continue }

            let startUTF8 = text.utf8.index(text.utf8.startIndex, offsetBy: entity.startIndex, limitedBy: text.utf8.endIndex) ?? text.utf8.startIndex
            let endUTF8 = text.utf8.index(text.utf8.startIndex, offsetBy: entity.endIndex, limitedBy: text.utf8.endIndex) ?? text.utf8.endIndex

            let startString = String.Index(startUTF8, within: text) ?? text.startIndex
            let endString = String.Index(endUTF8, within: text) ?? text.endIndex

            guard let attrStart = AttributedString.Index(startString, within: attributed),
                  let attrEnd = AttributedString.Index(endString, within: attributed) else {
                continue
            }

            attributed[attrStart..<attrEnd].underlineStyle = .single
            attributed[attrStart..<attrEnd].underlineColor = UIColor(TomoTheme.magicalUnderline)
        }

        return attributed
    }
}
