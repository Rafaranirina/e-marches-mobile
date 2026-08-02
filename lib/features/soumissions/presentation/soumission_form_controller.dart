import 'package:flutter/foundation.dart';

import '../data/soumission_repository.dart';

class SoumissionFormController extends ChangeNotifier {
  SoumissionFormController({
    SoumissionRepository? repository,
  }) : _repository = repository ?? SoumissionRepository();

  final SoumissionRepository _repository;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get isSubmitting => _isSubmitting;

  String? get errorMessage => _errorMessage;

  bool get hasError => _errorMessage != null;

  Future<SoumissionActionResult?> deposer({
    required String reference,
    required String appelOffreId,
    required String entrepriseId,
    required double? montantPropose,
    String? delaiExecution,
  }) async {
    _errorMessage = null;

    final erreurValidation = _valider(
      reference: reference,
      appelOffreId: appelOffreId,
      entrepriseId: entrepriseId,
      montantPropose: montantPropose,
    );

    if (erreurValidation != null) {
      _errorMessage = erreurValidation;
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      return await _repository.deposer(
        reference: reference,
        appelOffreId: appelOffreId,
        entrepriseId: entrepriseId,
        montantPropose: montantPropose!,
        delaiExecution: delaiExecution,
      );
    } on SoumissionException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Une erreur inattendue est survenue pendant le dépôt.';
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  String? _valider({
    required String reference,
    required String appelOffreId,
    required String entrepriseId,
    required double? montantPropose,
  }) {
    if (reference.trim().isEmpty) {
      return 'La référence de la soumission est obligatoire.';
    }

    if (appelOffreId.trim().isEmpty) {
      return 'L’appel d’offres est invalide.';
    }

    if (entrepriseId.trim().isEmpty) {
      return 'Aucune entreprise n’est associée à ce compte fournisseur.';
    }

    if (montantPropose == null) {
      return 'Le montant proposé est obligatoire.';
    }

    if (montantPropose <= 0) {
      return 'Le montant proposé doit être supérieur à zéro.';
    }

    return null;
  }

  void effacerErreur() {
    _errorMessage = null;
    notifyListeners();
  }
}