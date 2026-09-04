import '../../../shared/presentation/safe_change_notifier.dart';

import '../data/soumission.dart';
import '../data/soumission_repository.dart';

class SoumissionController extends SafeChangeNotifier {
  SoumissionController({
    required this.appelOffreId,
    SoumissionRepository? repository,
  }) : _repository = repository ?? SoumissionRepository();

  final String appelOffreId;
  final SoumissionRepository _repository;

  List<Soumission> _soumissions = [];
  final Set<String> _validationsEnCours = {};

  bool _isLoading = false;
  String? _errorMessage;

  List<Soumission> get soumissions =>
      List.unmodifiable(_soumissions);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get hasError => _errorMessage != null;

  int get nombreTotal => _soumissions.length;

  bool validationEnCours(String soumissionId) {
    return _validationsEnCours.contains(soumissionId);
  }

  Future<void> charger() async {
    if (appelOffreId.trim().isEmpty) {
      _errorMessage =
          'L’identifiant de l’appel d’offres est invalide.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _soumissions =
          await _repository.listerParAppelOffre(
        appelOffreId,
      );
    } on SoumissionException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible de charger les soumissions.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> actualiser() async {
    try {
      _errorMessage = null;

      _soumissions =
          await _repository.listerParAppelOffre(
        appelOffreId,
      );
    } on SoumissionException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible d’actualiser les soumissions.';
    } finally {
      notifyListeners();
    }
  }

  Future<SoumissionActionResult?> valider({
    required String soumissionId,
    required String statut,
  }) async {
    if (_validationsEnCours.contains(soumissionId)) {
      return null;
    }

    _validationsEnCours.add(soumissionId);
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat = await _repository.valider(
        soumissionId: soumissionId,
        statut: statut,
      );

      _soumissions =
          await _repository.listerParAppelOffre(
        appelOffreId,
      );

      return resultat;
    } on SoumissionException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Impossible de mettre à jour la soumission.';
      return null;
    } finally {
      _validationsEnCours.remove(soumissionId);
      notifyListeners();
    }
  }

  void effacerErreur() {
    _errorMessage = null;
    notifyListeners();
  }
}