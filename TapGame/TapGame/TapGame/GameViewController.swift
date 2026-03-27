import UIKit

// MARK: - GameViewController
// Contrôleur du jeu "cercles mobiles" — utilisé pour le mode Difficile du Sélecteur de Couleur
// Concepts CM utilisés :
//   • UIViewController (viewDidLoad, viewDidAppear, viewWillDisappear)
//   • Classes, propriétés stockées et calculées
//   • Tableaux (circles, comboCircles)
//   • Optionnels (Timer?)
//   • Control flow (switch, if/else, guard)
//   • Fonctions, closures ([weak self])
//   • Navigation programmatique → ResultViewController
//   • UIView.animate — animation UIKit standard

class GameViewController: UIViewController {

    // MARK: - Propriétés publiques (transmises depuis InstructionViewController)
    var level:    GameLevel = .easy
    var gameType: GameType  = .colorSelector   // pour ResultViewController

    // MARK: - Labels UI
    private let scoreLabel   = UILabel()
    private let timerLabel   = UILabel()
    private let messageLabel = UILabel()

    // MARK: - État du jeu (CM : didSet computed property)
    private var score: Int = 0 {
        didSet { scoreLabel.text = "Score : \(score)" }
    }
    private var timeRemaining: Int = 0

    // Tableau des cercles actifs (CM : Array)
    private var circles: [CircleView] = []

    // MARK: - Timers (CM : optionnels)
    private var spawnTimer:     Timer?
    private var countdownTimer: Timer?
    private var moveTimer:      Timer?

    // MARK: - Configuration par niveau
    private var maxCircles:     Int          = 1
    private var spawnInterval:  TimeInterval = 2.5
    private var circleLifetime: TimeInterval = 4.0
    private let circleSize:     CGFloat      = 70

    // MARK: - Combo challenge (niveau Difficile)
    private var consecutiveGoodTaps: Int  = 0
    private var isInComboChallenge:  Bool = false
    private var comboCircles:     [CircleView] = []
    private var comboNextExpected: Int    = 1

    private var gameAreaTop: CGFloat {
        view.safeAreaInsets.top + 80
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = level.rawValue
        setupLabels()
        configureForLevel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startGame()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAllTimers()
    }

    // MARK: - Interface
    private func setupLabels() {
        scoreLabel.font = UIFont.boldSystemFont(ofSize: 22)
        scoreLabel.text = "Score : 0"
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scoreLabel)

        timerLabel.font          = UIFont.systemFont(ofSize: 20)
        timerLabel.textAlignment = .right
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timerLabel)

        messageLabel.font          = UIFont.italicSystemFont(ofSize: 14)
        messageLabel.textAlignment = .center
        messageLabel.textColor     = .secondaryLabel
        messageLabel.numberOfLines = 2
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            scoreLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            scoreLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            timerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            timerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            timerLabel.leadingAnchor.constraint(equalTo: scoreLabel.trailingAnchor, constant: 8),
            messageLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 4),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
    }

    // MARK: - Configuration par niveau (CM : switch)
    private func configureForLevel() {
        switch level {
        case .easy:
            maxCircles = 1; spawnInterval = 2.5; circleLifetime = 4.0
            timerLabel.isHidden = true
            messageLabel.text = "Touchez le cercle !"
        case .medium:
            maxCircles = 3; spawnInterval = 1.5; circleLifetime = 2.5
            timeRemaining = 60
            timerLabel.text   = "⏱ 60s"
            messageLabel.text = "Vite ! Touchez les cercles !"
        case .hard:
            maxCircles = 5; spawnInterval = 1.0; circleLifetime = 2.0
            timeRemaining = 45
            timerLabel.text   = "⏱ 45s"
            messageLabel.text = "Verts = +10  |  Rouges = −5  |  Combo ×5 = +30"
        }
    }

    // MARK: - Démarrage
    private func startGame() {
        score = 0
        consecutiveGoodTaps = 0

        spawnTimer = Timer.scheduledTimer(withTimeInterval: spawnInterval, repeats: true) { [weak self] _ in
            self?.spawnCircle()
        }
        if level != .easy {
            countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.tickCountdown()
            }
        }
        if level == .hard {
            moveTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
                self?.moveCircles()
            }
        }
        spawnCircle()
    }

    private func stopAllTimers() {
        spawnTimer?.invalidate();     spawnTimer = nil
        countdownTimer?.invalidate(); countdownTimer = nil
        moveTimer?.invalidate();      moveTimer = nil
    }

    private func endGame() {
        isInComboChallenge = false
        stopAllTimers()
        circles.forEach { $0.removeFromSuperview() }
        circles.removeAll()
        comboCircles.removeAll()

        // Navigation programmatique — plus de segue Storyboard (CM : UINavigationController.push)
        let config   = GameConfig(gameType: gameType, level: level)
        let resultVC = ResultViewController(score: score, config: config, didWin: true)
        navigationController?.pushViewController(resultVC, animated: true)
    }

    // MARK: - Génération d'un cercle
    private func spawnCircle() {
        guard !isInComboChallenge else { return }
        guard circles.count < maxCircles else { return }

        let size   = circleSize
        let top    = gameAreaTop
        let bottom = view.bounds.height - view.safeAreaInsets.bottom - size
        let right  = view.bounds.width  - size
        guard bottom > top, right > 0 else { return }

        let x = CGFloat.random(in: 0...right)
        let y = CGFloat.random(in: top...bottom)

        let circle = CircleView(frame: CGRect(x: x, y: y, width: size, height: size))
        circle.makeCircular()

        switch level {
        case .easy:
            circle.backgroundColor = .systemBlue
        case .medium:
            let colors: [UIColor] = [.systemBlue, .systemGreen, .systemOrange, .systemPurple, .systemPink]
            circle.backgroundColor = colors.randomElement()!
        case .hard:
            let isObstacle = Int.random(in: 0...3) == 0
            circle.isObstacle      = isObstacle
            circle.backgroundColor = isObstacle ? .systemRed : .systemGreen
            if isObstacle { circle.setTitle("✕", for: .normal) }
            let speed = CGFloat.random(in: 3.5...6.0)
            let angle = CGFloat.random(in: 0...(2 * .pi))
            circle.velocityX = cos(angle) * speed
            circle.velocityY = sin(angle) * speed
        }

        circle.addTarget(self, action: #selector(circleTapped(_:)), for: .touchUpInside)
        circle.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        view.addSubview(circle)
        circles.append(circle)
        UIView.animate(withDuration: 0.2) { circle.transform = .identity }

        Timer.scheduledTimer(withTimeInterval: circleLifetime, repeats: false) { [weak self] _ in
            guard let self = self, self.circles.contains(circle) else { return }
            if !circle.isObstacle { self.consecutiveGoodTaps = 0 }
            self.removeCircle(circle, animated: true)
        }
    }

    // MARK: - Tap sur un cercle
    @objc private func circleTapped(_ sender: CircleView) {
        if sender.comboIndex > 0 { return }
        guard circles.contains(sender) else { return }

        if sender.isObstacle {
            score = max(0, score - 5)
            consecutiveGoodTaps = 0
            showFloatingText("−5", at: sender.center, color: .systemRed)
        } else {
            score += 10
            consecutiveGoodTaps += 1
            showFloatingText("+10", at: sender.center, color: .systemGreen)
            if level == .hard && consecutiveGoodTaps > 0 && consecutiveGoodTaps % 5 == 0 {
                removeCircle(sender, animated: true)
                startComboChallenge()
                return
            }
        }
        removeCircle(sender, animated: true)
    }

    private func removeCircle(_ circle: CircleView, animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.15, animations: {
                circle.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                circle.alpha = 0
            }) { [weak self] _ in
                circle.removeFromSuperview()
                self?.circles.removeAll { $0 === circle }
            }
        } else {
            circle.removeFromSuperview()
            circles.removeAll { $0 === circle }
        }
    }

    // MARK: - Mouvement 60 fps (niveau Difficile)
    private func moveCircles() {
        let bounds = view.bounds
        let topLimit = gameAreaTop
        let botLimit = bounds.height - view.safeAreaInsets.bottom

        for circle in circles {
            var ox = circle.frame.origin.x + circle.velocityX
            var oy = circle.frame.origin.y + circle.velocityY

            if ox < 0 { ox = 0; circle.velocityX = abs(circle.velocityX) }
            else if ox + circle.frame.width > bounds.width {
                ox = bounds.width - circle.frame.width; circle.velocityX = -abs(circle.velocityX)
            }
            if oy < topLimit { oy = topLimit; circle.velocityY = abs(circle.velocityY) }
            else if oy + circle.frame.height > botLimit {
                oy = botLimit - circle.frame.height; circle.velocityY = -abs(circle.velocityY)
            }
            circle.frame.origin = CGPoint(x: ox, y: oy)
        }
    }

    // MARK: - Combo challenge
    private func startComboChallenge() {
        isInComboChallenge = true
        spawnTimer?.invalidate()
        circles.filter { $0.comboIndex == 0 }.forEach { removeCircle($0, animated: true) }
        messageLabel.text      = "MÉMORISEZ L'ORDRE !"
        messageLabel.textColor = .systemOrange
        comboCircles     = []
        comboNextExpected = 1

        // Nombre aléatoire de cercles mémoire : entre 5 et 15 (CM : Int.random)
        let comboCount = Int.random(in: 5...15)
        let allColors: [UIColor] = [.systemBlue, .systemOrange, .systemPurple, .systemCyan, .systemPink, .systemYellow, .systemMint, .systemIndigo, .systemTeal]
        let colors = Array(allColors.shuffled().prefix(comboCount))

        for i in 0..<comboCount {
            let size = circleSize
            let top  = gameAreaTop
            let bottom = view.bounds.height - view.safeAreaInsets.bottom - size
            let right  = view.bounds.width  - size
            var rect = CGRect.zero
            var tries = 0
            repeat {
                let x = CGFloat.random(in: 0...right)
                let y = CGFloat.random(in: top...bottom)
                rect  = CGRect(x: x, y: y, width: size, height: size)
                tries += 1
            } while comboCircles.contains(where: {
                rect.insetBy(dx: -15, dy: -15).intersects($0.frame)
            }) && tries < 30

            let circle = CircleView(frame: rect)
            circle.makeCircular()
            circle.backgroundColor      = colors[i % colors.count]
            circle.comboIndex           = i + 1
            circle.isUserInteractionEnabled = false
            circle.setTitle("\(i + 1)", for: .normal)
            circle.addTarget(self, action: #selector(comboCircleTapped(_:)), for: .touchUpInside)
            view.addSubview(circle)
            circles.append(circle)
            comboCircles.append(circle)
        }

        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            guard let self = self, self.isInComboChallenge else { return }
            self.messageLabel.text = "REPRODUISEZ L'ORDRE !"
            for circle in self.comboCircles {
                circle.setTitle("?", for: .normal)
                circle.isUserInteractionEnabled = true
            }
            Timer.scheduledTimer(withTimeInterval: 6.0, repeats: false) { [weak self] _ in
                guard let self = self, self.isInComboChallenge else { return }
                self.endComboChallenge(success: false)
            }
        }
    }

    @objc private func comboCircleTapped(_ sender: CircleView) {
        guard isInComboChallenge else { return }
        if sender.comboIndex == comboNextExpected {
            sender.backgroundColor = .systemGreen
            sender.setTitle("✓", for: .normal)
            sender.isUserInteractionEnabled = false
            comboNextExpected += 1
            if comboNextExpected > comboCircles.count { endComboChallenge(success: true) }
        } else {
            sender.backgroundColor = .systemRed
            endComboChallenge(success: false)
        }
    }

    private func endComboChallenge(success: Bool) {
        isInComboChallenge = false
        if success {
            score += 30
            showFloatingText("COMBO ! +30", at: view.center, color: .systemYellow)
            messageLabel.text = "Excellent ! Continuez !"
        } else {
            score = max(0, score - 10)
            showFloatingText("Raté ! −10", at: view.center, color: .systemRed)
            messageLabel.text = "Verts = +10  |  Rouges = −5  |  Combo ×5 = +30"
        }
        messageLabel.textColor = .secondaryLabel
        comboCircles.forEach { removeCircle($0, animated: true) }
        comboCircles.removeAll()
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.spawnTimer = Timer.scheduledTimer(withTimeInterval: self.spawnInterval,
                                                   repeats: true) { [weak self] _ in self?.spawnCircle() }
            self.spawnCircle()
        }
    }

    // MARK: - Compte à rebours
    private func tickCountdown() {
        timeRemaining -= 1
        timerLabel.text = "⏱ \(timeRemaining)s"
        if timeRemaining <= 10 { timerLabel.textColor = .systemRed }
        if timeRemaining <= 0  { endGame() }
    }

    // MARK: - Texte flottant animé (CM : UIView.animate)
    private func showFloatingText(_ text: String, at center: CGPoint, color: UIColor) {
        let label = UILabel()
        label.text = text; label.textColor = color
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.sizeToFit(); label.center = center
        view.addSubview(label)
        UIView.animate(withDuration: 0.8, animations: {
            label.center = CGPoint(x: center.x, y: center.y - 70)
            label.alpha  = 0
        }) { _ in label.removeFromSuperview() }
    }
}
