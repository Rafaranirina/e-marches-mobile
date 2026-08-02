import 'package:flutter/foundation.dart';

import '../data/categorie_marche.dart';
import '../data/categorie_repository.dart';

class CategorieController extends ChangeNotifier {
  CategorieController({
    CategorieRepository? repository,
  }) : _repository =
            repository ?? CategorieRepository();

  final CategorieRepository _repository;

  List<CategorieMarche> _categories = [];

  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isCreating = false;

  String? _errorMessage;
  String _recherche = '';
  String _filtreType = 'toutes';

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

        return correspondRecherche &&
            correspondType;
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

  bool get isBusy {
    return _isLoading ||
        _isRefreshing ||
        _isCreating;
  }

  String? get errorMessage => _errorMessage;

  bool get hasError {
    return _errorMessage != null &&
        _errorMessage!.trim().isNotEmpty;
  }

  String get recherche => _recherche;

  String get filtreType => _filtreType;

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

  Future<void> charger() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat =
          await _repository.listerCategories();

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
      final resultat =
          await _repository.listerCategories();

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

  void reinitialiserFiltres() {
    final filtresDejaVides =
        _recherche.isEmpty &&
            _filtreType == 'toutes';

    if (filtresDejaVides) {
      return;
    }

    _recherche = '';
    _filtreType = 'toutes';
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
    final resultat =
        await _repository.listerCategories();

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