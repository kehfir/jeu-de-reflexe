import UIKit

// MARK: - GameListViewController
// Liste des jeux avec leurs modes, organisée en sections
// Concepts CM : UITableView avec sections, protocoles DataSource & Delegate,
//               @IBOutlet, enum CaseIterable, Array, extension,
//               UITableViewHeaderFooterView, UIImage(named:), UIImageView

class GameListViewController: UIViewController {

    private let games:  [GameType]  = GameType.allCases
    private let levels: [GameLevel] = [.easy, .medium, .hard]

    // MARK: - IBOutlet (CM : @IBOutlet — UITableView connectée depuis Main.storyboard)
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupTableView()
        // Observer changement de langue (CM : NotificationCenter.addObserver)
        NotificationCenter.default.addObserver(self,
            selector: #selector(languageChanged),
            name: .languageDidChange, object: nil)
        updateTitle()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    @objc private func languageChanged() {
        updateTitle()
        tableView.reloadData()
    }

    private func updateTitle() {
        title = AppSettings.shared.loc("Choisir un Jeu", "Choose a Game")
    }

    // MARK: - Configuration du UITableView (CM : DataSource, Delegate, register)
    // La UITableView vient du Storyboard via @IBOutlet — on configure seulement le comportement
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(UITableViewCell.self,       forCellReuseIdentifier: "ModeCell")
        tableView.register(GameSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: "GameHeader")
        tableView.rowHeight           = 72
        tableView.sectionHeaderHeight = 64
    }
}

// MARK: - En-tête de section personnalisé avec image (CM : UITableViewHeaderFooterView, UIImageView)
class GameSectionHeaderView: UITableViewHeaderFooterView {

    private let gameImageView = UIImageView()
    private let titleLabel    = UILabel()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupView()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        gameImageView.contentMode  = .scaleAspectFit
        gameImageView.clipsToBounds = true
        gameImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(gameImageView)

        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            gameImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            gameImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            gameImageView.widthAnchor.constraint(equalToConstant: 38),
            gameImageView.heightAnchor.constraint(equalToConstant: 38),

            titleLabel.leadingAnchor.constraint(equalTo: gameImageView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
    }

    func configure(with game: GameType) {
        gameImageView.image = UIImage(named: game.imageName)
        titleLabel.text     = game.displayName
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate (CM : extension, protocoles)
extension GameListViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { games.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { levels.count }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: "GameHeader"
        ) as? GameSectionHeaderView
        header?.configure(with: games[section])
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 64 }

    // Cellule : niveau + description (CM : cellForRowAt, defaultContentConfiguration)
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell   = tableView.dequeueReusableCell(withIdentifier: "ModeCell", for: indexPath)
        let game   = games[indexPath.section]
        let level  = levels[indexPath.row]
        let config = GameConfig(gameType: game, level: level)

        var content = cell.defaultContentConfiguration()
        content.text          = level.displayName
        content.secondaryText = config.shortDescription
        content.textProperties.font          = UIFont.boldSystemFont(ofSize: 16)
        content.secondaryTextProperties.font  = UIFont.systemFont(ofSize: 12)
        content.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    // Sélection → navigation vers les instructions (CM : pushViewController)
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let config = GameConfig(gameType: games[indexPath.section], level: levels[indexPath.row])
        let instructionVC = InstructionViewController(config: config)
        navigationController?.pushViewController(instructionVC, animated: true)
    }
}
