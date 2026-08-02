import 'package:flutter/foundation.dart';

import '../data/auth_repository.dart';
import '../data/auth_user.dart';
import '../data/login_result.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    AuthRepository? repository,
  }) : _repository = repository ?? AuthRepository();

  final AuthRepository _repository;

  AuthUser? _utilisateur;
  bool _isLoading = false;
  String? _errorMessage;
  String? _utilisateurDeuxFacteursId;

  AuthUser? get utilisateur => _utilisateur;

  bool get isLoading => _isLoading;

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
    notifyListeners();

    final result = await _repository.login(
      email: email,
      motDePasse: motDePasse,
    );

    if (result.isSuccess) {
      _utilisateur = result.utilisateur;
    } else if (result.requiresTwoFactor) {
      _utilisateurDeuxFacteursId = result.utilisateurId;
    } else {
      _errorMessage = result.message;
    }

    _isLoading = false;
    notifyListeners();

    return result;
  }

  Future<void> logout() async {
    await _repository.logout();

    _utilisateur = null;
    _errorMessage = null;
    _utilisateurDeuxFacteursId = null;

    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}