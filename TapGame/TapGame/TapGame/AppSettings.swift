import UIKit
import AudioToolbox

// MARK: - AppSettings
// Singleton gérant les préférences globales de l'application
// Concepts CM : Singleton (init privé), UserDefaults (persistance), computed properties

class AppSettings {

    // MARK: - Singleton (CM : patron Singleton — une seule instance partagée)
    static let shared = AppSettings()
    private init() {
        // Valeur par défaut : son activé
        if UserDefaults.standard.object(forKey: "soundEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "soundEnabled")
        }
    }

    // MARK: - Langue (CM : UserDefaults, computed property avec get/set)
    var language: String {
        get { UserDefaults.standard.string(forKey: "language") ?? "fr" }
        set { UserDefaults.standard.set(newValue, forKey: "language") }
    }

    // MARK: - Son activé / désactivé
    var isSoundEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "soundEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "soundEnabled") }
    }

    // MARK: - Variante son de défaite
    var useLoseSoundVariant: Bool {
        get { UserDefaults.standard.bool(forKey: "loseSoundVariant") }
        set { UserDefaults.standard.set(newValue, forKey: "loseSoundVariant") }
    }

    // MARK: - Sons système (CM : AudioToolbox, guard)
    func playWin() {
        guard isSoundEnabled else { return }
        AudioServicesPlaySystemSound(1025)   // son de succès
    }

    func playLose() {
        guard isSoundEnabled else { return }
        // Si variante activée : vibration + son différent (CM : ternaire)
        let soundID: SystemSoundID = useLoseSoundVariant ? 1073 : 1053
        AudioServicesPlaySystemSound(soundID)
    }

    func playTap() {
        guard isSoundEnabled else { return }
        AudioServicesPlaySystemSound(1104)   // son de tap léger
    }

    // MARK: - Localisation simple (CM : ternaire, String)
    // Retourne le texte en français ou en anglais selon la langue choisie
    func loc(_ fr: String, _ en: String) -> String {
        return language == "fr" ? fr : en
    }
}

// MARK: - Notification (CM : NotificationCenter, Notification.Name)
// Diffusée à chaque changement de langue pour que tous les VCs se mettent à jour
extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}
