import SwiftUI

struct ScrollFadeOverlay: View {
    var extendToSafeArea: Bool = false

    var body: some View {
        ZStack {
            VStack {
                LinearGradient(
                    colors: [TomoTheme.pageBackground, TomoTheme.pageBackground.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
                Spacer()
            }
            VStack {
                Spacer()
                LinearGradient(
                    colors: [TomoTheme.pageBackground.opacity(0), TomoTheme.pageBackground],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea(extendToSafeArea ? .all : [])
    }
}
