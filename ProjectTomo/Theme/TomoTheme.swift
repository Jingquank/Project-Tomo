import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum TomoTheme {
    // MARK: - Colors (adaptive via Asset Catalog)

    static let pageBackground = Color("PageBackground")
    static let cardFill = Color("CardFill")
    static let cardShadowColor = Color("CardShadowColor")
    static let primaryText = Color("PrimaryText")
    static let secondaryText = Color("SecondaryText")
    static let tomoTitle = Color("TomoTitle")
    static let accent = Color("Accent")
    static let magicalUnderline = Color("MagicalUnderline")
    static let warmCharcoal = Color("WarmCharcoal")

    // MARK: - Typography

    static let titleFont = Font.custom("Lora-Bold", size: 28)

    static func rounded(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .rounded).weight(weight)
    }

    static let nameFont = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let bodyFont = Font.system(size: 15, weight: .regular, design: .rounded)
    static let captionFont = Font.system(size: 11, weight: .regular, design: .rounded)
    static let countdownFont = Font.system(size: 28, weight: .regular, design: .rounded)
    static let emphasisFont = Font.system(size: 15, weight: .semibold, design: .rounded)

    // MARK: - Dimensions

    static let cardCornerRadius: CGFloat = 24
    static let cardPadding: CGFloat = 20
    static let gridGutter: CGFloat = 12
    static let avatarSizeLarge: CGFloat = 60
    static let avatarSizeSmall: CGFloat = 36
    static let bottomBarCornerRadius: CGFloat = 24
    static let imageCornerRadius: CGFloat = 8

    // MARK: - Shadows

    static func cardShadow() -> some ViewModifier {
        CardShadowModifier()
    }
}

struct CardShadowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(
                color: TomoTheme.cardShadowColor,
                radius: 12,
                x: 0,
                y: 2
            )
    }
}

extension View {
    func tomoCardShadow() -> some View {
        modifier(CardShadowModifier())
    }

    func tomoCardStyle() -> some View {
        self
            .background(TomoTheme.cardFill)
            .clipShape(RoundedRectangle(cornerRadius: TomoTheme.cardCornerRadius, style: .continuous))
            .tomoCardShadow()
    }
}
