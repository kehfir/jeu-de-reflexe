import UIKit

// MARK: - InstructionViewController
// Affiche les règles du jeu avant de commencer
// Concepts CM : struct transmis, UIStackView, NotificationCenter, factory method (switch)

class InstructionViewController: UIViewController {

    private let config: GameConfig

    // Labels mis à jour lors du changement de langue
    private var gameTitleLabel   = UILabel()   // nom du jeu traduit
    private var levelLabel       = UILabel()
    private var instructionLabel = UILabel()
    private var startButton      = UIButton(type: .system)

    init(config: GameConfig) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        // Observer le changement de langue (CM : NotificationCenter.addObserver)
        NotificationCenter.default.addObserver(self,
            selector: #selector(languageChanged),
            name: .languageDidChange, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Mise à jour des textes (CM : @objc, NotificationCenter)
    @objc private func languageChanged() { updateTexts() }

    private func updateTexts() {
        let loc               = AppSettings.shared.loc
        title                 = loc("Instructions", "Instructions")
        gameTitleLabel.text   = config.gameType.displayName
        levelLabel.text       = "  \(loc("Niveau", "Level")) : \(config.level.displayName)  "
        instructionLabel.text = config.instructions
        startButton.setTitle(loc("Tap pour commencer !", "Tap to start!"), for: .normal)
    }

    // MARK: - Interface
    private func setupUI() {

        let imageView = UIImageView(image: UIImage(named: config.gameType.imageName))
        imageView.contentMode = .scaleAspectFit

        gameTitleLabel.font          = UIFont.boldSystemFont(ofSize: 24)
        gameTitleLabel.textAlignment = .center

        levelLabel.font               = UIFont.boldSystemFont(ofSize: 15)
        levelLabel.textColor          = .white
        levelLabel.backgroundColor    = config.levelColor
        levelLabel.layer.cornerRadius = 10
        levelLabel.clipsToBounds      = true
        levelLabel.textAlignment      = .center

        instructionLabel.font          = UIFont.systemFont(ofSize: 16)
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = 0
        instructionLabel.textColor     = .label

        startButton.titleLabel?.font   = UIFont.boldSystemFont(ofSize: 20)
        startButton.backgroundColor    = .systemBlue
        startButton.setTitleColor(.white, for: .normal)
        startButton.layer.cornerRadius = 16
        startButton.clipsToBounds      = true
        startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [
            imageView, gameTitleLabel, levelLabel, instructionLabel, startButton
        ])
        stack.axis      = .vertical
        stack.spacing   = 22
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor,  constant: 28),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            imageView.widthAnchor.constraint(equalToConstant: 90),
            imageView.heightAnchor.constraint(equalToConstant: 90),
            startButton.widthAnchor.constraint(equalToConstant: 260),
            startButton.heightAnchor.constraint(equalToConstant: 56),
        ])

        updateTexts()
    }

    @objc private func startTapped() {
        navigationController?.pushViewController(makeGameViewController(for: config), animated: true)
    }

    private func makeGameViewController(for config: GameConfig) -> UIViewController {
        switch config.gameType {
        case .colorSelector:
            if config.level == .hard {
                let vc = GameViewController()
                vc.level    = .hard
                vc.gameType = .colorSelector
                return vc
            }
            return ColorSelectorViewController(config: config)
        case .swipeGame:   return SwipeGameViewController(config: config)
        case .dontTapRed:  return DontTapRedViewController(config: config)
        }
    }
}
