import UIKit

// MARK: - SettingsViewController
// Écran de paramètres : langue et sons
// Concepts CM : UITableView (@IBOutlet), UISwitch, Singleton (AppSettings), UserDefaults,
//               enum CaseIterable, extension, protocoles DataSource & Delegate

class SettingsViewController: UIViewController {

    // MARK: - IBOutlet (CM : @IBOutlet — UITableView connectée depuis Main.storyboard)
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Sections (CM : enum CaseIterable, RawRepresentable)
    private enum Section: Int, CaseIterable {
        case language = 0
        case sound    = 1
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = AppSettings.shared.loc("Paramètres", "Settings")
        view.backgroundColor = .systemGroupedBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissSelf)
        )
        setupTableView()
    }

    // MARK: - Configuration du UITableView
    // La UITableView vient du Storyboard via @IBOutlet
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }

    @objc private func dismissSelf() { dismiss(animated: true) }

    @objc private func soundToggled(_ sender: UISwitch) {
        if sender.tag == 0 {
            AppSettings.shared.isSoundEnabled = sender.isOn
        } else {
            AppSettings.shared.useLoseSoundVariant = sender.isOn
        }
        tableView.reloadSections(IndexSet(integer: Section.sound.rawValue), with: .none)
    }
}

// MARK: - UITableViewDataSource & Delegate (CM : extension, protocoles)
extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section) {
        case .language: return AppSettings.shared.loc("🌐  Langue", "🌐  Language")
        case .sound:    return AppSettings.shared.loc("🔊  Sons",   "🔊  Sound")
        default:        return nil
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .language: return 2
        case .sound:    return 2
        default:        return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.selectionStyle = .none
        cell.accessoryView  = nil
        cell.accessoryType  = .none
        var content = cell.defaultContentConfiguration()

        switch Section(rawValue: indexPath.section) {
        case .language:
            let options: [(label: String, code: String)] = [
                (AppSettings.shared.loc("Français", "French"), "fr"),
                (AppSettings.shared.loc("Anglais",  "English"), "en")
            ]
            let opt = options[indexPath.row]
            content.text = opt.label
            cell.accessoryType = AppSettings.shared.language == opt.code ? .checkmark : .none

        case .sound:
            let sw = UISwitch()
            sw.tag = indexPath.row
            sw.addTarget(self, action: #selector(soundToggled(_:)), for: .valueChanged)
            cell.accessoryView = sw
            if indexPath.row == 0 {
                content.text = AppSettings.shared.loc("Sons activés", "Sound enabled")
                sw.isOn = AppSettings.shared.isSoundEnabled
                cell.alpha = 1.0
                cell.isUserInteractionEnabled = true
            } else {
                content.text = AppSettings.shared.loc("Son de défaite différent", "Different lose sound")
                sw.isOn = AppSettings.shared.useLoseSoundVariant
                let enabled = AppSettings.shared.isSoundEnabled
                cell.alpha = enabled ? 1.0 : 0.4
                cell.isUserInteractionEnabled = enabled
            }
        default: break
        }
        cell.contentConfiguration = content
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard Section(rawValue: indexPath.section) == .language else { return }
        let codes = ["fr", "en"]
        AppSettings.shared.language = codes[indexPath.row]
        NotificationCenter.default.post(name: .languageDidChange, object: nil)
        title = AppSettings.shared.loc("Paramètres", "Settings")
        tableView.reloadData()
    }
}
