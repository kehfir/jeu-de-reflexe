import Foundation

// MARK: - GameType
// Enumération des 3 types de jeux disponibles
// Concepts CM : enum, CaseIterable, computed properties, rawValue (String)

enum GameType: String, CaseIterable {
    case colorSelector = "Sélecteur de Couleur"
    case swipeGame     = "Jeu de Glisser"
    case dontTapRed    = "Don't Tap Red"

    // Nom de l'image dans Assets.xcassets (CM : computed property)
    var imageName: String {
        switch self {
        case .colorSelector: return "couleur"
        case .swipeGame:     return "glisser"
        case .dontTapRed:    return "rouge"
        }
    }

    // Emoji de secours si l'image n'est pas disponible
    var emoji: String {
        switch self {
        case .colorSelector: return "🎨"
        case .swipeGame:     return "👆"
        case .dontTapRed:    return "🔴"
        }
    }

    // Nom traduit selon la langue (CM : computed property, Singleton)
    var displayName: String {
        switch self {
        case .colorSelector: return AppSettings.shared.loc("Sélecteur de Couleur", "Color Selector")
        case .swipeGame:     return AppSettings.shared.loc("Jeu de Glisser",       "Swipe Game")
        case .dontTapRed:    return AppSettings.shared.loc("Ne Tapez Pas Rouge", "Don't Tap Red")
        }
    }

    // Description courte traduite (CM : computed property)
    var description: String {
        switch self {
        case .colorSelector: return AppSettings.shared.loc("Touchez la bonne couleur !",       "Tap the right color!")
        case .swipeGame:     return AppSettings.shared.loc("Glissez dans la bonne direction !", "Swipe in the right direction!")
        case .dontTapRed:    return AppSettings.shared.loc("Ne touchez jamais le rouge !",      "Never tap the red!")
        }
    }
}
