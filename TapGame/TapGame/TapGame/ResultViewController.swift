import UIKit

// MARK: - ResultViewController
// Écran de résultat — affiché après chaque partie
// Concepts CM : propriétés, UIStackView, NotificationCenter, NSAttributedString, @objc

class ResultViewController: UIViewController {

    private let score:  Int
    private let config: GameConfig
    private let didWin: Bool

    // Labels mis à jour lors du changement de langue
    private let emojiLabel   = UILabel()
    private let titleLabel   = UILabel()
    private let levelLabel   = UILabel()
    private let scoreLabel   = UILabel()
    private let replayButton = UIButton(type: .system)
    private let menuButton   = UIButton(type: .system)

    init(score: Int, config: GameConfig, didWin: Bool) {
        self.score  = score
        self.config = config
        self.didWin = didWin
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.hidesBackButton = true
        setupUI()
        // Observer changement de langue (CM : NotificationCenter)
        NotificationCenter.default.addObserver(self,
            selector: #selector(languageChanged),
            name: .languageDidChange, object: nil)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    @objc private func languageChanged() { updateTexts() }

    private func updateTexts() {
        let loc = AppSettings.shared.loc
        title           = loc("Résultats", "Results")
        levelLabel.text = "\(config.gameType.emoji)  \(config.gameType.rawValue)\n\(loc("Niveau", "Level")) : \(config.level.rawValue)"
        titleLabel.text = didWin ? loc("Bravo ! Gagné !", "Well done! You won!") : loc("Dommage… Perdu !", "Too bad... Game over!")
        replayButton.setTitle(loc("Rejouer", "Play again"), for: .normal)
        menuButton.setTitle(loc("Menu principal", "Main menu"), for: .normal)
    }

    private func setupUI() {

        emojiLabel.font          = UIFont.systemFont(ofSize: 72)
        emojiLabel.textAlignment = .center

        titleLabel.font          = UIFont.boldSystemFont(ofSize: 28)
        titleLabel.textAlignment = .center
        titleLabel.textColor     = didWin ? .systemGreen : .systemRed

        levelLabel.font          = UIFont.systemFont(ofSize: 16)
        levelLabel.textAlignment = .center
        levelLabel.textColor     = .secondaryLabel
        levelLabel.numberOfLines = 2

        // Score avec NSAttributedString (CM : NSAttributedString)
        let scoreAttr = NSMutableAttributedString(
            string: "\(score)",
            attributes: [.font: UIFont.boldSystemFont(ofSize: 64), .foregroundColor: UIColor.systemBlue]
        )
        scoreAttr.append(NSAttributedString(
            string: " pts",
            attributes: [.font: UIFont.systemFont(ofSize: 28), .foregroundColor: UIColor.secondaryLabel]
        ))
        scoreLabel.attributedText = scoreAttr
        scoreLabel.textAlignment  = .center

        replayButton.titleLabel?.font   = UIFont.boldSystemFont(ofSize: 20)
        replayButton.backgroundColor    = .systemBlue
        replayButton.setTitleColor(.white, for: .normal)
        replayButton.layer.cornerRadius = 16
        replayButton.clipsToBounds      = true
        replayButton.addTarget(self, action: #selector(replayTapped), for: .touchUpInside)

        menuButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        menuButton.setTitleColor(.systemGray, for: .normal)
        menuButton.addTarget(self, action: #selector(menuTapped), for: .touchUpInside)

        // Emoji selon résultat (CM : if/else if)
        if didWin {
            emojiLabel.text = score >= 80 ? "🏆" : score >= 40 ? "🎉" : "👍"
        } else {
            emojiLabel.text = "💪"
        }

        let stack = UIStackView(arrangedSubviews: [
            emojiLabel, titleLabel, levelLabel, scoreLabel, replayButton, menuButton
        ])
        stack.axis      = .vertical
        stack.spacing   = 20
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor,  constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            replayButton.widthAnchor.constraint(equalToConstant: 210),
            replayButton.heightAnchor.constraint(equalToConstant: 54),
        ])

        updateTexts()
    }

    @objc private func replayTapped() {
        guard let nav = navigationController else { return }
        let stack = nav.viewControllers
        if stack.count >= 3 {
            nav.popToViewController(stack[stack.count - 3], animated: true)
        } else {
            nav.popToRootViewController(animated: true)
        }
    }

    @objc private func menuTapped() {
        navigationController?.popToRootViewController(animated: true)
    }
}
