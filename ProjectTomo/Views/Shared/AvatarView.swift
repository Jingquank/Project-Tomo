import SwiftUI

struct AvatarView: View {
    let friend: Friend
    var size: CGFloat = TomoTheme.avatarSizeLarge

    private var gradientColors: [Color] {
        let hash = friend.name.hashValue
        let hue1 = Double(abs(hash) % 360) / 360.0
        let hue2 = (hue1 + 0.1).truncatingRemainder(dividingBy: 1.0)
        return [
            Color(hue: hue1, saturation: 0.25, brightness: 0.92),
            Color(hue: hue2, saturation: 0.3, brightness: 0.85),
        ]
    }

    var body: some View {
        Group {
            if let data = friend.thumbnailData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay {
                    Text(friend.displayInitials)
                        .font(.system(size: size * 0.36, weight: .semibold, design: .rounded))
                        .foregroundStyle(TomoTheme.primaryText.opacity(0.6))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}
