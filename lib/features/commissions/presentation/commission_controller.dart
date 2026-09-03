import 'package:flutter/foundation.dart';

import '../../utilisateurs/data/utilisateur_gestion.dart';
import '../../../shared/models/commission.dart';
import '../data/commission_membre_repository.dart';
import '../data/commission_repository.dart';

class CommissionController extends ChangeNotifier {
  CommissionController({
    required String appelOffreId,
    CommissionRepository? repository,
    CommissionMembreRepository? membreRepository,
  })  : _appelOffreId = appelOffreId.trim(),
        _repository = repository ?? CommissionRepository(),
        _membreRepository =
            membreRepository ?? CommissionMembreRepository();

  final CommissionRepository _repository;
  final CommissionMembreRepository _membreRepository;
  final String _appelOffreId;

  List<Commission> _commissions = [];
  List<UtilisateurGestion> _membresDisponibles = [];

  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isCreating = false;
  bool _isAddingMember = false;
  bool _isLoadingMembers = false;

  String? _commissionEnCoursId;
  String? _errorMessage;
  String? _membersErrorMessage;

  String get appelOffreId => _appelOffreId;

  List<Commission> get commissions {
    return List.unmodifiable(_commissions);
  }

  List<UtilisateurGestion> get membresDisponibles {
    return List.unmodifiable(_membresDisponibles);
  }

  bool get isLoading => _isLoading;

  bool get isRefreshing => _isRefreshing;

  bool get isCreating => _isCreating;

  bool get isAddingMember => _isAddingMember;

  bool get isLoadingMembers => _isLoadingMembers;

  bool get isBusy {
    return _isLoading ||
        _isRefreshing ||
        _isCreating ||
        _isAddingMember ||
        _isLoadingMembers;
  }

  String? get commissionEnCoursId {
    return _commissionEnCoursId;
  }

  String? get errorMessage => _errorMessage;

  String? get membersErrorMessage {
    return _membersErrorMessage;
  }

  bool get hasError {
    return _errorMessage != null &&
        _errorMessage!.trim().isNotEmpty;
  }

  bool get hasMembersError {
    return _membersErrorMessage != null &&
        _membersErrorMessage!.trim().isNotEmpty;
  }

  int get nombreCommissions {
    return _commissions.length;
  }

  int get nombreMembres {
    return _commissions.fold<int>(
      0,
      (total, commission) {
        return total + commission.nombreMembres;
      },
    );
  }

  bool operationMembreEnCours(
    String commissionId,
  ) {
    return _isAddingMember &&
        _commissionEnCoursId == commissionId.trim();
  }

  Future<void> charger() async {
    if (_isLoading) {
      return;
    }

    if (_appelOffreId.isEmpty) {
      _errorMessage =
          'L’appel d’offres sélectionné est invalide.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _isLoadingMembers = true;
    _errorMessage = null;
    _membersErrorMessage = null;
    notifyListeners();

    try {
      await _chargerCommissionsSansEtat();
    } on CommissionException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible de charger les commissions.';
    }

    try {
      await _chargerMembresSansEtat();
    } on CommissionMembreException catch (error) {
      _membersErrorMessage = error.message;
    } catch (_) {
      _membersErrorMessage =
          'Impossible de charger les membres disponibles.';
    } finally {
      _isLoading = false;
      _isLoadingMembers = false;
      notifyListeners();
    }
  }

  Future<void> actualiser() async {
    if (_isRefreshing || _isLoading) {
      return;
    }

    if (_appelOffreId.isEmpty) {
      _errorMessage =
          'L’appel d’offres sélectionné est invalide.';
      notifyListeners();
      return;
    }

    _isRefreshing = true;
    _isLoadingMembers = true;
    _errorMessage = null;
    _membersErrorMessage = null;
    notifyListeners();

    try {
      await _chargerCommissionsSansEtat();
    } on CommissionException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible d’actualiser les commissions.';
    }

    try {
      await _chargerMembresSansEtat();
    } on CommissionMembreException catch (error) {
      _membersErrorMessage = error.message;
    } catch (_) {
      _membersErrorMessage =
          'Impossible d’actualiser les membres disponibles.';
    } finally {
      _isRefreshing = false;
      _isLoadingMembers = false;
      notifyListeners();
    }
  }

  Future<void> actualiserMembres() async {
    if (_isLoadingMembers) {
      return;
    }

    _isLoadingMembers = true;
    _membersErrorMessage = null;
    notifyListeners();

    try {
      await _chargerMembresSansEtat();
    } on CommissionMembreException catch (error) {
      _membersErrorMessage = error.message;
    } catch (_) {
      _membersErrorMessage =
          'Impossible d’actualiser les membres disponibles.';
    } finally {
      _isLoadingMembers = false;
      notifyListeners();
    }
  }

  Future<ActionCommissionResult?> creerCommission(
    String nom,
  ) async {
    if (_isCreating) {
      return null;
    }

    final nomNormalise = nom.trim();

    if (nomNormalise.isEmpty) {
      _errorMessage =
          'Le nom de la commission est obligatoire.';
      notifyListeners();
      return null;
    }

    if (_appelOffreId.isEmpty) {
      _errorMessage =
          'L’appel d’offres sélectionné est invalide.';
      notifyListeners();
      return null;
    }

    _isCreating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat =
          await _repository.creerCommission(
        DonneesCommission(
          nom: nomNormalise,
          appelOffreId: _appelOffreId,
        ),
      );

      final commission = resultat.commission;

      if (commission != null &&
          commission.id.isNotEmpty) {
        final existeDeja = _commissions.any(
          (element) => element.id == commission.id,
        );

        if (!existeDeja) {
          _commissions.add(commission);
        }

        _trierCommissions();
      } else {
        await _chargerCommissionsSansEtat();
      }

      return resultat;
    } on CommissionException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Impossible de créer la commission.';
      return null;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  Future<ActionMembreCommissionResult?> ajouterMembre({
    required String commissionId,
    required String utilisateurId,
    required String fonction,
  }) async {
    if (_isAddingMember) {
      return null;
    }

    final commissionIdNormalise =
        commissionId.trim();

    final utilisateurIdNormalise =
        utilisateurId.trim();

    if (commissionIdNormalise.isEmpty) {
      _errorMessage =
          'La commission sélectionnée est invalide.';
      notifyListeners();
      return null;
    }

    if (utilisateurIdNormalise.isEmpty) {
      _errorMessage =
          'Le membre sélectionné est invalide.';
      notifyListeners();
      return null;
    }

    final commission = trouverCommissionParId(
      commissionIdNormalise,
    );

    if (commission == null) {
      _errorMessage =
          'La commission sélectionnée est introuvable.';
      notifyListeners();
      return null;
    }

    if (commission.contientUtilisateur(
      utilisateurIdNormalise,
    )) {
      _errorMessage =
          'Ce membre fait déjà partie de la commission.';
      notifyListeners();
      return null;
    }

    _isAddingMember = true;
    _commissionEnCoursId = commissionIdNormalise;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat =
          await _repository.ajouterMembre(
        commissionId: commissionIdNormalise,
        donnees: DonneesMembreCommission(
          utilisateurId: utilisateurIdNormalise,
          fonction: fonction.trim(),
        ),
      );

      final membre = resultat.membre;

      if (membre != null &&
          membre.utilisateurId.isNotEmpty) {
        _ajouterMembreLocalement(
          commissionIdNormalise,
          membre,
        );
      } else {
        await _chargerCommissionsSansEtat();
      }

      return resultat;
    } on CommissionException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Impossible d’ajouter le membre.';
      return null;
    } finally {
      _isAddingMember = false;
      _commissionEnCoursId = null;
      notifyListeners();
    }
  }

  Commission? trouverCommissionParId(
    String commissionId,
  ) {
    final id = commissionId.trim();

    if (id.isEmpty) {
      return null;
    }

    for (final commission in _commissions) {
      if (commission.id == id) {
        return commission;
      }
    }

    return null;
  }

  UtilisateurGestion? trouverMembreParId(
    String utilisateurId,
  ) {
    final id = utilisateurId.trim();

    if (id.isEmpty) {
      return null;
    }

    for (final utilisateur in _membresDisponibles) {
      if (utilisateur.id == id) {
        return utilisateur;
      }
    }

    return null;
  }

  String nomMembreParId(
    String utilisateurId,
  ) {
    final utilisateur = trouverMembreParId(
      utilisateurId,
    );

    return utilisateur?.nomComplet ??
        'Utilisateur inconnu';
  }

  List<UtilisateurGestion> membresNonAjoutes(
    String commissionId,
  ) {
    final commission = trouverCommissionParId(
      commissionId,
    );

    if (commission == null) {
      return List<UtilisateurGestion>.from(
        _membresDisponibles,
      );
    }

    final idsDejaAjoutes = commission.membres
        .map(
          (membre) => membre.utilisateurId,
        )
        .toSet();

    return _membresDisponibles
        .where(
          (utilisateur) =>
              !idsDejaAjoutes.contains(utilisateur.id),
        )
        .toList();
  }

  void effacerErreur() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  void effacerErreurMembres() {
    if (_membersErrorMessage == null) {
      return;
    }

    _membersErrorMessage = null;
    notifyListeners();
  }

  Future<void> _chargerCommissionsSansEtat() async {
    final resultat =
        await _repository.listerParAppelOffre(
      _appelOffreId,
    );

    _commissions = List<Commission>.from(
      resultat.commissions,
    );

    _trierCommissions();
  }

  Future<void> _chargerMembresSansEtat() async {
    final resultat =
        await _membreRepository
            .listerMembresDisponibles();

    _membresDisponibles =
        List<UtilisateurGestion>.from(
      resultat,
    );

    _trierMembres();
  }

  void _ajouterMembreLocalement(
    String commissionId,
    MembreCommission membre,
  ) {
    final index = _commissions.indexWhere(
      (commission) => commission.id == commissionId,
    );

    if (index < 0) {
      return;
    }

    final commission = _commissions[index];

    final membreExiste = commission.membres.any(
      (element) =>
          element.utilisateurId ==
          membre.utilisateurId,
    );

    if (membreExiste) {
      return;
    }

    final membresMisAJour =
        List<MembreCommission>.from(
      commission.membres,
    )..add(membre);

    _commissions[index] = commission.copyWith(
      membres: membresMisAJour,
    );
  }

  void _trierCommissions() {
    _commissions.sort(
      (a, b) {
        final dateA = a.dateCreation;
        final dateB = b.dateCreation;

        if (dateA != null && dateB != null) {
          return dateB.compareTo(dateA);
        }

        if (dateA != null) {
          return -1;
        }

        if (dateB != null) {
          return 1;
        }

        return a.nom.toLowerCase().compareTo(
              b.nom.toLowerCase(),
            );
      },
    );
  }

  void _trierMembres() {
    _membresDisponibles.sort(
      (a, b) => a.nomComplet.toLowerCase().compareTo(
            b.nomComplet.toLowerCase(),
          ),
    );
  }
}