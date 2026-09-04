import '../../../shared/presentation/safe_change_notifier.dart';

import '../data/classement_soumission.dart';
import '../../../shared/models/commission.dart';
import '../data/commission_repository.dart';
import '../data/evaluation_repository.dart';

class EvaluationController extends SafeChangeNotifier {
  EvaluationController({
    required this.appelOffreId,
    EvaluationRepository? evaluationRepository,
    CommissionRepository? commissionRepository,
  })  : _evaluationRepository =
            evaluationRepository ?? EvaluationRepository(),
        _commissionRepository =
            commissionRepository ?? CommissionRepository();

  final String appelOffreId;
  final EvaluationRepository _evaluationRepository;
  final CommissionRepository _commissionRepository;

  List<ClassementSoumission> _classement = [];
  List<Commission> _commissions = [];

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<ClassementSoumission> get classement =>
      List.unmodifiable(_classement);

  List<Commission> get commissions =>
      List.unmodifiable(_commissions);

  bool get isLoading => _isLoading;

  bool get isSubmitting => _isSubmitting;

  bool get hasError => _errorMessage != null;

  String? get errorMessage => _errorMessage;

  int get nombreSoumissions => _classement.length;

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
      final resultats = await Future.wait<Object>([
        _evaluationRepository.classement(
          appelOffreId,
        ),
        _commissionRepository.listerParAppelOffre(
          appelOffreId,
        ),
      ]);

      _classement =
          resultats[0] as List<ClassementSoumission>;

      _commissions =
          resultats[1] as List<Commission>;
    } on EvaluationException catch (error) {
      _errorMessage = error.message;
    } on CommissionException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible de charger les évaluations.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> actualiser() async {
    try {
      _errorMessage = null;

      final resultats = await Future.wait<Object>([
        _evaluationRepository.classement(
          appelOffreId,
        ),
        _commissionRepository.listerParAppelOffre(
          appelOffreId,
        ),
      ]);

      _classement =
          resultats[0] as List<ClassementSoumission>;

      _commissions =
          resultats[1] as List<Commission>;
    } on EvaluationException catch (error) {
      _errorMessage = error.message;
    } on CommissionException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible d’actualiser les évaluations.';
    } finally {
      notifyListeners();
    }
  }

  Future<EvaluationActionResult?> evaluer({
    required String soumissionId,
    required String commissionId,
    required double? noteTechnique,
    required double? noteFinanciere,
    String? commentaire,
  }) async {
    final erreur = _validerEvaluation(
      soumissionId: soumissionId,
      commissionId: commissionId,
      noteTechnique: noteTechnique,
      noteFinanciere: noteFinanciere,
    );

    if (erreur != null) {
      _errorMessage = erreur;
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat =
          await _evaluationRepository.evaluer(
        soumissionId: soumissionId,
        commissionId: commissionId,
        noteTechnique: noteTechnique!,
        noteFinanciere: noteFinanciere!,
        commentaire: commentaire,
      );

      _classement =
          await _evaluationRepository.classement(
        appelOffreId,
      );

      return resultat;
    } on EvaluationException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Impossible d’enregistrer l’évaluation.';
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<AttributionActionResult?> attribuer({
    required String soumissionId,
    required String referenceContrat,
    String? objet,
  }) async {
    if (soumissionId.trim().isEmpty) {
      _errorMessage =
          'Sélectionnez une soumission.';
      notifyListeners();
      return null;
    }

    if (referenceContrat.trim().isEmpty) {
      _errorMessage =
          'La référence du contrat est obligatoire.';
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat =
          await _evaluationRepository.attribuer(
        soumissionId: soumissionId,
        referenceContrat: referenceContrat,
        objet: objet,
      );

      _classement =
          await _evaluationRepository.classement(
        appelOffreId,
      );

      return resultat;
    } on EvaluationException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Impossible d’attribuer le marché.';
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  String? _validerEvaluation({
    required String soumissionId,
    required String commissionId,
    required double? noteTechnique,
    required double? noteFinanciere,
  }) {
    if (soumissionId.trim().isEmpty) {
      return 'La soumission est invalide.';
    }

    if (commissionId.trim().isEmpty) {
      return 'Sélectionnez une commission.';
    }

    if (noteTechnique == null) {
      return 'La note technique est obligatoire.';
    }

    if (noteFinanciere == null) {
      return 'La note financière est obligatoire.';
    }

    if (noteTechnique < 0 ||
        noteFinanciere < 0) {
      return 'Les notes ne peuvent pas être négatives.';
    }

    return null;
  }

  void effacerErreur() {
    _errorMessage = null;
    notifyListeners();
  }
}