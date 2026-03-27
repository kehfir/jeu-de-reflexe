import UIKit

// MARK: - SceneDelegate
// Point d'entrée de la scène — charge le UITabBarController depuis Main.storyboard
// Concepts CM : UIStoryboard, UITabBarController, UIWindow, NotificationCenter

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Charger le UITabBarController défini dans Main.storyboard (CM : UIStoryboard)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let tabBar = storyboard.instantiateInitialViewController() as? UITabBarController else { return }

        // Appliquer les titres et icônes selon la langue courante (CM : Singleton AppSettings)
        applyTabTitles(to: tabBar)

        // Observer le changement de langue pour mettre à jour les onglets immédiatement
        // (CM : NotificationCenter.addObserver, closures [weak])
        NotificationCenter.default.addObserver(
            forName: .languageDidChange,
            object: nil,
            queue: .main
        ) { [weak tabBar] _ in
            guard let tabBar = tabBar else { return }
            self.applyTabTitles(to: tabBar)
        }

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = tabBar
        window?.makeKeyAndVisible()
    }

    // MARK: - Titres des onglets selon la langue (CM : Singleton AppSettings)
    // Les icônes sont définies dans Main.storyboard (imageReference systemImageName)
    // On met à jour uniquement les titres pour la traduction FR/EN
    private func applyTabTitles(to tabBar: UITabBarController) {
        let s = AppSettings.shared
        tabBar.viewControllers?[0].tabBarItem.title = s.loc("Accueil", "Home")
        tabBar.viewControllers?[1].tabBarItem.title = s.loc("Jeux",    "Games")
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}
