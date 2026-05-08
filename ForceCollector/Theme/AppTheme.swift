import SwiftUI

enum AppTheme {
    static let accent = Color(hex: "#1152D4")
    static let gold = Color(hex: "#F6C453")
    static let background = Color(hex: "#060B17")
    static let surface = Color(hex: "#0E1629")
    static let elevatedSurface = Color(hex: "#16213A")
    static let border = Color.white.opacity(0.08)
    static let text = Color.white
    static let secondaryText = Color(hex: "#A8B3CF")
    static let success = Color(hex: "#52D98C")
    static let warning = Color(hex: "#FFB14A")
    static let danger = Color(hex: "#FF6F7D")

    static func displayFont(size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func panelFill(opacity: Double = 1) -> some ShapeStyle {
        LinearGradient(
            colors: [surface.opacity(opacity), elevatedSurface.opacity(opacity)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 255, 255, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
