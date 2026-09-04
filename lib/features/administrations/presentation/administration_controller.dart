import '../../../shared/presentation/safe_change_notifier.dart';

import '../data/administration_marche.dart';
import '../data/administration_repository.dart';

class AdministrationController extends SafeChangeNotifier {
  AdministrationController({
    AdministrationRepository? repository,
  }) : _repository =
            repository ?? AdministrationRepository();

  final AdministrationRepository _repository;

  List<AdministrationMarche> _administrations = [];

  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isCreating = false;

  String? _administrationEnCoursId;
  String? _errorMessage;
  String _recherche = '';

  List<AdministrationMarche> get administrations {
    return List.unmodifiable(_administrations);
  }

  List<AdministrationMarche> get administrationsFiltrees {
    final rechercheNormalisee =
        _recherche.trim().toLowerCase();

    if (rechercheNormalisee.isEmpty) {
      return List.unmodifiable(_administrations);
    }

    return _administrations.where(
      (administration) {
        return administration.nom
                .toLowerCase()
                .contains(rechercheNormalisee) ||
            administration.sigle
                .toLowerCase()
                .contains(rechercheNormalisee) ||
            administration.typeEntite
                .toLowerCase()
                .contains(rechercheNormalisee) ||
            administration.email
                .toLowerCase()
                .contains(rechercheNormalisee) ||
            administration.telephone
                .toLowerCase()
                .contains(rechercheNormalisee);
      },
    ).toList();
  }

  bool get isLoading => _isLoading;

  bool get isRefreshing => _isRefreshing;

  bool get isCreating => _isCreating;

  bool get isBusy {
    return _isLoading ||
        _isRefreshing ||
        _isCreating ||
        _administrationEnCoursId != null;
  }

  String? get errorMessage => _errorMessage;

  bool get hasError {
    return _errorMessage != null &&
        _errorMessage!.trim().isNotEmpty;
  }

  String get recherche => _recherche;

  int get nombreTotal => _administrations.length;

  int get nombreAvecSigle {
    return _administrations
        .where(
          (administration) =>
              administration.sigle.trim().isNotEmpty,
        )
        .length;
  }

  int get nombreAvecCoordonnees {
    return _administrations
        .where(
          (administration) =>
              administration.possedeCoordonnees,
        )
        .length;
  }

  bool actionEnCoursPour(
    String administrationId,
  ) {
    return _administrationEnCoursId ==
        administrationId.trim();
  }

  Future<void> charger() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat =
          await _repository.listerGestion();

      _administrations =
          List<AdministrationMarche>.from(
        resultat.administrations,
      );

      _trierAdministrations();
    } on AdministrationException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible de charger les administrations.';
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
      final resultat =
          await _repository.listerGestion();

      _administrations =
          List<AdministrationMarche>.from(
        resultat.administrations,
      );

      _trierAdministrations();
    } on AdministrationException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible d’actualiser les administrations.';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<ActionAdministrationResult?>
      creerAdministration(
    DonneesAdministration donnees,
  ) async {
    if (_isCreating) {
      return null;
    }

    _isCreating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat =
          await _repository.creerAdministration(
        donnees,
      );

      final administration =
          resultat.administration;

      if (administration != null &&
          administration.id.isNotEmpty) {
        _administrations.add(
          administration,
        );

        _trierAdministrations();
      } else {
        await _rechargerSansEtat();
      }

      return resultat;
    } on AdministrationException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Impossible de créer l’administration.';
      return null;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  Future<ActionAdministrationResult?>
      modifierAdministration({
    required AdministrationMarche
        administration,
    required DonneesAdministration donnees,
  }) async {
    final id = administration.id.trim();

    if (id.isEmpty ||
        _administrationEnCoursId != null) {
      return null;
    }

    _administrationEnCoursId = id;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat =
          await _repository.modifier(
        administrationId: id,
        donnees: donnees,
      );

      final administrationRetournee =
          resultat.administration;

      final index = _administrations.indexWhere(
        (element) => element.id == id,
      );

      if (index >= 0 &&
          administrationRetournee != null) {
        _administrations[index] =
            administrationRetournee;

        _trierAdministrations();
      } else {
        await _rechargerSansEtat();
      }

      return resultat;
    } on AdministrationException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Impossible de modifier l’administration.';
      return null;
    } finally {
      _administrationEnCoursId = null;
      notifyListeners();
    }
  }

  Future<ActionAdministrationResult?>
      changerStatut({
    required AdministrationMarche
        administration,
    required bool actif,
  }) async {
    final id = administration.id.trim();

    if (id.isEmpty ||
        _administrationEnCoursId != null) {
      return null;
    }

    _administrationEnCoursId = id;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat =
          await _repository.changerStatut(
        administrationId: id,
        actif: actif,
      );

      final index = _administrations.indexWhere(
        (element) => element.id == id,
      );

      if (index >= 0) {
        final administrationRetournee =
            resultat.administration;

        _administrations[index] =
            administrationRetournee ??
                _administrations[index].copyWith(
                  actif: actif,
                  dateMaj: DateTime.now(),
                );

        _trierAdministrations();
      }

      return resultat;
    } on AdministrationException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Impossible de modifier le statut de l’administration.';
      return null;
    } finally {
      _administrationEnCoursId = null;
      notifyListeners();
    }
  }

  Future<AdministrationMarche?>
      obtenirDetail(
    String administrationId,
  ) async {
    final id = administrationId.trim();

    if (id.isEmpty) {
      return null;
    }

    try {
      final administration =
          await _repository.obtenir(id);

      final index = _administrations.indexWhere(
        (element) => element.id == id,
      );

      if (index >= 0) {
        _administrations[index] =
            administration;
        notifyListeners();
      }

      return administration;
    } on AdministrationException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      return null;
    } catch (_) {
      _errorMessage =
          'Impossible de charger l’administration.';
      notifyListeners();
      return null;
    }
  }

  void rechercher(
    String valeur,
  ) {
    final rechercheNormalisee =
        valeur.trim();

    if (_recherche == rechercheNormalisee) {
      return;
    }

    _recherche = rechercheNormalisee;
    notifyListeners();
  }

  void reinitialiserRecherche() {
    if (_recherche.isEmpty) {
      return;
    }

    _recherche = '';
    notifyListeners();
  }

  AdministrationMarche? trouverParId(
    String administrationId,
  ) {
    final id = administrationId.trim();

    if (id.isEmpty) {
      return null;
    }

    for (final administration
        in _administrations) {
      if (administration.id == id) {
        return administration;
      }
    }

    return null;
  }

  void effacerErreur() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _rechargerSansEtat() async {
    final resultat =
        await _repository.listerGestion();

    _administrations =
        List<AdministrationMarche>.from(
      resultat.administrations,
    );

    _trierAdministrations();
  }

  void _trierAdministrations() {
    _administrations.sort(
      (a, b) => a.nom
          .toLowerCase()
          .compareTo(
            b.nom.toLowerCase(),
          ),
    );
  }
}