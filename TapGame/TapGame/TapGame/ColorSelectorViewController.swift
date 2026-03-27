import UIKit

// MARK: - ColorSelectorViewController
// Jeu 1 — Sélecteur de Couleur (Facile & Moyen)
//
// Facile : un nom de couleur s'affiche dans sa couleur → toucher le bon bouton
// Moyen  : effet Stroop — le mot est dans une AUTRE couleur → toucher la couleur du texte
//
// Concepts CM : Timer, closures [weak self], Array, Dictionary, switch, guard,
//               UIButton en grille 2×2, NSAttributedString, propriétés calculées

class ColorSelectorViewController: UIViewController {

    // MARK: - Config (transmise depuis InstructionViewController)
    private let config: GameConfig

    // MARK: - Données du jeu — tableau de tuples (CM : tableaux, tuples)
    // Chaque élément : (couleur UIKit, nom en français)
    private let palette: [(color: UIColor, name: String)] = [
        (.systemRed,    "ROUGE"),
        (.systemBlue,   "BLEU"),
        (.systemGreen,  "VERT"),
        (.systemYellow, "JAUNE"),
    ]

    // Couleurs mélangées pour la disposition actuelle des boutons
    private var buttonPalette: [(color: UIColor, name: String)] = []
    // Nom de la couleur correcte pour ce round
    private var correctColorName: String = ""

    // MARK: - État du jeu
    // Propriété calculée : met à jour le label à chaque changement (CM : didSet)
    private var score = 0 { didSet { scoreLabel.text = "Score : \(score)" } }
    private var timeRemaining = 30

    // Timer optionnel (CM : optionnels, Timer?)
    private var countdownTimer: Timer?

    // MARK: - UI
    private let scoreLabel   = UILabel()
    private let timerLabel   = UILabel()
    private let wordLabel    = UILabel()   // affiche le nom de la couleur
    private var colorButtons: [UIButton] = []

    // MARK: - Init
    init(config: GameConfig) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) non supporté") }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
        title = config.gameType.rawValue
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startGame()
    }

    // Arrêter le timer si l'écran disparaît (CM : UIViewController lifecycle)
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    // MARK: - Construction de l'interface
    private func setupUI() {
        // — Score (en haut à gauche) —
        scoreLabel.font = UIFont.boldSystemFont(ofSize: 22)
        scoreLabel.text = "Score : 0"
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scoreLabel)

        // — Timer (en haut à droite) —
        timerLabel.font          = UIFont.systemFont(ofSize: 20)
        timerLabel.textAlignment = .right
        timerLabel.text          = "⏱ 30s"
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timerLabel)

        // — Mot affiché (grande taille) —
        wordLabel.font          = UIFont.boldSystemFont(ofSize: 56)
        wordLabel.textAlignment = .center
        wordLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(wordLabel)

        // — Sous-titre selon le mode —
        let hintLabel = UILabel()
        hintLabel.font          = UIFont.italicSystemFont(ofSize: 14)
        hintLabel.textColor     = .secondaryLabel
        hintLabel.textAlignment = .center
        hintLabel.text = config.level == .medium
            ? "Touchez la couleur du texte !"
            : "Touchez la couleur nommée !"
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hintLabel)

        // — Grille 2×2 de boutons colorés —
        // On crée deux lignes avec UIStackView horizontal (CM : UIStackView imbriqués)
        let row1 = UIStackView()
        let row2 = UIStackView()
        for row in [row1, row2] {
            row.axis         = .horizontal
            row.spacing      = 14
            row.distribution = .fillEqually
        }

        for i in 0..<4 {
            let btn = UIButton(type: .system)
            btn.layer.cornerRadius = 14
            btn.clipsToBounds      = true
            btn.tag = i
            btn.addTarget(self, action: #selector(colorButtonTapped(_:)), for: .touchUpInside)
            colorButtons.append(btn)
            (i < 2 ? row1 : row2).addArrangedSubview(btn)
        }

        let grid = UIStackView(arrangedSubviews: [row1, row2])
        grid.axis         = .vertical
        grid.spacing      = 14
        grid.distribution = .fillEqually
        grid.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(grid)

        NSLayoutConstraint.activate([
            scoreLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            scoreLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            timerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            timerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            timerLabel.leadingAnchor.constraint(equalTo: scoreLabel.trailingAnchor, constant: 8),

            wordLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            wordLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 36),

            hintLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hintLabel.topAnchor.constraint(equalTo: wordLabel.bottomAnchor, constant: 8),

            grid.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 40),
            grid.leadingAnchor.constraint(equalTo: view.leadingAnchor,  constant: 28),
            grid.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            grid.heightAnchor.constraint(equalToConstant: 180),
        ])
    }

    // MARK: - Démarrage
    private func startGame() {
        score         = 0
        timeRemaining = 30
        nextRound()

        // Timer de compte à rebours (CM : Timer, closures [weak self])
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tickCountdown()
        }
    }

    // MARK: - Nouveau round : choisir les couleurs et mettre à jour l'UI
    private func nextRound() {
        // Mélanger la palette pour la disposition des boutons (CM : tableaux, shuffle)
        buttonPalette = palette.shuffled()

        if config.level == .medium {
            // — Mode Stroop —
            // Le mot dit une chose mais est affiché dans une couleur DIFFÉRENTE
            let wordEntry    = palette.randomElement()!
            // Filtrer pour avoir une couleur d'affichage ≠ couleur du mot (CM : filter)
            let otherColors  = palette.filter { $0.name != wordEntry.name }
            let displayEntry = otherColors.randomElement()!

            wordLabel.text      = wordEntry.name      // ce que dit le mot
            wordLabel.textColor = displayEntry.color  // la couleur d'affichage (≠ mot)
            // La bonne réponse = couleur d'affichage du texte
            correctColorName    = displayEntry.name
        } else {
            // — Mode Facile —
            // Le mot correspond à sa couleur
            let target       = palette.randomElement()!
            wordLabel.text   = target.name
            wordLabel.textColor = target.color
            correctColorName = target.name
        }

        // Mettre à jour les 4 boutons avec les couleurs mélangées
        for (i, btn) in colorButtons.enumerated() {
            btn.backgroundColor = buttonPalette[i].color
        }
    }

    // MARK: - Tap sur un bouton couleur (CM : @objc, IBAction)
    @objc private func colorButtonTapped(_ sender: UIButton) {
        let tappedName = buttonPalette[sender.tag].name

        if tappedName == correctColorName {
            score += 10
            showFloatingText("+10", at: sender.center, color: .systemGreen)
        } else {
            score = max(0, score - 5)
            showFloatingText("−5", at: sender.center, color: .systemRed)
        }
        nextRound()
    }

    // MARK: - Compte à rebours
    private func tickCountdown() {
        timeRemaining -= 1
        timerLabel.text = "⏱ \(timeRemaining)s"
        if timeRemaining <= 10 { timerLabel.textColor = .systemRed }
        if timeRemaining <= 0  { endGame() }
    }

    // MARK: - Fin de partie → ResultViewController
    private func endGame() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        let resultVC = ResultViewController(score: score, config: config, didWin: true)
        navigationController?.pushViewController(resultVC, animated: true)
    }

    // MARK: - Texte flottant animé (CM : UIView.animate, closures)
    private func showFloatingText(_ text: String, at center: CGPoint, color: UIColor) {
        let label       = UILabel()
        label.text      = text
        label.textColor = color
        label.font      = UIFont.boldSystemFont(ofSize: 26)
        label.sizeToFit()
        label.center    = center
        view.addSubview(label)

        UIView.animate(withDuration: 0.8, animations: {
            label.center = CGPoint(x: center.x, y: center.y - 70)
            label.alpha  = 0
        }) { _ in label.removeFromSuperview() }
    }
}
