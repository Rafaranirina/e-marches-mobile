import 'package:flutter/foundation.dart';

import '../data/contrat.dart';
import '../data/contrat_repository.dart';
import '../data/paiement.dart';

class ContratDetailsController
    extends ChangeNotifier {
  ContratDetailsController({
    required this.contratId,
    ContratRepository? repository,
  }) : _repository =
            repository ?? ContratRepository();

  final String contratId;
  final ContratRepository _repository;

  Contrat? _contrat;
  List<Paiement> _paiements = [];

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  Contrat? get contrat => _contrat;

  List<Paiement> get paiements =>
      List.unmodifiable(_paiements);

  bool get isLoading => _isLoading;

  bool get isSubmitting => _isSubmitting;

  String? get errorMessage => _errorMessage;

  bool get hasError =>
      _errorMessage != null;

  int get nombrePaiements =>
      _paiements.length;

  double get montantTotalPaiements {
    return _paiements.fold<double>(
      0,
      (total, paiement) =>
          total + (paiement.montant ?? 0),
    );
  }

  double get montantTotalPaye {
    return _paiements
        .where((paiement) => paiement.estPaye)
        .fold<double>(
          0,
          (total, paiement) =>
              total + (paiement.montant ?? 0),
        );
  }

  double get montantTotalEnAttente {
    return _paiements
        .where(
          (paiement) =>
              paiement.estEnAttente,
        )
        .fold<double>(
          0,
          (total, paiement) =>
              total + (paiement.montant ?? 0),
        );
  }

  Future<void> charger() async {
    if (contratId.trim().isEmpty) {
      _errorMessage =
          'L’identifiant du contrat est invalide.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat =
          await _repository.details(
        contratId,
      );

      _contrat = resultat.contrat;
      _paiements = resultat.paiements;
    } on ContratException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible de charger le contrat.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> actualiser() async {
    if (contratId.trim().isEmpty) {
      return;
    }

    try {
      _errorMessage = null;

      final resultat =
          await _repository.details(
        contratId,
      );

      _contrat = resultat.contrat;
      _paiements = resultat.paiements;
    } on ContratException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible d’actualiser le contrat.';
    } finally {
      notifyListeners();
    }
  }

  Future<ContratActionResult?>
      mettreAJourContrat({
    String? statut,
    DateTime? dateSignature,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    if (_contrat == null) {
      _errorMessage =
          'Le contrat n’est pas encore chargé.';
      notifyListeners();
      return null;
    }

    if (dateDebut != null &&
        dateFin != null &&
        dateFin.isBefore(dateDebut)) {
      _errorMessage =
          'La date de fin ne peut pas être antérieure à la date de début.';
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat =
          await _repository.mettreAJourStatut(
        contratId: contratId,
        statut: statut,
        dateSignature: dateSignature,
        dateDebut: dateDebut,
        dateFin: dateFin,
      );

      if (resultat.contrat != null) {
        _contrat = resultat.contrat;
      } else {
        final details =
            await _repository.details(
          contratId,
        );

        _contrat = details.contrat;
        _paiements = details.paiements;
      }

      return resultat;
    } on ContratException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Impossible de mettre à jour le contrat.';
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<PaiementActionResult?>
      ajouterPaiement({
    required double? montant,
    String? reference,
    String? description,
    DateTime? dateEcheance,
  }) async {
    if (_contrat == null) {
      _errorMessage =
          'Le contrat n’est pas encore chargé.';
      notifyListeners();
      return null;
    }

    if (montant == null || montant <= 0) {
      _errorMessage =
          'Le montant du paiement doit être supérieur à zéro.';
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat =
          await _repository.ajouterPaiement(
        contratId: contratId,
        montant: montant,
        reference: reference,
        description: description,
        dateEcheance: dateEcheance,
      );

      final details =
          await _repository.details(
        contratId,
      );

      _contrat = details.contrat;
      _paiements = details.paiements;

      return resultat;
    } on ContratException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Impossible d’ajouter le paiement.';
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<PaiementActionResult?>
      validerPaiement(
    String paiementId,
  ) async {
    if (paiementId.trim().isEmpty) {
      _errorMessage =
          'Le paiement sélectionné est invalide.';
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat =
          await _repository.validerPaiement(
        paiementId,
      );

      final details =
          await _repository.details(
        contratId,
      );

      _contrat = details.contrat;
      _paiements = details.paiements;

      return resultat;
    } on ContratException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Impossible de valider le paiement.';
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Paiement? trouverPaiement(
    String paiementId,
  ) {
    for (final paiement in _paiements) {
      if (paiement.id == paiementId) {
        return paiement;
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
}