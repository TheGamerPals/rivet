import SwiftUI

enum RivetTheme {
    static let background = Color(red: 0.027, green: 0.031, blue: 0.027)
    static let primarySurface = Color(red: 0.067, green: 0.075, blue: 0.067)
    static let secondarySurface = Color(red: 0.098, green: 0.110, blue: 0.098)
    static let primaryText = Color(red: 0.91, green: 0.89, blue: 0.84)
    static let secondaryText = Color(red: 0.61, green: 0.64, blue: 0.60)
    static let disabled = Color(red: 0.29, green: 0.31, blue: 0.29)
    static let accent = Color(red: 0.71, green: 1.0, blue: 0.30)
    static let warning = Color(red: 0.82, green: 0.29, blue: 0.25)
    static let progress = Color(red: 0.74, green: 0.63, blue: 0.36)
}

public enum ThemeMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case dark
    case light
    case system

    public var id: String { rawValue }

    var preferredScheme: ColorScheme? {
        switch self {
        case .dark: .dark
        case .light: .light
        case .system: nil
        }
    }
}
