import 'package:flutter/foundation.dart';

import '../../utilisateurs/data/utilisateur_gestion.dart';
import '../../utilisateurs/data/utilisateur_repository.dart';

class ProfilController extends ChangeNotifier {
  ProfilController({
    UtilisateurRepository? repository,
  }) : _repository =
            repository ?? UtilisateurRepository();

  final UtilisateurRepository _repository;

  UtilisateurGestion? _profil;

  bool _isLoading = false;
  bool _isRefreshing = false;

  String? _errorMessage;

  UtilisateurGestion? get profil => _profil;

  bool get isLoading => _isLoading;

  bool get isRefreshing => _isRefreshing;

  bool get isBusy =>
      _isLoading || _isRefreshing;

  String? get errorMessage => _errorMessage;

  bool get hasError =>
      _errorMessage != null &&
      _errorMessage!.trim().isNotEmpty;

  bool get hasProfil => _profil != null;

  Future<void> charger() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profil =
          await _repository.chargerProfil();
    } on UtilisateurException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible de charger votre profil.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> actualiser() async {
    if (_isRefreshing || _isLoading) {
      return;
    }

    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profil =
          await _repository.chargerProfil();
    } on UtilisateurException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible d’actualiser votre profil.';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  void effacerErreur() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }
}