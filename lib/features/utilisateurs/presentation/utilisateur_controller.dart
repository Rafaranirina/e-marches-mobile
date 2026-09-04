import '../../../shared/presentation/safe_change_notifier.dart';

import '../data/utilisateur_gestion.dart';
import '../data/utilisateur_repository.dart';

class UtilisateurController extends SafeChangeNotifier {
  UtilisateurController({
    UtilisateurRepository? repository,
  }) : _repository =
            repository ?? UtilisateurRepository();

  final UtilisateurRepository _repository;

  List<UtilisateurGestion> _utilisateurs = [];

  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isCreating = false;

  String? _utilisateurEnCoursId;
  String? _errorMessage;

  String _recherche = '';
  String _filtreRole = 'tous';
  String _filtreStatut = 'tous';

  List<UtilisateurGestion> get utilisateurs =>
      List.unmodifiable(_utilisateurs);

  List<UtilisateurGestion>
      get utilisateursFiltres {
    final rechercheNormalisee =
        _recherche.trim().toLowerCase();

    return _utilisateurs.where(
      (utilisateur) {
        final correspondRecherche =
            rechercheNormalisee.isEmpty ||
                utilisateur.nomComplet
                    .toLowerCase()
                    .contains(
                      rechercheNormalisee,
                    ) ||
                utilisateur.email
                    .toLowerCase()
                    .contains(
                      rechercheNormalisee,
                    ) ||
                utilisateur.telephone
                    .toLowerCase()
                    .contains(
                      rechercheNormalisee,
                    );

        final correspondRole =
            _filtreRole == 'tous' ||
                utilisateur.role
                        .trim()
                        .toLowerCase() ==
                    _filtreRole;

        final correspondStatut =
            _filtreStatut == 'tous' ||
                utilisateur.statut
                        .trim()
                        .toLowerCase() ==
                    _filtreStatut;

        return correspondRecherche &&
            correspondRole &&
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
      _utilisateurEnCoursId != null;

  String? get errorMessage => _errorMessage;

  bool get hasError =>
      _errorMessage != null &&
      _errorMessage!.trim().isNotEmpty;

  String get recherche => _recherche;

  String get filtreRole => _filtreRole;

  String get filtreStatut => _filtreStatut;

  int get nombreTotal => _utilisateurs.length;

  int get nombreActifs => _utilisateurs
      .where(
        (utilisateur) => utilisateur.estActif,
      )
      .length;

  int get nombreEnAttente => _utilisateurs
      .where(
        (utilisateur) =>
            utilisateur.estEnAttente,
      )
      .length;

  int get nombreSuspendus => _utilisateurs
      .where(
        (utilisateur) =>
            utilisateur.estSuspendu,
      )
      .length;

  bool actionEnCoursPour(
    String utilisateurId,
  ) {
    return _utilisateurEnCoursId ==
        utilisateurId.trim();
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
          await _repository
              .listerUtilisateurs();

      _utilisateurs =
          List<UtilisateurGestion>.from(
        resultat.utilisateurs,
      );

      _trierUtilisateurs();
    } on UtilisateurException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible de charger les utilisateurs.';
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
          await _repository
              .listerUtilisateurs();

      _utilisateurs =
          List<UtilisateurGestion>.from(
        resultat.utilisateurs,
      );

      _trierUtilisateurs();
    } on UtilisateurException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible d’actualiser les utilisateurs.';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<ActionUtilisateurResult?>
      creerUtilisateur(
    DonneesUtilisateur donnees,
  ) async {
    if (_isCreating) {
      return null;
    }

    _isCreating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat =
          await _repository.creerUtilisateur(
        donnees,
      );

      final utilisateur =
          resultat.utilisateur;

      if (utilisateur != null &&
          utilisateur.id.isNotEmpty) {
        _utilisateurs.insert(
          0,
          utilisateur,
        );

        _trierUtilisateurs();
      } else {
        await _rechargerSansEtat();
      }

      return resultat;
    } on UtilisateurException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Impossible de créer le compte.';
      return null;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  Future<ActionUtilisateurResult?>
      modifierUtilisateur({
    required UtilisateurGestion utilisateur,
    required DonneesUtilisateur donnees,
  }) async {
    final id = utilisateur.id.trim();

    if (id.isEmpty ||
        _utilisateurEnCoursId != null) {
      return null;
    }

    _utilisateurEnCoursId = id;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat =
          await _repository.modifierUtilisateur(
        utilisateurId: id,
        donnees: donnees,
      );

      final utilisateurRetourne =
          resultat.utilisateur;

      final index = _utilisateurs.indexWhere(
        (element) => element.id == id,
      );

      if (index >= 0 &&
          utilisateurRetourne != null) {
        _utilisateurs[index] =
            UtilisateurGestion(
          id: utilisateurRetourne.id.isEmpty
              ? utilisateur.id
              : utilisateurRetourne.id,
          nom: utilisateurRetourne.nom,
          prenom:
              utilisateurRetourne.prenom,
          email:
              utilisateurRetourne.email,
          telephone:
              utilisateurRetourne.telephone,
          role:
              utilisateurRetourne.role,
          statut:
              utilisateurRetourne.statut,
          administrationId:
              utilisateurRetourne
                  .administrationId,
          entrepriseId:
              utilisateurRetourne
                  .entrepriseId,
          doubleAuthActive:
              utilisateur.doubleAuthActive,
          derniereConnexion:
              utilisateurRetourne
                      .derniereConnexion ??
                  utilisateur
                      .derniereConnexion,
          dateCreation:
              utilisateurRetourne
                      .dateCreation ??
                  utilisateur.dateCreation,
          dateMaj:
              utilisateurRetourne.dateMaj ??
                  DateTime.now(),
        );

        _trierUtilisateurs();
      } else {
        await _rechargerSansEtat();
      }

      return resultat;
    } on UtilisateurException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Impossible de modifier le compte.';
      return null;
    } finally {
      _utilisateurEnCoursId = null;
      notifyListeners();
    }
  }

  Future<ActionUtilisateurResult?>
      changerStatut({
    required UtilisateurGestion utilisateur,
    required String statut,
  }) async {
    final id = utilisateur.id.trim();

    if (id.isEmpty ||
        _utilisateurEnCoursId != null) {
      return null;
    }

    _utilisateurEnCoursId = id;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat =
          await _repository.changerStatut(
        utilisateurId: id,
        statut: statut,
      );

      final index = _utilisateurs.indexWhere(
        (element) => element.id == id,
      );

      if (index >= 0) {
        final statutRetourne =
            resultat.utilisateur
                    ?.statut
                    .trim() ??
                '';

        _utilisateurs[index] =
            _utilisateurs[index].copyWith(
          statut: statutRetourne.isEmpty
              ? statut.trim().toLowerCase()
              : statutRetourne,
          dateMaj:
              resultat.utilisateur?.dateMaj ??
                  DateTime.now(),
        );
      }

      return resultat;
    } on UtilisateurException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Impossible de modifier le statut du compte.';
      return null;
    } finally {
      _utilisateurEnCoursId = null;
      notifyListeners();
    }
  }

  Future<ActionUtilisateurResult?>
      reinitialiserMotDePasse({
    required UtilisateurGestion utilisateur,
    required String nouveauMotDePasse,
  }) async {
    final id = utilisateur.id.trim();

    if (id.isEmpty ||
        _utilisateurEnCoursId != null) {
      return null;
    }

    _utilisateurEnCoursId = id;
    _errorMessage = null;
    notifyListeners();

    try {
      return await _repository
          .reinitialiserMotDePasse(
        utilisateurId: id,
        nouveauMotDePasse:
            nouveauMotDePasse,
      );
    } on UtilisateurException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Impossible de réinitialiser le mot de passe.';
      return null;
    } finally {
      _utilisateurEnCoursId = null;
      notifyListeners();
    }
  }

  UtilisateurGestion? trouverParId(
    String utilisateurId,
  ) {
    final id = utilisateurId.trim();

    if (id.isEmpty) {
      return null;
    }

    for (final utilisateur
        in _utilisateurs) {
      if (utilisateur.id == id) {
        return utilisateur;
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

  void filtrerParRole(
    String role,
  ) {
    final roleNormalise =
        role.trim().toLowerCase();

    final nouveauFiltre =
        roleNormalise == 'tous' ||
                UtilisateurGestion
                    .rolesAutorises
                    .contains(roleNormalise)
            ? roleNormalise
            : 'tous';

    if (_filtreRole == nouveauFiltre) {
      return;
    }

    _filtreRole = nouveauFiltre;
    notifyListeners();
  }

  void filtrerParStatut(
    String statut,
  ) {
    final statutNormalise =
        statut.trim().toLowerCase();

    final nouveauFiltre =
        statutNormalise == 'tous' ||
                UtilisateurGestion
                    .statutsAutorises
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
            _filtreRole == 'tous' &&
            _filtreStatut == 'tous';

    if (filtresDejaVides) {
      return;
    }

    _recherche = '';
    _filtreRole = 'tous';
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

  Future<void> _rechargerSansEtat() async {
    final resultat =
        await _repository.listerUtilisateurs();

    _utilisateurs =
        List<UtilisateurGestion>.from(
      resultat.utilisateurs,
    );

    _trierUtilisateurs();
  }

  void _trierUtilisateurs() {
    _utilisateurs.sort(
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