import '../../../shared/presentation/safe_change_notifier.dart';

import '../data/categorie_marche.dart';
import '../data/categorie_repository.dart';

class CategorieController extends SafeChangeNotifier {
  CategorieController({
    CategorieRepository? repository,
  }) : _repository =
            repository ?? CategorieRepository();

  final CategorieRepository _repository;

  List<CategorieMarche> _categories = [];

  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isCreating = false;
  bool _modeGestion = false;

  String? _categorieEnCoursId;
  String? _errorMessage;

  String _recherche = '';
  String _filtreType = 'toutes';
  String _filtreStatut = 'toutes';

  List<CategorieMarche> get categories {
    return List.unmodifiable(_categories);
  }

  List<CategorieMarche> get categoriesFiltrees {
    final rechercheNormalisee =
        _recherche.trim().toLowerCase();

    return _categories.where(
      (categorie) {
        final correspondRecherche =
            rechercheNormalisee.isEmpty ||
                categorie.nom
                    .toLowerCase()
                    .contains(rechercheNormalisee) ||
                categorie.description
                    .toLowerCase()
                    .contains(rechercheNormalisee);

        final correspondType =
            _filtreType == 'toutes' ||
                (_filtreType == 'principales' &&
                    categorie.estCategoriePrincipale) ||
                (_filtreType == 'sous_categories' &&
                    categorie.estSousCategorie);

        final correspondStatut =
            _filtreStatut == 'toutes' ||
                (_filtreStatut == 'actives' &&
                    categorie.actif) ||
                (_filtreStatut == 'inactives' &&
                    !categorie.actif);

        return correspondRecherche &&
            correspondType &&
            correspondStatut;
      },
    ).toList();
  }

  List<CategorieMarche>
      get categoriesPrincipales {
    return _categories
        .where(
          (categorie) =>
              categorie.estCategoriePrincipale,
        )
        .toList();
  }

  bool get isLoading => _isLoading;

  bool get isRefreshing => _isRefreshing;

  bool get isCreating => _isCreating;

  bool get modeGestion => _modeGestion;

  bool get isBusy {
    return _isLoading ||
        _isRefreshing ||
        _isCreating ||
        _categorieEnCoursId != null;
  }

  String? get errorMessage => _errorMessage;

  bool get hasError {
    return _errorMessage != null &&
        _errorMessage!.trim().isNotEmpty;
  }

  String get recherche => _recherche;

  String get filtreType => _filtreType;

  String get filtreStatut => _filtreStatut;

  int get nombreTotal => _categories.length;

  int get nombrePrincipales {
    return _categories
        .where(
          (categorie) =>
              categorie.estCategoriePrincipale,
        )
        .length;
  }

  int get nombreSousCategories {
    return _categories
        .where(
          (categorie) =>
              categorie.estSousCategorie,
        )
        .length;
  }

  int get nombreActives => _categories
      .where(
        (categorie) => categorie.actif,
      )
      .length;

  int get nombreInactives => _categories
      .where(
        (categorie) => !categorie.actif,
      )
      .length;

  bool actionEnCoursPour(
    String categorieId,
  ) {
    return _categorieEnCoursId ==
        categorieId.trim();
  }

  Future<void> charger({
    bool modeGestion = false,
  }) async {
    if (_isLoading) {
      return;
    }

    _modeGestion = modeGestion;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat = _modeGestion
          ? await _repository.listerGestion()
          : await _repository
              .listerCategories();

      _categories = List<CategorieMarche>.from(
        resultat.categories,
      );

      _trierCategories();
    } on CategorieException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible de charger les catégories.';
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
      final resultat = _modeGestion
          ? await _repository.listerGestion()
          : await _repository
              .listerCategories();

      _categories = List<CategorieMarche>.from(
        resultat.categories,
      );

      _trierCategories();
    } on CategorieException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible d’actualiser les catégories.';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<ActionCategorieResult?> creerCategorie(
    DonneesCategorie donnees,
  ) async {
    if (_isCreating) {
      return null;
    }

    _isCreating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat =
          await _repository.creerCategorie(
        donnees,
      );

      final categorie = resultat.categorie;

      if (categorie != null &&
          categorie.id.isNotEmpty) {
        _categories.add(categorie);
        _trierCategories();
      } else {
        await _rechargerSansEtat();
      }

      return resultat;
    } on CategorieException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Impossible de créer la catégorie.';
      return null;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  Future<ActionCategorieResult?>
      modifierCategorie({
    required CategorieMarche categorie,
    required DonneesCategorie donnees,
  }) async {
    final id = categorie.id.trim();

    if (id.isEmpty ||
        _categorieEnCoursId != null) {
      return null;
    }

    _categorieEnCoursId = id;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat =
          await _repository.modifierCategorie(
        categorieId: id,
        donnees: donnees,
      );

      final categorieRetournee =
          resultat.categorie;

      final index = _categories.indexWhere(
        (element) => element.id == id,
      );

      if (index >= 0 &&
          categorieRetournee != null) {
        final nouveauParentId =
            categorieRetournee
                .categorieParentId;

        final parentTrouve =
            nouveauParentId == null
                ? null
                : trouverParId(
                    nouveauParentId,
                  );

        _categories[index] =
            categorie.copyWith(
          nom: categorieRetournee.nom,
          description:
              categorieRetournee
                  .description,
          categorieParentId:
              nouveauParentId,
          categorieParentNom:
              parentTrouve?.nom,
          categorieParentActif:
              parentTrouve?.actif,
          supprimerCategorieParent:
              nouveauParentId == null,
          actif: categorieRetournee.actif,
          dateCreation:
              categorieRetournee
                      .dateCreation ??
                  categorie.dateCreation,
          dateMaj:
              categorieRetournee.dateMaj ??
                  DateTime.now(),
        );

        _trierCategories();
      } else {
        await _rechargerSansEtat();
      }

      return resultat;
    } on CategorieException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Impossible de modifier la catégorie.';
      return null;
    } finally {
      _categorieEnCoursId = null;
      notifyListeners();
    }
  }

  Future<ActionCategorieResult?>
      changerStatut({
    required CategorieMarche categorie,
    required bool actif,
  }) async {
    final id = categorie.id.trim();

    if (id.isEmpty ||
        _categorieEnCoursId != null) {
      return null;
    }

    _categorieEnCoursId = id;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat =
          await _repository.changerStatut(
        categorieId: id,
        actif: actif,
      );

      final index = _categories.indexWhere(
        (element) => element.id == id,
      );

      if (index >= 0) {
        final actifRetourne =
            resultat.categorie?.actif;

        _categories[index] =
            _categories[index].copyWith(
          actif: actifRetourne ?? actif,
          dateMaj:
              resultat.categorie?.dateMaj ??
                  DateTime.now(),
        );

        _trierCategories();
      } else {
        await _rechargerSansEtat();
      }

      return resultat;
    } on CategorieException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Impossible de modifier le statut de la catégorie.';
      return null;
    } finally {
      _categorieEnCoursId = null;
      notifyListeners();
    }
  }

  Future<void> rafraichirDetail(
    String categorieId,
  ) async {
    final id = categorieId.trim();

    if (id.isEmpty) {
      return;
    }

    try {
      final categorie = await _repository
          .obtenirCategorie(id);

      final index = _categories.indexWhere(
        (element) => element.id == id,
      );

      if (index >= 0) {
        _categories[index] = categorie;
      } else {
        _categories.add(categorie);
      }

      _trierCategories();
      notifyListeners();
    } catch (_) {
      // Silencieux : les données déjà chargées restent affichées.
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

  void filtrerParType(
    String type,
  ) {
    final typeNormalise =
        type.trim().toLowerCase();

    const typesAutorises = [
      'toutes',
      'principales',
      'sous_categories',
    ];

    final nouveauFiltre =
        typesAutorises.contains(typeNormalise)
            ? typeNormalise
            : 'toutes';

    if (_filtreType == nouveauFiltre) {
      return;
    }

    _filtreType = nouveauFiltre;
    notifyListeners();
  }

  void filtrerParStatut(
    String statut,
  ) {
    final statutNormalise =
        statut.trim().toLowerCase();

    const statutsAutorises = [
      'toutes',
      'actives',
      'inactives',
    ];

    final nouveauFiltre =
        statutsAutorises.contains(statutNormalise)
            ? statutNormalise
            : 'toutes';

    if (_filtreStatut == nouveauFiltre) {
      return;
    }

    _filtreStatut = nouveauFiltre;
    notifyListeners();
  }

  void reinitialiserFiltres() {
    final filtresDejaVides =
        _recherche.isEmpty &&
            _filtreType == 'toutes' &&
            _filtreStatut == 'toutes';

    if (filtresDejaVides) {
      return;
    }

    _recherche = '';
    _filtreType = 'toutes';
    _filtreStatut = 'toutes';
    notifyListeners();
  }

  CategorieMarche? trouverParId(
    String categorieId,
  ) {
    final id = categorieId.trim();

    if (id.isEmpty) {
      return null;
    }

    for (final categorie in _categories) {
      if (categorie.id == id) {
        return categorie;
      }
    }

    return null;
  }

  String nomCategorieParId(
    String? categorieId,
  ) {
    final id = categorieId?.trim() ?? '';

    if (id.isEmpty) {
      return 'Catégorie principale';
    }

    final categorie = trouverParId(id);

    return categorie?.nom ??
        'Catégorie parente inconnue';
  }

  void effacerErreur() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _rechargerSansEtat() async {
    final resultat = _modeGestion
        ? await _repository.listerGestion()
        : await _repository
            .listerCategories();

    _categories = List<CategorieMarche>.from(
      resultat.categories,
    );

    _trierCategories();
  }

  void _trierCategories() {
    _categories.sort(
      (a, b) => a.nom
          .toLowerCase()
          .compareTo(
            b.nom.toLowerCase(),
          ),
    );
  }
}
