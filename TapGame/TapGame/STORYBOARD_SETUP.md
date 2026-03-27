# Guide de configuration du Storyboard — TapGame

## Étape 1 : Créer le projet Xcode

1. Ouvrir Xcode → **File > New > Project**
2. Choisir **iOS > App**
3. Remplir :
   - Product Name : `TapGame`
   - Interface : **Storyboard**
   - Language : **Swift**
   - Minimum Deployments : iOS 16
4. **Create** (choisir le dossier `Final/`)

---

## Étape 2 : Ajouter les fichiers Swift

1. Dans le navigateur de projet, **supprimer `ViewController.swift`** (Move to Trash)
2. Clic droit sur le groupe `TapGame` → **Add Files to "TapGame"...**
3. Sélectionner les 5 fichiers du dossier `TapGame/` :
   - `GameLevel.swift`
   - `CircleView.swift`
   - `MenuViewController.swift`
   - `GameViewController.swift`
   - `ScoreViewController.swift`
4. Cocher **Copy items if needed** → **Add**

---

## Étape 3 : Configurer Main.storyboard

Ouvrir `Main.storyboard`.

### 3a — Supprimer la scène par défaut
- Sélectionner le ViewController existant → **Supprimer** (touche Delete)

### 3b — Ajouter un UINavigationController
- Appuyer sur **⌘⇧L** pour ouvrir la bibliothèque d'objets
- Glisser un **Navigation Controller** sur le canvas
- Dans l'**Attributes Inspector** (panneau droit) : cocher **"Is Initial View Controller"**
- Supprimer le **Root View Controller** (Table View Controller) généré automatiquement

### 3c — Ajouter la scène MenuViewController
- Glisser un **View Controller** (pas Table View) depuis la bibliothèque
- Dans l'**Identity Inspector** (icône ID) :
  - Class : `MenuViewController`
  - Storyboard ID : `MenuViewController`
- **Connecter le Navigation Controller** au MenuViewController :
  - Control-drag depuis le Navigation Controller vers le MenuViewController
  - Choisir **"root view controller"**

### 3d — Interface de MenuViewController
Dans la scène MenuViewController, ajouter :
1. Un **Label** centré en haut → texte : `TapGame 🎯` (font Bold, taille 36)
2. Trois **Buttons** empilés verticalement :
   - Bouton 1 : texte `Facile` (Type: Custom, hauteur ~80)
   - Bouton 2 : texte `Moyen`  (Type: Custom, hauteur ~80)
   - Bouton 3 : texte `Difficile` (Type: Custom, hauteur ~80)

> Note : Les couleurs et styles sont appliqués par code dans `viewDidLoad`

Connecter les boutons (Control-drag vers le fichier MenuViewController.swift) :
| Bouton | IBOutlet | IBAction |
|--------|----------|---------|
| Facile | `easyButton` | `easyTapped` |
| Moyen | `mediumButton` | `mediumTapped` |
| Difficile | `hardButton` | `hardTapped` |

### 3e — Ajouter la scène GameViewController
- Glisser un nouveau **View Controller**
- Identity Inspector :
  - Class : `GameViewController`
  - Storyboard ID : `GameViewController`
- **Créer la segue** Menu → Game :
  - Control-drag depuis l'**icône jaune** (en haut de la scène MenuViewController)
  - Vers la scène GameViewController
  - Choisir : **Show**
  - Dans l'Attributes Inspector de la segue : Identifier = `toGame`

### 3f — Ajouter la scène ScoreViewController
- Glisser un nouveau **View Controller**
- Identity Inspector :
  - Class : `ScoreViewController`
  - Storyboard ID : `ScoreViewController`
- **Créer la segue** Game → Score :
  - Control-drag depuis l'**icône jaune** de GameViewController
  - Vers ScoreViewController
  - Choisir : **Show**
  - Identifier = `toScore`

---

## Étape 4 : Build & Run

1. Sélectionner un simulateur iPhone (ex. iPhone 15)
2. **⌘R** pour compiler et lancer
3. Tester les 3 niveaux

---

## Schéma de navigation

```
UINavigationController
       │
       ├─ (root) MenuViewController
       │         ↓ segue "toGame"
       ├─ GameViewController
       │         ↓ segue "toScore"
       └─ ScoreViewController
               [Rejouer] → setViewControllers (remplace la pile)
               [Menu]    → popToRootViewController
```

---

## Résumé des concepts du cours utilisés

| Concept CM | Où |
|---|---|
| UIViewController | MenuVC, GameVC, ScoreVC |
| IBOutlet / IBAction | MenuViewController (boutons) |
| UINavigationController | Architecture complète |
| Segue + prepare(for:sender:) | Menu→Jeu (niveau), Jeu→Score (score+niveau) |
| Classes et héritage | CircleView : UIButton |
| Propriétés stockées & calculées | score (didSet), gameAreaTop |
| Optionnels (Timer?) | spawnTimer, countdownTimer, moveTimer |
| Tableaux | circles[], comboCircles[] |
| Enum | GameLevel |
| Switch | configureForLevel(), circleTapped |
| Closures [weak self] | Tous les Timers |
| UIView.animate | Apparition/disparition des cercles |
| randomElement(), random(in:) | Positions et couleurs aléatoires |
