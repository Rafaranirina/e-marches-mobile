import 'package:flutter/foundation.dart';

import '../../../shared/models/commission.dart';
import '../data/commission_repository.dart';
import '../data/membre_commission_option.dart';

class CommissionManagementController
    extends ChangeNotifier {
  CommissionManagementController({
    required this.appelOffreId,
    CommissionRepository? repository,
  }) : _repository =
            repository ?? CommissionRepository();

  final String appelOffreId;
  final CommissionRepository _repository;

  List<Commission> _commissions = [];
  List<MembreCommissionOption>
      _membresDisponibles = [];

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _membresErrorMessage;

  List<Commission> get commissions =>
      List.unmodifiable(_commissions);

  List<MembreCommissionOption>
      get membresDisponibles =>
          List.unmodifiable(
            _membresDisponibles,
          );

  bool get isLoading => _isLoading;

  bool get isSubmitting => _isSubmitting;

  String? get errorMessage => _errorMessage;

  String? get membresErrorMessage =>
      _membresErrorMessage;

  bool get hasError =>
      _errorMessage != null;

  bool get hasMembresError =>
      _membresErrorMessage != null;

  int get nombreCommissions =>
      _commissions.length;

  int get nombreMembresDisponibles =>
      _membresDisponibles.length;

  Future<void> charger() async {
    if (appelOffreId.trim().isEmpty) {
      _errorMessage =
          'L’identifiant de l’appel d’offres est invalide.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _membresErrorMessage = null;
    notifyListeners();

    try {
      _commissions = await _repository
          .listerParAppelOffre(
        appelOffreId,
      );
    } on CommissionException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible de charger les commissions.';
    }

    try {
      _membresDisponibles = await _repository
          .listerMembresDisponibles();
    } on CommissionException catch (error) {
      _membresErrorMessage = error.message;
    } catch (_) {
      _membresErrorMessage =
          'Impossible de charger les membres disponibles.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> actualiser() async {
    _errorMessage = null;
    _membresErrorMessage = null;

    try {
      _commissions = await _repository
          .listerParAppelOffre(
        appelOffreId,
      );
    } on CommissionException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible d’actualiser les commissions.';
    }

    try {
      _membresDisponibles = await _repository
          .listerMembresDisponibles();
    } on CommissionException catch (error) {
      _membresErrorMessage = error.message;
    } catch (_) {
      _membresErrorMessage =
          'Impossible d’actualiser les membres disponibles.';
    } finally {
      notifyListeners();
    }
  }

  Future<CreationCommissionResult?>
      creerCommission({
    required String nom,
  }) async {
    final nomNormalise = nom.trim();

    if (nomNormalise.isEmpty) {
      _errorMessage =
          'Le nom de la commission est obligatoire.';
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat =
          await _repository.creerCommission(
        nom: nomNormalise,
        appelOffreId: appelOffreId,
      );

      _commissions =
          await _repository
              .listerParAppelOffre(
        appelOffreId,
      );

      return resultat;
    } on CommissionException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Impossible de créer la commission.';
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<AjoutMembreCommissionResult?>
      ajouterMembre({
    required String commissionId,
    required String utilisateurId,
    String? fonction,
  }) async {
    if (commissionId.trim().isEmpty) {
      _errorMessage =
          'Sélectionnez une commission.';
      notifyListeners();
      return null;
    }

    if (utilisateurId.trim().isEmpty) {
      _errorMessage =
          'Sélectionnez un membre.';
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat =
          await _repository.ajouterMembre(
        commissionId:
            commissionId.trim(),
        utilisateurId:
            utilisateurId.trim(),
        fonction: fonction,
      );

      _commissions =
          await _repository
              .listerParAppelOffre(
        appelOffreId,
      );

      return resultat;
    } on CommissionException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Impossible d’ajouter le membre à la commission.';
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  List<MembreCommissionOption>
      membresNonAjoutes(
    Commission commission,
  ) {
    final identifiantsExistants =
        commission.membres
            .map(
              (membre) =>
                  membre.utilisateurId,
            )
            .where(
              (id) => id.isNotEmpty,
            )
            .toSet();

    return _membresDisponibles
        .where(
          (membre) =>
              !identifiantsExistants
                  .contains(membre.id),
        )
        .toList();
  }

  Commission? trouverCommission(
    String commissionId,
  ) {
    for (final commission
        in _commissions) {
      if (commission.id ==
          commissionId) {
        return commission;
      }
    }

    return null;
  }

  void effacerErreur() {
    _errorMessage = null;
    notifyListeners();
  }
}