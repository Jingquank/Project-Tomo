import SwiftUI

struct BottomBarView: View {
    var onSearch: () -> Void
    var onAdd: () -> Void
    var onSort: () -> Void

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: 0) {
                barButton(icon: "magnifyingglass", action: onSearch)
                Spacer()
                barButton(icon: "plus", action: onAdd)
                Spacer()
                barButton(icon: "arrow.up.arrow.down", action: onSort)
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 18)
            .glassEffect(.regular.interactive(), in: .capsule)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }

    private func barButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(TomoTheme.warmCharcoal)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
    }
}
