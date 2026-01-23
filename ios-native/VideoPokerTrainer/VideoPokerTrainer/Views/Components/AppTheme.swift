import SwiftUI

/// Centralized theme for consistent styling across the app
struct AppTheme {

    // MARK: - New Design System Colors

    struct Colors {
        // Primary brand colors (New Design)
        static let mintGreen = Color(hex: "6EEDC6")       // Primary accent - mint green
        static let darkGreen = Color(hex: "1B4D3E")       // Background dark green (brighter)
        static let deepBlack = Color(hex: "000000")       // Background black
        static let cardBackground = Color(hex: "1A2B25")  // Card/container background

        // Input & Form colors
        static let inputBackground = Color(hex: "C4C4C4") // Light gray input fields
        static let inputBorder = Color(hex: "E5E5E5")     // Input border
        static let placeholder = Color(hex: "6B7280")     // Placeholder text

        // Button colors
        static let buttonSecondary = Color(hex: "6B7280") // Secondary button gray
        static let buttonDisabled = Color(hex: "4B5563")  // Disabled state

        // Text colors
        static let textPrimary = Color.white              // Primary text
        static let textSecondary = Color(hex: "9CA3AF")   // Secondary text
        static let textTertiary = Color(hex: "6B7280")    // Tertiary text

        // Semantic colors
        static let success = Color(hex: "27ae60")         // Green
        static let warning = Color(hex: "e67e22")         // Orange
        static let danger = Color(hex: "E74C3C")          // Red/coral
        static let gold = Color(hex: "f1c40f")            // Gold/Yellow

        // Legacy colors (for backward compatibility)
        static let primary = Color(hex: "667eea")         // Indigo (Quiz)
        static let secondary = Color(hex: "9b59b6")       // Purple (Play)
        static let accent = Color(hex: "3498db")          // Blue (Analyzer)
        static let simulation = Color(hex: "00a896")      // Teal (Simulation)
    }

    // MARK: - Gradients

    struct Gradients {
        // New Design System Gradient - organic ambient light effect
        static var background: some View {
            AmbientGradientBackground()
        }

        // Mint green gradient for buttons
        static let mintButton = LinearGradient(
            colors: [Color(hex: "6EEDC6"), Color(hex: "5DD9B5")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // Card subtle gradient
        static let card = LinearGradient(
            colors: [Color(hex: "1A2B25"), Color(hex: "162420")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // Legacy gradients (for backward compatibility)
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

    // MARK: - Typography

    struct Typography {
        // Font sizes
        static let title1: CGFloat = 32
        static let title2: CGFloat = 28
        static let title3: CGFloat = 24
        static let headline: CGFloat = 20
        static let body: CGFloat = 16
        static let callout: CGFloat = 14
        static let caption: CGFloat = 12

        // Font weights
        static let bold: Font.Weight = .bold
        static let semibold: Font.Weight = .semibold
        static let medium: Font.Weight = .medium
        static let regular: Font.Weight = .regular
    }

    // MARK: - Spacing & Sizing

    struct Layout {
        // Corner radius
        static let cornerRadiusSmall: CGFloat = 8
        static let cornerRadiusMedium: CGFloat = 12
        static let cornerRadiusLarge: CGFloat = 16
        static let cornerRadiusXL: CGFloat = 24
        static let cornerRadiusButton: CGFloat = 24      // Pill-shaped buttons
        static let cornerRadiusInput: CGFloat = 12       // Input fields

        // Spacing
        static let paddingXSmall: CGFloat = 4
        static let paddingSmall: CGFloat = 8
        static let paddingMedium: CGFloat = 16
        static let paddingLarge: CGFloat = 24
        static let paddingXLarge: CGFloat = 32

        // Icon sizes
        static let iconSizeSmall: CGFloat = 20
        static let iconSizeMedium: CGFloat = 24
        static let iconSizeLarge: CGFloat = 32
        static let iconSizeXL: CGFloat = 40

        // Button height
        static let buttonHeight: CGFloat = 56
        static let buttonHeightSmall: CGFloat = 44

        // Input height
        static let inputHeight: CGFloat = 52
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

// MARK: - New Design System Components

/// Primary button style (Mint green)
struct PrimaryButtonStyle: ViewModifier {
    var isEnabled: Bool = true

    func body(content: Content) -> some View {
        content
            .font(.system(size: AppTheme.Typography.headline, weight: .semibold))
            .foregroundColor(AppTheme.Colors.darkGreen)
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.Layout.buttonHeight)
            .background(
                isEnabled ? AppTheme.Colors.mintGreen : AppTheme.Colors.buttonDisabled
            )
            .cornerRadius(AppTheme.Layout.cornerRadiusButton)
            .opacity(isEnabled ? 1.0 : 0.6)
    }
}

/// Secondary button style (Gray)
struct SecondaryButtonStyle: ViewModifier {
    var isEnabled: Bool = true

    func body(content: Content) -> some View {
        content
            .font(.system(size: AppTheme.Typography.headline, weight: .medium))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.Layout.buttonHeight)
            .background(
                isEnabled ? AppTheme.Colors.buttonSecondary : AppTheme.Colors.buttonDisabled
            )
            .cornerRadius(AppTheme.Layout.cornerRadiusButton)
            .opacity(isEnabled ? 1.0 : 0.6)
    }
}

/// Input field style
struct InputFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: AppTheme.Typography.body))
            .foregroundColor(.black)
            .padding(.horizontal, AppTheme.Layout.paddingMedium)
            .frame(height: AppTheme.Layout.inputHeight)
            .background(AppTheme.Colors.inputBackground)
            .cornerRadius(AppTheme.Layout.cornerRadiusInput)
    }
}

/// Dark card background style
struct DarkCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusLarge)
                    .fill(AppTheme.Colors.cardBackground)
            )
    }
}

/// Chip/pill selection style
struct ChipStyle: ViewModifier {
    var isSelected: Bool

    func body(content: Content) -> some View {
        content
            .font(.system(size: AppTheme.Typography.callout, weight: .medium))
            .foregroundColor(isSelected ? AppTheme.Colors.darkGreen : .white)
            .padding(.horizontal, AppTheme.Layout.paddingMedium)
            .padding(.vertical, AppTheme.Layout.paddingSmall)
            .background(
                isSelected ? AppTheme.Colors.mintGreen : AppTheme.Colors.cardBackground
            )
            .cornerRadius(AppTheme.Layout.cornerRadiusButton)
    }
}

extension View {
    func primaryButton(isEnabled: Bool = true) -> some View {
        modifier(PrimaryButtonStyle(isEnabled: isEnabled))
    }

    func secondaryButton(isEnabled: Bool = true) -> some View {
        modifier(SecondaryButtonStyle(isEnabled: isEnabled))
    }

    func inputField() -> some View {
        modifier(InputFieldStyle())
    }

    func darkCard() -> some View {
        modifier(DarkCardStyle())
    }

    func chip(isSelected: Bool) -> some View {
        modifier(ChipStyle(isSelected: isSelected))
    }
}

// MARK: - Ambient Gradient Background

/// Creates an organic, ambient light gradient effect with a radial glow from upper-left
struct AmbientGradientBackground: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base: solid black
                Color.black

                // Primary glow: darker green in upper-left, extends across more of screen
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: "00913C").opacity(0.9), location: 0.0),
                        .init(color: Color(hex: "007530").opacity(0.7), location: 0.25),
                        .init(color: Color(hex: "005522").opacity(0.45), location: 0.5),
                        .init(color: Color(hex: "003015").opacity(0.2), location: 0.75),
                        .init(color: Color.clear, location: 1.0)
                    ]),
                    center: UnitPoint(x: 0.08, y: 0.15),
                    startRadius: 0,
                    endRadius: max(geometry.size.width, geometry.size.height) * 1.1
                )
            }
        }
    }
}

// MARK: - Orientation Helpers

/// Environment key for checking if device is in landscape orientation
struct IsLandscapeKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var isLandscape: Bool {
        get { self[IsLandscapeKey.self] }
        set { self[IsLandscapeKey.self] = newValue }
    }
}

/// A view that detects orientation and provides it to child views
struct OrientationReader<Content: View>: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    let content: (Bool) -> Content

    init(@ViewBuilder content: @escaping (Bool) -> Content) {
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            content(isLandscape)
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

/// View modifier that provides landscape state
struct OrientationModifier: ViewModifier {
    @State private var isLandscape: Bool = false

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .environment(\.isLandscape, geometry.size.width > geometry.size.height)
                .onAppear {
                    isLandscape = geometry.size.width > geometry.size.height
                }
                .onChange(of: geometry.size) { _, newSize in
                    isLandscape = newSize.width > newSize.height
                }
        }
    }
}

extension View {
    /// Provides isLandscape environment value to child views
    func withOrientationTracking() -> some View {
        modifier(OrientationModifier())
    }
}

/// A simple adaptive stack that switches between VStack and HStack based on orientation
struct AdaptiveStack<Content: View>: View {
    let isLandscape: Bool
    let horizontalAlignment: HorizontalAlignment
    let verticalAlignment: VerticalAlignment
    let spacing: CGFloat?
    let content: () -> Content

    init(
        isLandscape: Bool,
        horizontalAlignment: HorizontalAlignment = .center,
        verticalAlignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.isLandscape = isLandscape
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        if isLandscape {
            HStack(alignment: verticalAlignment, spacing: spacing, content: content)
        } else {
            VStack(alignment: horizontalAlignment, spacing: spacing, content: content)
        }
    }
}
