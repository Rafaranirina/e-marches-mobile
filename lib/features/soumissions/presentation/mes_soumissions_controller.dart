import '../../../shared/presentation/safe_change_notifier.dart';

import '../data/soumission.dart';
import '../data/soumission_repository.dart';

class MesSoumissionsController extends SafeChangeNotifier {
  MesSoumissionsController({
    SoumissionRepository? repository,
  }) : _repository = repository ?? SoumissionRepository();

  final SoumissionRepository _repository;

  List<Soumission> _soumissions = [];
  final Set<String> _actionsEnCours = {};

  bool _isLoading = false;
  String? _errorMessage;

  List<Soumission> get soumissions =>
      List.unmodifiable(_soumissions);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get hasError => _errorMessage != null;

  int get nombreTotal => _soumissions.length;

  bool actionEnCours(String soumissionId) {
    return _actionsEnCours.contains(soumissionId);
  }

  Future<void> charger() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _soumissions =
          await _repository.listerMesSoumissions();
    } on SoumissionException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible de charger vos soumissions.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> actualiser() async {
    try {
      _errorMessage = null;

      _soumissions =
          await _repository.listerMesSoumissions();
    } on SoumissionException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible d’actualiser vos soumissions.';
    } finally {
      notifyListeners();
    }
  }

  Future<SoumissionActionResult?> modifierBrouillon({
    required String soumissionId,
    double? montantPropose,
    String? delaiExecution,
  }) async {
    if (_actionsEnCours.contains(soumissionId)) {
      return null;
    }

    _actionsEnCours.add(soumissionId);
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat = await _repository.modifierBrouillon(
        soumissionId: soumissionId,
        montantPropose: montantPropose,
        delaiExecution: delaiExecution,
      );

      await actualiser();

      return resultat;
    } on SoumissionException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Impossible de modifier la soumission.';
      return null;
    } finally {
      _actionsEnCours.remove(soumissionId);
      notifyListeners();
    }
  }

  Future<TransmissionResult?> transmettre({
    required String soumissionId,
  }) async {
    if (_actionsEnCours.contains(soumissionId)) {
      return null;
    }

    _actionsEnCours.add(soumissionId);
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat = await _repository.transmettre(
        soumissionId: soumissionId,
      );

      await actualiser();

      return resultat;
    } on SoumissionException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Impossible de transmettre la soumission.';
      return null;
    } finally {
      _actionsEnCours.remove(soumissionId);
      notifyListeners();
    }
  }

  void effacerErreur() {
    _errorMessage = null;
    notifyListeners();
  }
}
