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

    static let headingFont = Font.system(size: 28, weight: .semibold, design: .rounded)
    static let subheadingFont = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let nameFont = Font.custom("Lora-Bold", size: 17)
    static let bodyFont = Font.system(size: 15, weight: .regular, design: .rounded)
    static let emphasisFont = Font.system(size: 15, weight: .semibold, design: .rounded)
    static let smallActionFont = Font.system(size: 14, weight: .semibold, design: .rounded)
    static let pillFont = Font.system(size: 13, weight: .medium, design: .rounded)
    static let captionFont = Font.system(size: 12, weight: .regular, design: .rounded)
    static let countdownFont = Font.system(size: 28, weight: .regular, design: .rounded)

    static let iconFont = Font.system(size: 16, weight: .semibold, design: .rounded)
    static let largeIconFont = Font.system(size: 28, weight: .regular, design: .rounded)

    // MARK: - Dimensions

    static let cardCornerRadius: CGFloat = 28
    static let cardPadding: CGFloat = 20
    static let gridGutter: CGFloat = 12
    static let avatarSizeLarge: CGFloat = 60
    static let avatarSizeSmall: CGFloat = 36
    static let bottomBarCornerRadius: CGFloat = 24
    static let imageCornerRadius: CGFloat = 8

    // MARK: - Spacing

    static let contentPadding: CGFloat = 24
    static let sectionSpacing: CGFloat = 20
    static let scrollBottomInset: CGFloat = 100
    static let titleTopPadding: CGFloat = 16
    static let titleBottomPadding: CGFloat = 24

    // MARK: - Shadows

    static func cardShadow() -> some ViewModifier {
        CardShadowModifier()
    }
}

// MARK: - Card Modifiers

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

// MARK: - Gradient Background

struct TomoBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme

    private var points: [SIMD2<Float>] {
        [
            SIMD2(0.0, 0.0), SIMD2(0.5, 0.0), SIMD2(1.0, 0.0),
            SIMD2(0.0, 0.4), SIMD2(0.5, 0.35), SIMD2(1.0, 0.4),
            SIMD2(0.0, 1.0), SIMD2(0.5, 1.0), SIMD2(1.0, 1.0),
        ]
    }

    private var lightColors: [Color] {
        let base = Color(red: 0.965, green: 0.953, blue: 0.933)
        let warm = Color(red: 0.976, green: 0.961, blue: 0.945)
        let deeper = Color(red: 0.945, green: 0.929, blue: 0.902)
        let glow = Color(red: 0.984, green: 0.973, blue: 0.957)
        return [
            base,  glow,  warm,
            warm,  glow,  base,
            deeper, base, deeper,
        ]
    }

    private var darkColors: [Color] {
        let base = Color(red: 0.118, green: 0.102, blue: 0.094)
        let lighter = Color(red: 0.145, green: 0.125, blue: 0.114)
        let deeper = Color(red: 0.082, green: 0.071, blue: 0.063)
        let glow = Color(red: 0.155, green: 0.133, blue: 0.122)
        return [
            lighter, glow,    lighter,
            base,    lighter, base,
            deeper,  base,    deeper,
        ]
    }

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: points,
            colors: colorScheme == .dark ? darkColors : lightColors
        )
        .ignoresSafeArea()
    }
}

// MARK: - View Extensions

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

    func tomoBackground() -> some View {
        self.background { TomoBackgroundView() }
    }
}
