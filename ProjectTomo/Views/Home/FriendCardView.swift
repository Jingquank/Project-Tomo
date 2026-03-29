import SwiftUI

struct FriendCardView: View {
    let friend: Friend
    var namespace: Namespace.ID

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AvatarView(friend: friend, size: TomoTheme.avatarSizeLarge)

            Text(friend.name)
                .font(TomoTheme.nameFont)
                .foregroundStyle(TomoTheme.primaryText)
                .lineLimit(1)

            if !friend.liveSubtitle.isEmpty {
                Text(friend.liveSubtitle)
                    .font(TomoTheme.bodyFont)
                    .foregroundStyle(TomoTheme.secondaryText)
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(TomoTheme.cardPadding)
        .tomoCardStyle()
    }
}
