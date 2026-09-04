import '../../../shared/presentation/safe_change_notifier.dart';

import '../data/soumission_repository.dart';

class SoumissionFormController extends SafeChangeNotifier {
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
    required String appelOffreId,
    required double? montantPropose,
    String? delaiExecution,
  }) async {
    _errorMessage = null;

    final erreurValidation = _valider(
      appelOffreId: appelOffreId,
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
        appelOffreId: appelOffreId,
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
    required String appelOffreId,
    required double? montantPropose,
  }) {
    if (appelOffreId.trim().isEmpty) {
      return 'L’appel d’offres est invalide.';
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
