import UIKit

// MARK: - CircleView
// Sous-classe de UIButton représentant un cercle cliquable du jeu
// (CM : classes Swift, héritage, propriétés stockées)
class CircleView: UIButton {

    // Vitesse de déplacement — utilisées uniquement en niveau Difficile
    var velocityX: CGFloat = 0
    var velocityY: CGFloat = 0

    // Vrai si ce cercle est un obstacle (ne pas toucher)
    var isObstacle: Bool = false

    // Position dans la séquence combo (0 = cercle normal)
    var comboIndex: Int = 0

    // MARK: - Initialiseurs (CM : init)
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    // MARK: - Configuration commune
    private func configure() {
        clipsToBounds = true
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 22)
        setTitleColor(.white, for: .normal)
    }

    // Rend le bouton parfaitement rond
    // À appeler après avoir défini le frame
    func makeCircular() {
        layer.cornerRadius = frame.width / 2
    }
}
