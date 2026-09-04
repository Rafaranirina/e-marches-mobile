# e-Marchés Madagascar — Application mobile

Application mobile Flutter de gestion des marchés publics, consommant la même API backend que le site web (`e-marches-memoire/backend`). Elle couvre l'ensemble du cycle de vie d'un marché public : appels d'offres, soumissions, évaluations, commissions, contrats, ainsi que la gestion des comptes et des administrations/fournisseurs.

## Architecture

Le projet suit une organisation par feature, chaque module possédant sa propre couche `data/` (modèles + repositories Dio) et `presentation/` (controllers `ChangeNotifier` + écrans) :

```
lib/
  core/
    config/       # configuration (URL de l'API)
    network/      # client Dio (ApiClient), intercepteurs (token, 401)
    storage/      # stockage sécurisé du token d'accès
  features/
    auth/                # connexion, 2FA, mot de passe oublié
    parametres/           # profil, photo, double authentification
    dashboard/            # écran d'accueil, navigation par rôle
    appels_offres/        # cycle de vie des appels d'offres
    soumissions/          # dépôt, transmission, suivi des soumissions
    evaluations/          # notation, classement, attribution
    commissions/          # gestion des commissions d'évaluation
    contrats/             # contrats, jalons, paiements
    documents/            # bibliothèque documentaire
    fournisseurs/         # répertoire des entreprises
    administrations/      # répertoire des administrations
    categories/           # catégories de marchés
    utilisateurs/         # gestion des comptes (admin national)
    notifications/        # notifications in-app
    rapports/             # tableau de bord et statistiques
    profil/               # consultation du profil
  shared/
    models/       # modèles partagés entre plusieurs features
    network/      # gestion d'erreur Dio partagée
    widgets/      # widgets réutilisables (chip de statut, etc.)
```

**State management :** Provider (`ChangeNotifier`).
**Réseau :** Dio, avec injection automatique du token `Authorization: Bearer` et déconnexion automatique sur 401.
**Stockage :** `flutter_secure_storage` pour le token d'accès.
**Navigation :** `Navigator.push` / `MaterialPageRoute`.

## Rôles applicatifs

L'app adapte les modules visibles et les actions disponibles selon le rôle du compte connecté :

- `admin_national` — accès complet, gestion des utilisateurs et des référentiels.
- `administration` — gestion des appels d'offres, soumissions, contrats de son administration.
- `fournisseur` — dépôt et suivi de ses propres soumissions.
- `commission` — évaluation des soumissions dans le cadre d'une commission.

## Prérequis

- Flutter SDK (voir `environment.sdk` dans `pubspec.yaml`)
- Le backend `e-marches-memoire/backend` démarré et accessible (voir son propre README pour le lancer)

## Configuration de l'API

L'URL du backend est définie via la variable de compilation `API_BASE_URL` (valeur par défaut : `http://10.0.2.2:5000`, qui correspond à `localhost` depuis un émulateur Android).

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5000
```

Sur un appareil physique ou un simulateur iOS, remplacer par l'adresse IP réelle de la machine hébergeant le backend.

## Lancer le projet

```bash
flutter pub get
flutter run
```

## Vérifications

```bash
flutter analyze   # analyse statique
flutter test      # tests (si présents dans test/)
```

## Notes

- Une fonctionnalité (ajout de membre à une commission) est volontairement désactivée côté mobile : le backend n'expose actuellement aucun endpoint permettant de lister les utilisateurs éligibles à une commission pour les rôles `administration`. Un message explicite est affiché à la place d'une erreur réseau silencieuse (voir les `TODO(backend)` dans `lib/features/commissions/` et `lib/features/evaluations/`).
- La réinitialisation de mot de passe se fait par saisie manuelle du token reçu par e-mail (pas de deep linking configuré).
