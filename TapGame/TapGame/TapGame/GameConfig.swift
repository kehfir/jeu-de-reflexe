import UIKit

// MARK: - GameConfig
// Structure de configuration associant un jeu et un niveau (CM : struct, types valeur)

struct GameConfig {
    let gameType: GameType
    let level:    GameLevel

    var levelColor: UIColor {
        switch level {
        case .easy:   return .systemGreen
        case .medium: return .systemOrange
        case .hard:   return .systemRed
        }
    }

    // Description courte — bilingue (CM : switch sur tuple, Singleton)
    var shortDescription: String {
        let l = AppSettings.shared.loc
        switch (gameType, level) {
        case (.colorSelector, .easy):   return l("Touchez la bonne couleur — 30 sec",       "Tap the right color — 30 sec")
        case (.colorSelector, .medium): return l("Effet Stroop — couleur du texte — 30 sec", "Stroop effect — text color — 30 sec")
        case (.colorSelector, .hard):   return l("Cercles mobiles rapides + combos — 45 sec","Fast moving circles + combos — 45 sec")
        case (.swipeGame, .easy):       return l("Paires coïncidentes — glissez ← ou →",    "Matching pairs — swipe ← or →")
        case (.swipeGame, .medium):     return l("Flèche verte = même sens, rouge = contraire","Green = same dir, red = opposite")
        case (.swipeGame, .hard):       return l("Flèches rapides — changement automatique", "Fast arrows — auto change")
        case (.dontTapRed, .easy):      return l("10 cercles — évitez le rouge — 30 sec",   "10 circles — avoid red — 30 sec")
        case (.dontTapRed, .medium):    return l("6 cercles — tapez pour changer — 30 sec", "6 circles — tap to change — 30 sec")
        case (.dontTapRed, .hard):      return l("20 cercles mobiles — 3 vies — 45 sec",    "20 moving circles — 3 lives — 45 sec")
        }
    }

    // Instructions complètes — bilingues (CM : switch sur tuple)
    var instructions: String {
        let l = AppSettings.shared.loc
        switch (gameType, level) {

        case (.colorSelector, .easy):
            return l(
                "Un nom de couleur s'affiche.\n\nTouchez le bouton qui correspond à la couleur nommée !\n\n⏱ 30 secondes",
                "A color name appears.\n\nTap the button matching the named color!\n\n⏱ 30 seconds"
            )
        case (.colorSelector, .medium):
            return l(
                "Un mot s'affiche dans une couleur différente.\n\nTouchez la couleur du TEXTE, pas ce que le mot dit !\n\nEffet Stroop — ⏱ 30 secondes",
                "A word appears in a different color.\n\nTap the color of the TEXT, not what the word says!\n\nStroop effect — ⏱ 30 seconds"
            )
        case (.colorSelector, .hard):
            return l(
                "Cercles mobiles très rapides !\n\nVerts = +10  |  Rouges = −5\nFaites des combos ×5 pour +30 !\n\n⏱ 45 secondes",
                "Very fast moving circles!\n\nGreen = +10  |  Red = −5\nCombo ×5 = +30!\n\n⏱ 45 seconds"
            )
        case (.swipeGame, .easy):
            return l(
                "Deux carrés colorés apparaissent.\n\nGlissez → DROITE si les couleurs sont pareilles.\nGlissez ← GAUCHE si elles sont différentes.\n\n⏱ 30 secondes",
                "Two colored squares appear.\n\nSwipe → RIGHT if the colors match.\nSwipe ← LEFT if they are different.\n\n⏱ 30 seconds"
            )
        case (.swipeGame, .medium):
            return l(
                "Une flèche colorée s'affiche.\n\n🟩 Verte → glissez dans le MÊME sens.\n🟥 Rouge → glissez dans le sens CONTRAIRE.\n\n⏱ 30 secondes",
                "A colored arrow appears.\n\n🟩 Green → swipe in the SAME direction.\n🟥 Red → swipe in the OPPOSITE direction.\n\n⏱ 30 seconds"
            )
        case (.swipeGame, .hard):
            return l(
                "Flèches rapides et automatiques !\n\n🟩 Verte → même sens  |  🟥 Rouge → contraire.\n\nLa flèche change si vous tardez trop !\n\n⏱ 30 secondes",
                "Fast and automatic arrows!\n\n🟩 Green → same direction  |  🟥 Red → opposite.\n\nThe arrow changes if you wait too long!\n\n⏱ 30 seconds"
            )
        case (.dontTapRed, .easy):
            return l(
                "10 cercles apparaissent.\n\nTouchez les cercles — évitez le ROUGE !\nUn rouge touché = Perdu !\n\n⏱ 30 secondes",
                "10 circles appear.\n\nTap the circles — avoid RED!\nOne red tapped = Game over!\n\n⏱ 30 seconds"
            )
        case (.dontTapRed, .medium):
            return l(
                "6 cercles de couleurs variées.\n\nTouchez n'importe quel cercle NON-ROUGE.\nIl change de couleur et vous marquez +10 !\nTouchez le rouge = Perdu !\n\n⏱ 30 secondes",
                "6 colorful circles.\n\nTap any NON-RED circle.\nIt changes color and you score +10!\nTap red = Game over!\n\n⏱ 30 seconds"
            )
        case (.dontTapRed, .hard):
            return l(
                "20 cercles mobiles mélangés !\n\nMême règle — mais les cercles bougent vite !\nToucher rouge = −❤️  |  Vous avez 3 vies.\nLes cercles peuvent changer de couleur !\n\n⏱ 45 secondes",
                "20 mixed moving circles!\n\nSame rule — but circles move fast!\nTap red = −❤️  |  You have 3 lives.\nCircles can change color!\n\n⏱ 45 seconds"
            )
        }
    }
}
