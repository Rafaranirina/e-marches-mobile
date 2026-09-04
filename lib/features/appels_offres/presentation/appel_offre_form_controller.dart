import '../../../shared/presentation/safe_change_notifier.dart';

import '../data/appel_offre.dart';
import '../data/appel_offre_referentiels.dart';
import '../data/appel_offre_repository.dart';

class AppelOffreFormController extends SafeChangeNotifier {
  AppelOffreFormController({
    AppelOffreRepository? repository,
  }) : _repository = repository ?? AppelOffreRepository();

  final AppelOffreRepository _repository;

  static const List<String> typesMarche = [
    'travaux',
    'fournitures',
    'services',
    'equipements',
    'developpement',
    'infrastructure',
  ];

  List<AdministrationOption> _administrations = [];
  List<CategorieOption> _categories = [];

  bool _isLoadingReferentiels = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<AdministrationOption> get administrations =>
      List.unmodifiable(_administrations);

  List<CategorieOption> get categories =>
      List.unmodifiable(_categories);

  bool get isLoadingReferentiels => _isLoadingReferentiels;

  bool get isSubmitting => _isSubmitting;

  String? get errorMessage => _errorMessage;

  bool get hasError => _errorMessage != null;

  Future<void> chargerReferentiels() async {
    _isLoadingReferentiels = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultats = await Future.wait([
        _repository.listerAdministrations(),
        _repository.listerCategories(),
      ]);

      _administrations =
          resultats[0] as List<AdministrationOption>;
      _categories = resultats[1] as List<CategorieOption>;
    } on AppelOffreException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible de charger les administrations et les catégories.';
    } finally {
      _isLoadingReferentiels = false;
      notifyListeners();
    }
  }

  Future<AppelOffreActionResult?> enregistrer({
    AppelOffre? appelOffreExistant,
    required String reference,
    required String titre,
    required String typeMarche,
    required String administrationId,
    String? description,
    String? categorieId,
    double? montantEstime,
    DateTime? dateLimiteSoumission,
    DateTime? dateOuverturePlis,
  }) async {
    _errorMessage = null;

    final erreurValidation = _valider(
      reference: reference,
      titre: titre,
      typeMarche: typeMarche,
      administrationId: administrationId,
      montantEstime: montantEstime,
      dateLimiteSoumission: dateLimiteSoumission,
      dateOuverturePlis: dateOuverturePlis,
    );

    if (erreurValidation != null) {
      _errorMessage = erreurValidation;
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      if (appelOffreExistant == null) {
        return await _repository.creer(
          reference: reference,
          titre: titre,
          description: description,
          typeMarche: typeMarche,
          categorieId: categorieId,
          administrationId: administrationId,
          montantEstime: montantEstime,
          dateLimiteSoumission: dateLimiteSoumission,
          dateOuverturePlis: dateOuverturePlis,
        );
      }

      return await _repository.modifier(
        id: appelOffreExistant.id,
        reference: reference,
        titre: titre,
        description: description,
        typeMarche: typeMarche,
        categorieId: categorieId,
        administrationId: administrationId,
        montantEstime: montantEstime,
        dateLimiteSoumission: dateLimiteSoumission,
        dateOuverturePlis: dateOuverturePlis,
      );
    } on AppelOffreException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Une erreur inattendue est survenue pendant l’enregistrement.';
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  String? _valider({
    required String reference,
    required String titre,
    required String typeMarche,
    required String administrationId,
    required double? montantEstime,
    required DateTime? dateLimiteSoumission,
    required DateTime? dateOuverturePlis,
  }) {
    if (reference.trim().isEmpty) {
      return 'La référence est obligatoire.';
    }

    if (titre.trim().isEmpty) {
      return 'Le titre est obligatoire.';
    }

    if (!typesMarche.contains(typeMarche)) {
      return 'Le type de marché sélectionné est invalide.';
    }

    if (administrationId.trim().isEmpty) {
      return 'L’administration est obligatoire.';
    }

    if (montantEstime != null && montantEstime < 0) {
      return 'Le montant estimé ne peut pas être négatif.';
    }

    if (dateLimiteSoumission != null &&
        dateOuverturePlis != null &&
        dateOuverturePlis.isBefore(dateLimiteSoumission)) {
      return 'La date d’ouverture des plis doit être postérieure ou égale à la date limite.';
    }

    return null;
  }

  Future<AppelOffreActionResult?> publier(
    String appelOffreId,
  ) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await _repository.publier(appelOffreId);
    } on AppelOffreException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Une erreur inattendue est survenue pendant la publication.';
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}