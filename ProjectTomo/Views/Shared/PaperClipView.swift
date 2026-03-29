import SwiftUI

struct PaperClipView: View {
    var size: CGFloat = 28

    var body: some View {
        Image(systemName: "paperclip")
            .font(.system(size: size, weight: .medium))
            .foregroundStyle(TomoTheme.accent)
            .rotationEffect(.degrees(15))
    }
}
