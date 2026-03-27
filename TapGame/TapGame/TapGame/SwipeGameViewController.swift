import UIKit

// MARK: - SwipeDirection
// Enum représentant les 4 directions de glissement (CM : enum avec computed properties)
private enum SwipeDirection: CaseIterable {
    case up, down, left, right

    // Direction opposée (CM : computed property dans un enum)
    var opposite: SwipeDirection {
        switch self {
        case .up:    return .down
        case .down:  return .up
        case .left:  return .right
        case .right: return .left
        }
    }

    // Caractères Unicode simples qui répondent à textColor (CM : String Unicode)
    // Les emoji ⬆️⬇️ ne changent pas de couleur — on utilise ↑↓←→ à la place
    var symbol: String {
        switch self {
        case .up:    return "↑"
        case .down:  return "↓"
        case .left:  return "←"
        case .right: return "→"
        }
    }
}

// MARK: - SwipeGameViewController
// Jeu 2 — Jeu de Glisser
//
// Facile : deux carrés colorés côte à côte → glisser DROITE si pareils, GAUCHE si différents
// Moyen  : une flèche colorée → glisser dans le même sens (verte) ou contraire (rouge)
// Difficile : comme Moyen mais la flèche change automatiquement si on tarde trop
//
// Concepts CM : UIPanGestureRecognizer, enum, switch, Timer, closures, UIStackView

class SwipeGameViewController: UIViewController {

    // MARK: - Config
    private let config: GameConfig

    // MARK: - Palette de couleurs (CM : Array de tuples)
    private let palette: [UIColor] = [
        .systemRed, .systemBlue, .systemGreen,
        .systemYellow, .systemPurple, .systemOrange
    ]

    // MARK: - État commun
    private var score = 0 { didSet { scoreLabel.text = "Score : \(score)" } }
    private var timeRemaining = 30
    private var countdownTimer: Timer?
    private var autoAdvanceTimer: Timer?   // difficile uniquement

    // MARK: - État Facile (paires coïncidentes)
    private var leftColorIndex  = 0
    private var rightColorIndex = 0
    private var doColorsMatch   = false

    // MARK: - État Moyen / Difficile (flèches)
    private var currentArrow: SwipeDirection = .up
    private var arrowIsGreen: Bool = true   // vert = même sens, rouge = contraire

    // MARK: - UI
    private let scoreLabel   = UILabel()
    private let timerLabel   = UILabel()
    private let hintLabel    = UILabel()
    private let feedbackLabel = UILabel()

    // Facile : deux carrés colorés
    private let leftCard  = UIView()
    private let rightCard = UIView()

    // Moyen / Difficile : flèche géante
    private let arrowLabel = UILabel()

    // MARK: - Init
    init(config: GameConfig) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
        title = config.gameType.rawValue
        setupUI()
        // Ajouter le détecteur de glissement (CM : UIGestureRecognizer)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(pan)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startGame()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTimers()
    }

    // MARK: - Construction de l'interface
    private func setupUI() {
        // — Score —
        scoreLabel.font = UIFont.boldSystemFont(ofSize: 22)
        scoreLabel.text = "Score : 0"
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scoreLabel)

        // — Timer —
        timerLabel.font          = UIFont.systemFont(ofSize: 20)
        timerLabel.textAlignment = .right
        timerLabel.text          = "⏱ 30s"
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timerLabel)

        // — Feedback ("+10" / "−5") —
        feedbackLabel.font          = UIFont.boldSystemFont(ofSize: 26)
        feedbackLabel.textAlignment = .center
        feedbackLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(feedbackLabel)

        // — Hint bas de page —
        hintLabel.font          = UIFont.italicSystemFont(ofSize: 14)
        hintLabel.textColor     = .secondaryLabel
        hintLabel.textAlignment = .center
        hintLabel.numberOfLines = 2
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hintLabel)

        if config.level == .easy {
            setupEasyUI()
        } else {
            setupArrowUI()
        }

        NSLayoutConstraint.activate([
            scoreLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            scoreLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            timerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            timerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            timerLabel.leadingAnchor.constraint(equalTo: scoreLabel.trailingAnchor, constant: 8),

            feedbackLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            feedbackLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -120),

            hintLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            hintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor,  constant: 20),
            hintLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }

    private func setupEasyUI() {
        // Deux carrés colorés (CM : UIView)
        for card in [leftCard, rightCard] {
            card.layer.cornerRadius = 20
            card.clipsToBounds      = true
            card.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(card)
        }
        NSLayoutConstraint.activate([
            leftCard.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            leftCard.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -16),
            leftCard.widthAnchor.constraint(equalToConstant: 130),
            leftCard.heightAnchor.constraint(equalToConstant: 130),

            rightCard.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            rightCard.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 16),
            rightCard.widthAnchor.constraint(equalToConstant: 130),
            rightCard.heightAnchor.constraint(equalToConstant: 130),
        ])
        hintLabel.text = "← Différents   Pareils →"
    }

    private func setupArrowUI() {
        // Grande flèche centrale avec fond coloré pour rendre la couleur très visible
        // (CM : layer.cornerRadius, backgroundColor)
        arrowLabel.font                    = UIFont.boldSystemFont(ofSize: 110)
        arrowLabel.textAlignment           = .center
        arrowLabel.layer.cornerRadius      = 24
        arrowLabel.clipsToBounds           = true
        arrowLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(arrowLabel)

        NSLayoutConstraint.activate([
            arrowLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            arrowLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            arrowLabel.widthAnchor.constraint(equalToConstant: 180),
            arrowLabel.heightAnchor.constraint(equalToConstant: 180),
        ])
    }

    // MARK: - Démarrage
    private func startGame() {
        score         = 0
        timeRemaining = 30
        nextRound()

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tickCountdown()
        }

        // Mode Difficile : auto-avance si le joueur ne glisse pas dans les 2s
        if config.level == .hard {
            scheduleAutoAdvance()
        }
    }

    // MARK: - Nouveau round
    private func nextRound() {
        autoAdvanceTimer?.invalidate()

        if config.level == .easy {
            // — Facile : deux carrés —
            leftColorIndex = Int.random(in: 0..<palette.count)
            doColorsMatch  = Bool.random()
            if doColorsMatch {
                rightColorIndex = leftColorIndex
            } else {
                var idx: Int
                // repeat-while : garantit une couleur différente (CM : repeat-while)
                repeat { idx = Int.random(in: 0..<palette.count) } while idx == leftColorIndex
                rightColorIndex = idx
            }
            leftCard.backgroundColor  = palette[leftColorIndex]
            rightCard.backgroundColor = palette[rightColorIndex]

        } else {
            // — Moyen / Difficile : flèche colorée —
            currentArrow = SwipeDirection.allCases.randomElement()!
            arrowIsGreen = Bool.random()
            arrowLabel.text            = currentArrow.symbol
            // textColor sur caractères Unicode (↑↓←→) fonctionne correctement (CM : UIColor)
            arrowLabel.textColor       = .white
            arrowLabel.backgroundColor = arrowIsGreen ? .systemGreen : .systemRed

            let colorWord = arrowIsGreen ? "VERTE" : "ROUGE"
            hintLabel.text = "Flèche \(colorWord) → \(arrowIsGreen ? "même sens" : "sens contraire")"

            if config.level == .hard { scheduleAutoAdvance() }
        }
    }

    // MARK: - Auto-avance (mode Difficile)
    private func scheduleAutoAdvance() {
        autoAdvanceTimer?.invalidate()
        autoAdvanceTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            // Pas de glissement dans les temps → pénalité
            self.score = max(0, self.score - 5)
            self.showFeedback("⏰ −5", color: .systemOrange)
            self.nextRound()
        }
    }

    // MARK: - Détection du glissement (CM : UIPanGestureRecognizer)
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard gesture.state == .ended else { return }

        let velocity  = gesture.velocity(in: view)
        let direction = swipeDirection(from: velocity)
        processSwipe(direction: direction)
    }

    // Convertir la vélocité en direction cardinale (CM : if/else, abs)
    private func swipeDirection(from velocity: CGPoint) -> SwipeDirection {
        if abs(velocity.x) > abs(velocity.y) {
            return velocity.x > 0 ? .right : .left
        } else {
            return velocity.y > 0 ? .down : .up
        }
    }

    // MARK: - Traitement du glissement (CM : switch sur enum)
    private func processSwipe(direction: SwipeDirection) {
        autoAdvanceTimer?.invalidate()
        let isCorrect: Bool

        switch config.level {
        case .easy:
            // Droite = pareils, Gauche = différents
            switch direction {
            case .right: isCorrect = doColorsMatch
            case .left:  isCorrect = !doColorsMatch
            default:     return   // haut/bas ignorés
            }

        case .medium, .hard:
            // Vert = même direction, Rouge = direction opposée
            let expectedDirection = arrowIsGreen ? currentArrow : currentArrow.opposite
            isCorrect = (direction == expectedDirection)
        }

        if isCorrect {
            score += 10
            showFeedback("+10", color: .systemGreen)
        } else {
            score = max(0, score - 5)
            showFeedback("−5", color: .systemRed)
        }

        // Pause brève puis round suivant (CM : Timer.scheduledTimer)
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            self?.nextRound()
        }
    }

    // MARK: - Feedback visuel
    private func showFeedback(_ text: String, color: UIColor) {
        feedbackLabel.text      = text
        feedbackLabel.textColor = color
        feedbackLabel.alpha     = 1
        UIView.animate(withDuration: 0.6, delay: 0.2) {
            self.feedbackLabel.alpha = 0
        }
    }

    // MARK: - Compte à rebours
    private func tickCountdown() {
        timeRemaining -= 1
        timerLabel.text = "⏱ \(timeRemaining)s"
        if timeRemaining <= 10 { timerLabel.textColor = .systemRed }
        if timeRemaining <= 0  { endGame() }
    }

    private func stopTimers() {
        countdownTimer?.invalidate();    countdownTimer    = nil
        autoAdvanceTimer?.invalidate();  autoAdvanceTimer  = nil
    }

    // MARK: - Fin de partie
    private func endGame() {
        stopTimers()
        let resultVC = ResultViewController(score: score, config: config, didWin: true)
        navigationController?.pushViewController(resultVC, animated: true)
    }
}
