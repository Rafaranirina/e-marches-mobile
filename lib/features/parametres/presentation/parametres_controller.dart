import 'package:flutter/foundation.dart';

import '../../utilisateurs/data/utilisateur_gestion.dart';
import '../../utilisateurs/data/utilisateur_repository.dart';
import '../data/parametres_repository.dart';

class ParametresController extends ChangeNotifier {
  ParametresController({
    ParametresRepository? repository,
    UtilisateurRepository? utilisateurRepository,
  })  : _repository = repository ?? ParametresRepository(),
        _utilisateurRepository =
            utilisateurRepository ?? UtilisateurRepository();

  final ParametresRepository _repository;
  final UtilisateurRepository _utilisateurRepository;

  UtilisateurGestion? _profil;
  PhotoProfil? _photo;
  Activation2FA? _activation2FA;

  bool _isLoading = false;
  bool _isSavingProfil = false;
  bool _isUploadingPhoto = false;
  bool _isTogglingDeuxFacteurs = false;
  String? _errorMessage;

  UtilisateurGestion? get profil => _profil;

  PhotoProfil? get photo => _photo;

  Activation2FA? get activation2FAEnCours => _activation2FA;

  bool get isLoading => _isLoading;

  bool get isSavingProfil => _isSavingProfil;

  bool get isUploadingPhoto => _isUploadingPhoto;

  bool get isTogglingDeuxFacteurs => _isTogglingDeuxFacteurs;

  String? get errorMessage => _errorMessage;

  bool get hasError => _errorMessage != null;

  Future<void> charger() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profil = await _utilisateurRepository.chargerProfil();
    } on UtilisateurException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Impossible de charger votre profil.';
    }

    try {
      _photo = await _repository.chargerPhotoProfil();
    } catch (_) {
      _photo = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<String?> modifierProfil({
    required String nom,
    String? prenom,
    String? telephone,
  }) async {
    _isSavingProfil = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profil = await _repository.modifierProfil(
        nom: nom,
        prenom: prenom,
        telephone: telephone,
      );

      return 'Profil mis à jour.';
    } on ParametresException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage = 'Impossible de modifier le profil.';
      return null;
    } finally {
      _isSavingProfil = false;
      notifyListeners();
    }
  }

  Future<String?> uploaderPhoto(String cheminFichier) async {
    _isUploadingPhoto = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final message = await _repository.uploaderPhotoProfil(
        cheminFichier: cheminFichier,
      );

      _photo = await _repository.chargerPhotoProfil();

      return message;
    } on ParametresException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage = 'Impossible de téléverser la photo.';
      return null;
    } finally {
      _isUploadingPhoto = false;
      notifyListeners();
    }
  }

  Future<String?> supprimerPhoto() async {
    _isUploadingPhoto = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final message = await _repository.supprimerPhotoProfil();
      _photo = null;

      return message;
    } on ParametresException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage = 'Impossible de supprimer la photo.';
      return null;
    } finally {
      _isUploadingPhoto = false;
      notifyListeners();
    }
  }

  Future<void> demarrerActivation2FA() async {
    _isTogglingDeuxFacteurs = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _activation2FA = await _repository.activer2FA();
    } on ParametresException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible d’activer la double authentification.';
    } finally {
      _isTogglingDeuxFacteurs = false;
      notifyListeners();
    }
  }

  void annulerActivation2FA() {
    _activation2FA = null;
    notifyListeners();
  }

  Future<String?> confirmerActivation2FA(String code) async {
    _isTogglingDeuxFacteurs = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final message = await _repository.verifier2FA(code: code);

      _activation2FA = null;
      await charger();

      return message;
    } on ParametresException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage = 'Le code saisi est invalide.';
      return null;
    } finally {
      _isTogglingDeuxFacteurs = false;
      notifyListeners();
    }
  }

  Future<String?> desactiver2FA(String motDePasse) async {
    _isTogglingDeuxFacteurs = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final message =
          await _repository.desactiver2FA(motDePasse: motDePasse);

      await charger();

      return message;
    } on ParametresException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Impossible de désactiver la double authentification.';
      return null;
    } finally {
      _isTogglingDeuxFacteurs = false;
      notifyListeners();
    }
  }

  void effacerErreur() {
    _errorMessage = null;
    notifyListeners();
  }
}
