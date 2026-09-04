import '../../../shared/presentation/safe_change_notifier.dart';

import '../../utilisateurs/data/utilisateur_repository.dart';
import '../data/auth_repository.dart';
import '../data/auth_user.dart';
import '../data/login_result.dart';

export '../data/auth_repository.dart' show AuthActionResult;

class AuthController extends SafeChangeNotifier {
  AuthController({
    AuthRepository? repository,
  }) : _repository = repository ?? AuthRepository();

  final AuthRepository _repository;

  AuthUser? _utilisateur;
  bool _isLoading = false;
  // Démarre à `true` (plutôt que d'être mis à `true` puis notifié depuis
  // restaurerSession()) pour que le tout premier build affiche déjà l'état
  // de chargement sans notification synchrone pendant initState — voir
  // restaurerSession() et le postFrameCallback dans main.dart.
  bool _isRestoring = true;
  String? _errorMessage;
  String? _utilisateurDeuxFacteursId;
  String? _challenge2fa;

  AuthUser? get utilisateur => _utilisateur;

  bool get isLoading => _isLoading;

  /// `true` pendant la vérification du token stocké au démarrage de l'app
  /// (voir [restaurerSession]) — permet d'afficher un écran de chargement
  /// plutôt que de basculer prématurément sur l'écran de connexion.
  bool get isRestoring => _isRestoring;

  String? get errorMessage => _errorMessage;

  String? get utilisateurDeuxFacteursId => _utilisateurDeuxFacteursId;

  bool get isAuthenticated => _utilisateur != null;

  Future<LoginResult> login({
    required String email,
    required String motDePasse,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _utilisateurDeuxFacteursId = null;
    _challenge2fa = null;
    notifyListeners();

    final result = await _repository.login(
      email: email,
      motDePasse: motDePasse,
    );

    if (result.isSuccess) {
      _utilisateur = result.utilisateur;
    } else if (result.requiresTwoFactor) {
      _utilisateurDeuxFacteursId = result.utilisateurId;
      _challenge2fa = result.challenge2fa;
    } else {
      _errorMessage = result.message;
    }

    _isLoading = false;
    notifyListeners();

    return result;
  }

  /// Deuxième étape du flux 2FA : valide le code à 6 chiffres avec le
  /// challenge reçu par [login] lorsque `statut == '2fa_requis'`.
  Future<LoginResult> validerDeuxFacteurs({
    required String code,
  }) async {
    final challenge = _challenge2fa;

    if (challenge == null || challenge.isEmpty) {
      return const LoginResult(
        statut: 'erreur',
        message:
            'Le défi de double authentification a expiré. Reconnectez-vous.',
      );
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.validerCode2FA(
      challenge2fa: challenge,
      code: code,
    );

    if (result.isSuccess) {
      _utilisateur = result.utilisateur;
      _utilisateurDeuxFacteursId = null;
      _challenge2fa = null;
    } else {
      _errorMessage = result.message;
    }

    _isLoading = false;
    notifyListeners();

    return result;
  }

  /// Annule un flux de double authentification en cours (ex. l'utilisateur
  /// revient à l'écran de connexion depuis l'écran de vérification du code)
  /// pour éviter qu'un challenge périmé reste en mémoire.
  void annulerDeuxFacteurs() {
    _utilisateurDeuxFacteursId = null;
    _challenge2fa = null;
    notifyListeners();
  }

  Future<String> demanderReinitialisationMotDePasse({
    required String email,
  }) async {
    _isLoading = true;
    notifyListeners();

    final message = await _repository.demanderReinitialisation(
      email: email,
    );

    _isLoading = false;
    notifyListeners();

    return message;
  }

  Future<AuthActionResult> reinitialiserMotDePasse({
    required String token,
    required String nouveauMotDePasse,
  }) async {
    _isLoading = true;
    notifyListeners();

    final resultat = await _repository.reinitialiserMotDePasse(
      token: token,
      nouveauMotDePasse: nouveauMotDePasse,
    );

    _isLoading = false;
    notifyListeners();

    return resultat;
  }

  /// À appeler une fois au démarrage de l'app : si un token est encore
  /// stocké, revalide la session auprès du serveur pour éviter de forcer
  /// une reconnexion alors que le token est toujours valide.
  Future<void> restaurerSession() async {
    try {
      _utilisateur =
          await _repository.restaurerUtilisateurConnecte();
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repository.logout();

    UtilisateurRepository.invaliderProfilEnCache();

    _utilisateur = null;
    _errorMessage = null;
    _utilisateurDeuxFacteursId = null;
    _challenge2fa = null;

    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
