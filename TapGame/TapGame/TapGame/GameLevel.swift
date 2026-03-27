import Foundation

// MARK: - GameLevel
// Enumération des trois niveaux de difficulté (CM : enums Swift)
enum GameLevel: String {
    case easy   = "Facile"
    case medium = "Moyen"
    case hard   = "Difficile"

    // Nom traduit selon la langue choisie (CM : computed property, Singleton)
    var displayName: String {
        switch self {
        case .easy:   return AppSettings.shared.loc("Facile",    "Easy")
        case .medium: return AppSettings.shared.loc("Moyen",     "Medium")
        case .hard:   return AppSettings.shared.loc("Difficile", "Hard")
        }
    }
}
