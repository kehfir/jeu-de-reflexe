import UIKit

// MARK: - HomeViewController
// Écran d'accueil — premier écran affiché au lancement
//
// Concepts CM :
//   • UIViewController lifecycle (viewDidLoad, viewWillAppear, viewWillDisappear)
//   • @IBOutlet — connexions Storyboard → code
//   • @IBAction  — actions bouton depuis le Storyboard
//   • Singleton (AppSettings), NotificationCenter
//   • UINavigationController (setNavigationBarHidden)
//   • UITabBarController (selectedIndex)
//   • UIStoryboard (instantiateViewController)

class HomeViewController: UIViewController {

    // MARK: - IBOutlets (CM : @IBOutlet — connectés dans Main.storyboard)
    @IBOutlet weak var titleLabel:     UILabel!
    @IBOutlet weak var subtitleLabel:  UILabel!
    @IBOutlet weak var logoImageView:  UIImageView!
    @IBOutlet weak var playButton:     UIButton!
    @IBOutlet weak var settingsButton: UIButton!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        styleUI()
        // Observer le changement de langue (CM : NotificationCenter.addObserver)
        NotificationCenter.default.addObserver(self,
            selector: #selector(languageChanged),
            name: .languageDidChange,
            object: nil)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    @objc private func languageChanged() { updateTexts() }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Cacher la barre de navigation sur l'écran d'accueil (CM : UINavigationController)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        updateTexts()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Style (propriétés impossibles à définir dans le Storyboard)
    // CM : CALayer, cornerRadius, UIImage.SymbolConfiguration
    private func styleUI() {
        // Bouton Jouer
        playButton.backgroundColor    = .systemBlue
        playButton.setTitleColor(.white, for: .normal)
        playButton.titleLabel?.font   = UIFont.boldSystemFont(ofSize: 24)
        playButton.layer.cornerRadius = 18
        playButton.clipsToBounds      = true

        // Bouton paramètres avec icône SF Symbol (CM : UIImage(systemName:))
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        settingsButton.setImage(
            UIImage(systemName: "gearshape.fill", withConfiguration: config),
            for: .normal
        )
        settingsButton.tintColor = .systemGray
    }

    // MARK: - Mise à jour des textes (FR / EN) (CM : Singleton AppSettings)
    private func updateTexts() {
        titleLabel.text    = "TapGame"
        subtitleLabel.text = AppSettings.shared.loc("Jeu de Réflexion", "Reflex Game")
        playButton.setTitle(AppSettings.shared.loc("Jouer !", "Play !"), for: .normal)
    }

    // MARK: - IBActions (CM : @IBAction — déclenchés par le Storyboard)

    // Naviguer vers l'onglet Jeux (CM : UITabBarController.selectedIndex)
    @IBAction func playTapped(_ sender: UIButton) {
        tabBarController?.selectedIndex = 1
    }

    // Ouvrir les paramètres en modal (CM : UIStoryboard.instantiateViewController, present)
    @IBAction func settingsTapped(_ sender: UIButton) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard let settingsVC = sb.instantiateViewController(
            withIdentifier: "SettingsVC"
        ) as? SettingsViewController else { return }
        let nav = UINavigationController(rootViewController: settingsVC)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }
}
