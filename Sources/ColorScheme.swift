import SwiftUI

struct ColorScheme {
    @Environment(\.colorScheme) private var systemColorScheme
    
    // MARK: - Dynamic Colors
    struct Dynamic {
        // Backgrounds
        static func backgroundPrimary(_ scheme: SwiftUI.ColorScheme) -> Color {
            scheme == .dark 
                ? Color(red: 0.11, green: 0.11, blue: 0.12)
                : Color(red: 0.98, green: 0.98, blue: 0.99)
        }
        
        static func backgroundSecondary(_ scheme: SwiftUI.ColorScheme) -> Color {
            scheme == .dark 
                ? Color(red: 0.14, green: 0.14, blue: 0.16)
                : Color.white
        }
        
        static func backgroundTertiary(_ scheme: SwiftUI.ColorScheme) -> Color {
            scheme == .dark 
                ? Color(red: 0.09, green: 0.09, blue: 0.10)
                : Color(red: 0.96, green: 0.97, blue: 0.98)
        }
        
        static func backgroundGlass(_ scheme: SwiftUI.ColorScheme) -> Color {
            scheme == .dark 
                ? Color.black.opacity(0.6)
                : Color.white.opacity(0.8)
        }
        
        // Surfaces
        static func surfaceElevated(_ scheme: SwiftUI.ColorScheme) -> Color {
            scheme == .dark 
                ? Color(red: 0.18, green: 0.18, blue: 0.20)
                : Color.white
        }
        
        static func surfaceCard(_ scheme: SwiftUI.ColorScheme) -> Color {
            scheme == .dark 
                ? Color(red: 0.16, green: 0.16, blue: 0.18)
                : Color(red: 0.99, green: 0.99, blue: 1.0)
        }
        
        // Accents (slightly adjusted for dark mode visibility)
        static func accentPrimary(_ scheme: SwiftUI.ColorScheme) -> Color {
            scheme == .dark 
                ? Color(red: 0.1, green: 0.58, blue: 1.0)
                : Color(red: 0.0, green: 0.48, blue: 1.0)
        }
        
        static func accentSecondary(_ scheme: SwiftUI.ColorScheme) -> Color {
            scheme == .dark 
                ? Color(red: 0.44, green: 0.44, blue: 0.94)
                : Color(red: 0.34, green: 0.34, blue: 0.84)
        }
        
        static let accentSuccess = Color(red: 0.20, green: 0.78, blue: 0.35)
        static let accentWarning = Color(red: 1.0, green: 0.58, blue: 0.0)
        static let accentDanger = Color(red: 0.96, green: 0.26, blue: 0.21)
        
        // Text
        static func textPrimary(_ scheme: SwiftUI.ColorScheme) -> Color {
            scheme == .dark 
                ? Color(red: 0.92, green: 0.92, blue: 0.94)
                : Color(red: 0.11, green: 0.11, blue: 0.12)
        }
        
        static func textSecondary(_ scheme: SwiftUI.ColorScheme) -> Color {
            scheme == .dark 
                ? Color(red: 0.68, green: 0.68, blue: 0.70)
                : Color(red: 0.47, green: 0.47, blue: 0.49)
        }
        
        static func textTertiary(_ scheme: SwiftUI.ColorScheme) -> Color {
            scheme == .dark 
                ? Color(red: 0.47, green: 0.47, blue: 0.49)
                : Color(red: 0.68, green: 0.68, blue: 0.70)
        }
        
        // Borders
        static func borderLight(_ scheme: SwiftUI.ColorScheme) -> Color {
            scheme == .dark 
                ? Color(red: 0.25, green: 0.25, blue: 0.28)
                : Color(red: 0.90, green: 0.90, blue: 0.92)
        }
        
        static func borderMedium(_ scheme: SwiftUI.ColorScheme) -> Color {
            scheme == .dark 
                ? Color(red: 0.32, green: 0.32, blue: 0.35)
                : Color(red: 0.82, green: 0.82, blue: 0.84)
        }
        
        // Shadows
        static func shadowCard(_ scheme: SwiftUI.ColorScheme) -> Color {
            scheme == .dark 
                ? Color.black.opacity(0.3)
                : Color.black.opacity(0.05)
        }
        
        static func shadowElevated(_ scheme: SwiftUI.ColorScheme) -> Color {
            scheme == .dark 
                ? Color.black.opacity(0.4)
                : Color.black.opacity(0.10)
        }
        
        static func shadowDeep(_ scheme: SwiftUI.ColorScheme) -> Color {
            scheme == .dark 
                ? Color.black.opacity(0.5)
                : Color.black.opacity(0.15)
        }
    }
}

// MARK: - View Extensions for Dynamic Colors
extension View {
    func dynamicBackground(_ colorFunc: @escaping (SwiftUI.ColorScheme) -> Color) -> some View {
        self.modifier(DynamicColorModifier(colorFunc: colorFunc, property: .background))
    }
    
    func dynamicForeground(_ colorFunc: @escaping (SwiftUI.ColorScheme) -> Color) -> some View {
        self.modifier(DynamicColorModifier(colorFunc: colorFunc, property: .foreground))
    }
}

struct DynamicColorModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let colorFunc: (SwiftUI.ColorScheme) -> Color
    let property: ColorProperty
    
    enum ColorProperty {
        case background
        case foreground
    }
    
    func body(content: Content) -> some View {
        switch property {
        case .background:
            content.background(colorFunc(colorScheme))
        case .foreground:
            content.foregroundColor(colorFunc(colorScheme))
        }
    }
}