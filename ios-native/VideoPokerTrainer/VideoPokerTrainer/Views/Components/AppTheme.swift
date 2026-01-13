import SwiftUI

/// Centralized theme for consistent styling across the app
struct AppTheme {

    // MARK: - Brand Colors

    struct Colors {
        // Primary brand colors
        static let primary = Color(hex: "667eea")      // Indigo (Quiz)
        static let secondary = Color(hex: "9b59b6")   // Purple (Play)
        static let accent = Color(hex: "3498db")      // Blue (Analyzer)

        // Semantic colors
        static let success = Color(hex: "27ae60")     // Green
        static let warning = Color(hex: "e67e22")     // Orange
        static let danger = Color(hex: "e74c3c")      // Red
        static let gold = Color(hex: "f1c40f")        // Gold/Yellow

        // Feature colors
        static let simulation = Color(hex: "00a896")  // Teal (Simulation)
    }

    // MARK: - Gradients

    struct Gradients {
        // Primary indigo gradient (Quiz mode)
        static let primary = LinearGradient(
            colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // Purple gradient (Play mode)
        static let purple = LinearGradient(
            colors: [Color(hex: "9b59b6"), Color(hex: "8e44ad")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // Blue gradient (Analyzer)
        static let blue = LinearGradient(
            colors: [Color(hex: "3498db"), Color(hex: "2980b9")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // Red gradient (Weak Spots)
        static let red = LinearGradient(
            colors: [Color(hex: "e74c3c"), Color(hex: "c0392b")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // Green gradient (Progress)
        static let green = LinearGradient(
            colors: [Color(hex: "27ae60"), Color(hex: "1e8449")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // Gold gradient (Winners)
        static let gold = LinearGradient(
            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
            startPoint: .leading,
            endPoint: .trailing
        )

        // Teal gradient (Simulation)
        static let teal = LinearGradient(
            colors: [Color(hex: "00a896"), Color(hex: "028090")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Spacing & Sizing

    struct Layout {
        static let cornerRadiusSmall: CGFloat = 8
        static let cornerRadiusMedium: CGFloat = 12
        static let cornerRadiusLarge: CGFloat = 16
        static let cornerRadiusXL: CGFloat = 24

        static let iconSizeSmall: CGFloat = 36
        static let iconSizeMedium: CGFloat = 50
        static let iconSizeLarge: CGFloat = 60
    }

    // MARK: - Shadows

    struct Shadows {
        static func light(color: Color = .black) -> some View {
            Color.clear.shadow(color: color.opacity(0.08), radius: 4, y: 2)
        }

        static func medium(color: Color = .black) -> some View {
            Color.clear.shadow(color: color.opacity(0.12), radius: 8, y: 4)
        }

        static func colored(_ color: Color) -> some View {
            Color.clear.shadow(color: color.opacity(0.2), radius: 8, y: 4)
        }
    }
}

// MARK: - Gradient for specific mode colors

extension AppTheme.Gradients {
    static func forColor(_ color: Color) -> LinearGradient {
        // Match colors to their gradients
        switch color {
        case Color(hex: "667eea"):
            return primary
        case Color(hex: "9b59b6"):
            return purple
        case Color(hex: "3498db"):
            return blue
        case Color(hex: "e74c3c"):
            return red
        case Color(hex: "27ae60"):
            return green
        case Color(hex: "00a896"):
            return teal
        default:
            // Create a gradient from the color
            return LinearGradient(
                colors: [color, color.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - View Modifiers

/// Elevated card style with shadow
struct ElevatedCardStyle: ViewModifier {
    let color: Color
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(.systemBackground))
                    .shadow(color: color.opacity(0.15), radius: 8, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color.opacity(0.15), lineWidth: 1)
            )
    }
}

extension View {
    func elevatedCard(color: Color = .black, cornerRadius: CGFloat = AppTheme.Layout.cornerRadiusLarge) -> some View {
        modifier(ElevatedCardStyle(color: color, cornerRadius: cornerRadius))
    }
}
