import '../../../shared/presentation/safe_change_notifier.dart';

import '../data/fournisseur.dart';
import '../data/fournisseur_repository.dart';

class FournisseurController extends SafeChangeNotifier {
  FournisseurController({
    FournisseurRepository? repository,
  }) : _repository =
            repository ?? FournisseurRepository();

  final FournisseurRepository _repository;

  List<Fournisseur> _fournisseurs = [];

  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isCreating = false;

  String? _fournisseurEnCoursId;
  String? _errorMessage;

  String _recherche = '';
  String _filtreStatut = 'tous';

  List<Fournisseur> get fournisseurs =>
      List.unmodifiable(_fournisseurs);

  List<Fournisseur> get fournisseursFiltres {
    final rechercheNormalisee =
        _recherche.trim().toLowerCase();

    return _fournisseurs.where(
      (fournisseur) {
        final correspondRecherche =
            rechercheNormalisee.isEmpty ||
                fournisseur.raisonSociale
                    .toLowerCase()
                    .contains(
                      rechercheNormalisee,
                    ) ||
                (fournisseur.nif
                        ?.toLowerCase() ??
                    '')
                    .contains(
                      rechercheNormalisee,
                    ) ||
                (fournisseur.stat
                        ?.toLowerCase() ??
                    '')
                    .contains(
                      rechercheNormalisee,
                    ) ||
                (fournisseur.email
                        ?.toLowerCase() ??
                    '')
                    .contains(
                      rechercheNormalisee,
                    );

        final correspondStatut =
            _filtreStatut == 'tous' ||
                fournisseur.statutValidation
                        ?.trim()
                        .toLowerCase() ==
                    _filtreStatut;

        return correspondRecherche &&
            correspondStatut;
      },
    ).toList();
  }

  bool get isLoading => _isLoading;

  bool get isRefreshing => _isRefreshing;

  bool get isCreating => _isCreating;

  bool get isBusy =>
      _isLoading ||
      _isRefreshing ||
      _isCreating ||
      _fournisseurEnCoursId != null;

  String? get errorMessage => _errorMessage;

  bool get hasError =>
      _errorMessage != null &&
      _errorMessage!.trim().isNotEmpty;

  String get recherche => _recherche;

  String get filtreStatut => _filtreStatut;

  int get nombreTotal => _fournisseurs.length;

  int get nombreActifs => _fournisseurs
      .where(
        (fournisseur) => fournisseur.estActif,
      )
      .length;

  int get nombreEnAttente => _fournisseurs
      .where(
        (fournisseur) =>
            fournisseur.estEnAttente,
      )
      .length;

  int get nombreSuspendus => _fournisseurs
      .where(
        (fournisseur) =>
            fournisseur.estSuspendu,
      )
      .length;

  bool actionEnCoursPour(
    String fournisseurId,
  ) {
    return _fournisseurEnCoursId ==
        fournisseurId.trim();
  }

  Future<void> charger() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _fournisseurs =
          List<Fournisseur>.from(
        await _repository.lister(),
      );

      _trierFournisseurs();
    } on FournisseurException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible de charger les fournisseurs.';
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
      _fournisseurs =
          List<Fournisseur>.from(
        await _repository.lister(),
      );

      _trierFournisseurs();
    } on FournisseurException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible d’actualiser les fournisseurs.';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<ActionFournisseurResult?>
      creerFournisseur(
    DonneesCreationFournisseur donnees,
  ) async {
    if (_isCreating) {
      return null;
    }

    _isCreating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat =
          await _repository.creer(
        donnees,
      );

      final fournisseur =
          resultat.fournisseur;

      if (fournisseur != null &&
          fournisseur.id.isNotEmpty) {
        _fournisseurs.insert(
          0,
          fournisseur,
        );

        _trierFournisseurs();
      } else {
        await _rechargerSansEtat();
      }

      return resultat;
    } on FournisseurException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Impossible de créer le fournisseur.';
      return null;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  Future<ActionFournisseurResult?>
      modifierFournisseur({
    required Fournisseur fournisseur,
    required DonneesModificationFournisseur
        donnees,
  }) async {
    final id = fournisseur.id.trim();

    if (id.isEmpty ||
        _fournisseurEnCoursId != null) {
      return null;
    }

    _fournisseurEnCoursId = id;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat =
          await _repository.modifier(
        fournisseurId: id,
        donnees: donnees,
      );

      _remplacerDansListe(
        id,
        resultat.fournisseur,
      );

      return resultat;
    } on FournisseurException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Impossible de modifier le fournisseur.';
      return null;
    } finally {
      _fournisseurEnCoursId = null;
      notifyListeners();
    }
  }

  Future<ActionFournisseurResult?>
      changerStatut({
    required Fournisseur fournisseur,
    required String statut,
    String? motif,
  }) async {
    final id = fournisseur.id.trim();

    if (id.isEmpty ||
        _fournisseurEnCoursId != null) {
      return null;
    }

    _fournisseurEnCoursId = id;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat =
          await _repository.changerStatut(
        fournisseurId: id,
        statut: statut,
        motif: motif,
      );

      final fournisseurRetourne =
          resultat.fournisseur;

      final index = _fournisseurs.indexWhere(
        (element) => element.id == id,
      );

      if (index >= 0) {
        _fournisseurs[index] = fournisseurRetourne ??
            _fournisseurs[index].copyWith(
              statutValidation:
                  statut.trim().toLowerCase(),
              dateMaj: DateTime.now(),
            );
      }

      return resultat;
    } on FournisseurException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Impossible de modifier le statut du fournisseur.';
      return null;
    } finally {
      _fournisseurEnCoursId = null;
      notifyListeners();
    }
  }

  Fournisseur? trouverParId(
    String fournisseurId,
  ) {
    final id = fournisseurId.trim();

    if (id.isEmpty) {
      return null;
    }

    for (final fournisseur
        in _fournisseurs) {
      if (fournisseur.id == id) {
        return fournisseur;
      }
    }

    return null;
  }

  void rechercher(
    String valeur,
  ) {
    final valeurNormalisee =
        valeur.trim();

    if (_recherche == valeurNormalisee) {
      return;
    }

    _recherche = valeurNormalisee;
    notifyListeners();
  }

  void filtrerParStatut(
    String statut,
  ) {
    final statutNormalise =
        statut.trim().toLowerCase();

    final nouveauFiltre =
        statutNormalise == 'tous' ||
                Fournisseur.statutsAutorises
                    .contains(statutNormalise)
            ? statutNormalise
            : 'tous';

    if (_filtreStatut == nouveauFiltre) {
      return;
    }

    _filtreStatut = nouveauFiltre;
    notifyListeners();
  }

  void reinitialiserFiltres() {
    final filtresDejaVides =
        _recherche.isEmpty &&
            _filtreStatut == 'tous';

    if (filtresDejaVides) {
      return;
    }

    _recherche = '';
    _filtreStatut = 'tous';
    notifyListeners();
  }

  void effacerErreur() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  void _remplacerDansListe(
    String id,
    Fournisseur? fournisseurRetourne,
  ) {
    final index = _fournisseurs.indexWhere(
      (element) => element.id == id,
    );

    if (index < 0) {
      return;
    }

    if (fournisseurRetourne != null) {
      _fournisseurs[index] =
          fournisseurRetourne.id.isEmpty
              ? _fournisseurs[index]
                  .copyWith(
                  adresse: fournisseurRetourne
                      .adresse,
                  telephone:
                      fournisseurRetourne
                          .telephone,
                  email:
                      fournisseurRetourne.email,
                  representantLegal:
                      fournisseurRetourne
                          .representantLegal,
                  dateMaj:
                      fournisseurRetourne
                              .dateMaj ??
                          DateTime.now(),
                )
              : fournisseurRetourne;
    }

    _trierFournisseurs();
  }

  Future<void> _rechargerSansEtat() async {
    _fournisseurs = List<Fournisseur>.from(
      await _repository.lister(),
    );

    _trierFournisseurs();
  }

  void _trierFournisseurs() {
    _fournisseurs.sort(
      (a, b) {
        final dateA = a.dateCreation ??
            DateTime.fromMillisecondsSinceEpoch(
              0,
            );

        final dateB = b.dateCreation ??
            DateTime.fromMillisecondsSinceEpoch(
              0,
            );

        return dateB.compareTo(dateA);
      },
    );
  }
}
