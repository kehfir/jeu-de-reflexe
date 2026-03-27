import UIKit

// MARK: - DontTapRedViewController
// Jeu 3 — Don't Tap Red
//
// Facile    : 10 cercles (3 verts + 7 rouges) — 30s — tap vert = score, tap rouge = perdu
// Moyen     : 6 cercles de couleurs variées — 30s — tap non-rouge = change couleur + score,
//             tap rouge = perdu
// Difficile : 20 cercles mobiles (7 rouges + 13 couleurs) — 45s — 3 vies
//             tap non-rouge = change couleur + score, tap rouge = -1 vie
//
// Concepts CM : Array, Dictionary, Timer, closures [weak self], UIButton (CGRect),
//               UIView.animate, repeat-while, propriétés calculées, @objc, guard,
//               Singleton (AppSettings)

class DontTapRedViewController: UIViewController {

    // MARK: - Config
    private let config: GameConfig

    // MARK: - Palette de couleurs sûres (non-rouge) (CM : Array de UIColor)
    private let safeColors: [UIColor] = [
        .systemBlue, .systemGreen, .systemOrange,
        .systemPurple, .systemYellow,
        .systemTeal, .systemIndigo, .systemCyan
    ]

    // MARK: - Configuration par niveau (CM : computed properties, switch)
    private var totalCircles: Int {
        switch config.level { case .easy: return 10;  case .medium: return 6;  case .hard: return 20 }
    }
    private var redCount: Int {
        switch config.level { case .easy: return 7;   case .medium: return 2;  case .hard: return 7  }
    }
    private var safeCount: Int { totalCircles - redCount }
    private var timeLimit: Int {
        switch config.level { case .easy: return 30;  case .medium: return 30; case .hard: return 45 }
    }
    private var circleSize: CGFloat {
        config.level == .hard ? 52 : 64
    }

    // MARK: - État du jeu
    private var score = 0 {
        didSet { scoreLabel.text = "Score : \(score)" }
    }
    private var lives = 3 {
        didSet { livesLabel.text = String(repeating: "❤️", count: max(0, lives)) }
    }
    private var timeRemaining = 0

    // MARK: - Cercles (CM : Array, Dictionary)
    private var circles:      [UIButton]          = []
    private var circleColors: [UIButton: UIColor]  = [:]
    private var velocities:   [UIButton: CGPoint]  = [:]

    // Nombre de cercles sûrs actuellement visibles (CM : filter, computed property)
    private var currentSafeCount: Int {
        circles.filter { circleColors[$0] != .systemRed }.count
    }

    // MARK: - Timers (CM : optionnels Timer?)
    private var countdownTimer: Timer?
    private var moveTimer:      Timer?

    // MARK: - UI
    private let scoreLabel   = UILabel()
    private let timerLabel   = UILabel()
    private let livesLabel   = UILabel()
    private let messageLabel = UILabel()

    private var gameAreaTop: CGFloat { view.safeAreaInsets.top + 80 }

    // MARK: - Init
    init(config: GameConfig) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = config.gameType.displayName
        setupLabels()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startGame()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTimers()
    }

    // MARK: - Labels
    private func setupLabels() {
        scoreLabel.font = UIFont.boldSystemFont(ofSize: 22)
        scoreLabel.text = "Score : 0"
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scoreLabel)

        timerLabel.font          = UIFont.systemFont(ofSize: 20)
        timerLabel.textAlignment = .right
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timerLabel)

        // Vies : uniquement en mode Difficile (CM : isHidden)
        livesLabel.font          = UIFont.systemFont(ofSize: 22)
        livesLabel.textAlignment = .center
        livesLabel.isHidden      = (config.level != .hard)
        livesLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(livesLabel)

        messageLabel.font          = UIFont.italicSystemFont(ofSize: 14)
        messageLabel.textAlignment = .center
        messageLabel.textColor     = .secondaryLabel
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            scoreLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            scoreLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            timerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            timerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            timerLabel.leadingAnchor.constraint(equalTo: scoreLabel.trailingAnchor, constant: 8),

            livesLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 2),
            livesLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            messageLabel.topAnchor.constraint(equalTo: livesLabel.bottomAnchor, constant: 2),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor,  constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
    }

    // MARK: - Démarrage
    private func startGame() {
        score         = 0
        lives         = 3
        timeRemaining = timeLimit
        timerLabel.text = "⏱ \(timeLimit)s"

        switch config.level {
        case .easy:
            messageLabel.text = "Touchez les cercles — évitez le ROUGE !"
            spawnAllCircles()
            startCountdown()

        case .medium:
            messageLabel.text = "Changez les couleurs — évitez le ROUGE !"
            spawnAllCircles()
            startCountdown()
            // Mouvement lent en mode Moyen (CM : Timer, closures [weak self])
            moveTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0,
                                             repeats: true) { [weak self] _ in
                self?.moveCircles()
            }

        case .hard:
            livesLabel.text   = String(repeating: "❤️", count: lives)
            messageLabel.text = "Évitez les ROUGES — 3 vies ❤️❤️❤️"
            spawnAllCircles()
            startCountdown()
            // Déplacement à 60 fps (CM : Timer, closures [weak self])
            moveTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0,
                                             repeats: true) { [weak self] _ in
                self?.moveCircles()
            }
        }
    }

    // MARK: - Génération de tous les cercles (CM : repeat-while, Array, shuffle)
    private func spawnAllCircles() {
        clearCircles()
        let size   = circleSize
        let top    = gameAreaTop
        let bottom = view.bounds.height - view.safeAreaInsets.bottom - size
        let right  = view.bounds.width  - size
        guard bottom > top, right > 0 else { return }

        // Mélanger les types : safe + rouge (CM : Array, shuffle)
        let shuffledSafe = safeColors.shuffled()
        var types: [(color: UIColor, isRed: Bool)] = []

        // Mode moyen : 4 couleurs uniques + 2 rouges
        if config.level == .medium {
            for i in 0..<safeCount { types.append((shuffledSafe[i % shuffledSafe.count], false)) }
        } else {
            for _ in 0..<safeCount { types.append((safeColors.randomElement()!, false)) }
        }
        for _ in 0..<redCount { types.append((.systemRed, true)) }
        types.shuffle()

        var placed: [CGRect] = []

        for t in types {
            var rect  = CGRect.zero
            var tries = 0
            // repeat-while : garantit l'absence de chevauchement (CM : repeat-while)
            repeat {
                let x = CGFloat.random(in: 0...right)
                let y = CGFloat.random(in: top...bottom)
                rect  = CGRect(x: x, y: y, width: size, height: size)
                tries += 1
            } while placed.contains(where: {
                rect.insetBy(dx: -8, dy: -8).intersects($0)
            }) && tries < 50

            let btn = UIButton(type: .custom)
            btn.frame              = rect
            btn.layer.cornerRadius = size / 2
            btn.clipsToBounds      = true
            btn.backgroundColor    = t.color
            btn.addTarget(self, action: #selector(circleTapped(_:)), for: .touchUpInside)

            // Apparition animée (CM : UIView.animate, CGAffineTransform)
            btn.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            view.addSubview(btn)
            UIView.animate(withDuration: 0.2) { btn.transform = .identity }

            circles.append(btn)
            circleColors[btn] = t.color
            placed.append(rect)

            // Vitesse selon le niveau — Moyen lent, Difficile rapide (CM : switch, trigonométrie)
            if config.level == .medium || config.level == .hard {
                let speed = config.level == .hard
                    ? CGFloat.random(in: 2.8...5.0)
                    : CGFloat.random(in: 1.2...2.2)   // Moyen : plus lent
                let angle = CGFloat.random(in: 0...(2 * .pi))
                velocities[btn] = CGPoint(x: cos(angle) * speed, y: sin(angle) * speed)
            }
        }
    }

    // MARK: - Tap sur un cercle (CM : @objc, guard, Dictionary)
    @objc private func circleTapped(_ sender: UIButton) {
        guard circles.contains(sender) else { return }
        let isRed = (circleColors[sender] == .systemRed)

        if isRed {
            // — Touché rouge —
            showFloatingText("💥 ROUGE !", at: sender.center, color: .systemRed)
            AppSettings.shared.playLose()   // son de défaite (CM : Singleton)

            if config.level == .hard {
                lives -= 1
                if lives <= 0 { endGame(didWin: false) }
            } else {
                endGame(didWin: false)
            }

        } else {
            // — Touché couleur sûre —
            score += 10
            showFloatingText("+10", at: sender.center, color: .systemGreen)
            AppSettings.shared.playTap()

            if config.level == .easy {
                // Facile : retirer le cercle et en respawner un nouveau
                removeCircle(sender)
                Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false) { [weak self] _ in
                    self?.spawnOneReplacement()
                }
            } else {
                // Moyen / Difficile : changer la couleur du cercle
                // Toujours une couleur sûre — jamais rouge (CM : randomNextColor)
                let newColor = randomNextColor(excluding: circleColors[sender])
                circleColors[sender] = newColor
                UIView.animate(withDuration: 0.25) { sender.backgroundColor = newColor }
            }
        }
    }

    // MARK: - Couleur suivante aléatoire — toujours une couleur sûre (CM : Array, repeat-while)
    // On ne remet JAMAIS rouge : les cercles rouges sont fixes à la génération initiale.
    // Cela garantit que le joueur a toujours des cibles sûres et ne force pas la défaite.
    private func randomNextColor(excluding current: UIColor?) -> UIColor {
        var newColor: UIColor
        repeat { newColor = safeColors.randomElement()! } while newColor == current
        return newColor
    }

    // MARK: - Spawner un cercle de remplacement (mode Facile)
    private func spawnOneReplacement() {
        guard circles.count < totalCircles else { return }
        let size   = circleSize
        let top    = gameAreaTop
        let bottom = view.bounds.height - view.safeAreaInsets.bottom - size
        let right  = view.bounds.width  - size
        guard bottom > top, right > 0 else { return }

        var rect  = CGRect.zero
        var tries = 0
        repeat {
            let x = CGFloat.random(in: 0...right)
            let y = CGFloat.random(in: top...bottom)
            rect  = CGRect(x: x, y: y, width: size, height: size)
            tries += 1
        } while circles.map({ $0.frame }).contains(where: {
            rect.insetBy(dx: -8, dy: -8).intersects($0)
        }) && tries < 30

        // Garantir au moins 2 cercles sûrs à l'écran (CM : computed property, guard)
        // Si on a déjà moins de 2 sûrs, on force un cercle sûr
        let isRed: Bool = currentSafeCount >= 2 ? (Int.random(in: 0...3) == 0) : false
        let color: UIColor = isRed ? .systemRed : safeColors.randomElement()!

        let btn = UIButton(type: .custom)
        btn.frame              = rect
        btn.layer.cornerRadius = size / 2
        btn.clipsToBounds      = true
        btn.backgroundColor    = color
        btn.addTarget(self, action: #selector(circleTapped(_:)), for: .touchUpInside)

        btn.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        view.addSubview(btn)
        UIView.animate(withDuration: 0.2) { btn.transform = .identity }

        circles.append(btn)
        circleColors[btn] = color
    }

    // MARK: - Suppression avec animation (CM : UIView.animate, closures)
    private func removeCircle(_ circle: UIButton) {
        UIView.animate(withDuration: 0.15, animations: {
            circle.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            circle.alpha     = 0
        }) { [weak self] _ in
            circle.removeFromSuperview()
            self?.circles.removeAll    { $0 === circle }
            self?.velocities.removeValue(forKey: circle)
            self?.circleColors.removeValue(forKey: circle)
        }
    }

    private func clearCircles() {
        circles.forEach { $0.removeFromSuperview() }
        circles.removeAll()
        velocities.removeAll()
        circleColors.removeAll()
    }

    // MARK: - Mouvement 60 fps (mode Difficile) — rebond sur les bords (CM : Dictionary)
    private func moveCircles() {
        let bounds   = view.bounds
        let topLimit = gameAreaTop
        let botLimit = bounds.height - view.safeAreaInsets.bottom

        for circle in circles {
            guard var v = velocities[circle] else { continue }
            var ox = circle.frame.origin.x + v.x
            var oy = circle.frame.origin.y + v.y

            if ox < 0 {
                ox = 0; v.x = abs(v.x)
            } else if ox + circle.frame.width > bounds.width {
                ox = bounds.width - circle.frame.width; v.x = -abs(v.x)
            }
            if oy < topLimit {
                oy = topLimit; v.y = abs(v.y)
            } else if oy + circle.frame.height > botLimit {
                oy = botLimit - circle.frame.height; v.y = -abs(v.y)
            }

            circle.frame.origin = CGPoint(x: ox, y: oy)
            velocities[circle]  = v
        }
    }

    // MARK: - Compte à rebours (CM : Timer, closures)
    private func startCountdown() {
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.timeRemaining -= 1
            self.timerLabel.text = "⏱ \(self.timeRemaining)s"
            if self.timeRemaining <= 10 { self.timerLabel.textColor = .systemRed }
            if self.timeRemaining <= 0  { self.endGame(didWin: true) }
        }
    }

    private func stopTimers() {
        countdownTimer?.invalidate(); countdownTimer = nil
        moveTimer?.invalidate();      moveTimer      = nil
    }

    // MARK: - Fin de partie (CM : pushViewController)
    private func endGame(didWin: Bool) {
        stopTimers()
        clearCircles()
        if didWin { AppSettings.shared.playWin() } else { AppSettings.shared.playLose() }
        let resultVC = ResultViewController(score: score, config: config, didWin: didWin)
        navigationController?.pushViewController(resultVC, animated: true)
    }

    // MARK: - Texte flottant (CM : UIView.animate, UILabel)
    private func showFloatingText(_ text: String, at center: CGPoint, color: UIColor) {
        let label       = UILabel()
        label.text      = text
        label.textColor = color
        label.font      = UIFont.boldSystemFont(ofSize: 28)
        label.sizeToFit()
        label.center    = center
        view.addSubview(label)

        UIView.animate(withDuration: 0.8, animations: {
            label.center = CGPoint(x: center.x, y: center.y - 60)
            label.alpha  = 0
        }) { _ in label.removeFromSuperview() }
    }
}
