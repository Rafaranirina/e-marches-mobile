import 'package:flutter/foundation.dart';

import '../data/fournisseur.dart';
import '../data/fournisseur_repository.dart';

class FournisseurController extends ChangeNotifier {
  FournisseurController({
    FournisseurRepository? repository,
  }) : _repository = repository ?? FournisseurRepository();

  final FournisseurRepository _repository;

  List<Fournisseur> _fournisseurs = [];
  final Set<String> _validationsEnCours = {};
  String _recherche = '';
  bool _isLoading = false;
  String? _errorMessage;

  List<Fournisseur> get fournisseurs {
    final rechercheNormalisee =
        _recherche.trim().toLowerCase();

    if (rechercheNormalisee.isEmpty) {
      return List.unmodifiable(_fournisseurs);
    }

    return _fournisseurs.where((fournisseur) {
      final raisonSociale =
          fournisseur.raisonSociale.toLowerCase();

      final nif =
          fournisseur.nif?.toLowerCase() ?? '';

      final stat =
          fournisseur.stat?.toLowerCase() ?? '';

      final statutValidation =
          fournisseur.statutValidation?.toLowerCase() ?? '';

      return raisonSociale.contains(rechercheNormalisee) ||
          nif.contains(rechercheNormalisee) ||
          stat.contains(rechercheNormalisee) ||
          statutValidation.contains(rechercheNormalisee);
    }).toList();
  }

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get hasError => _errorMessage != null;

  String get recherche => _recherche;

  int get nombreTotal => _fournisseurs.length;

  Future<void> charger() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _fournisseurs = await _repository.lister();
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
    try {
      _errorMessage = null;
      _fournisseurs = await _repository.lister();
    } on FournisseurException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible d’actualiser les fournisseurs.';
    } finally {
      notifyListeners();
    }
  }

  void rechercher(String valeur) {
    _recherche = valeur;
    notifyListeners();
  }

  void effacerRecherche() {
    _recherche = '';
    notifyListeners();
  }

  bool validationEnCours(String entrepriseId) {
    return _validationsEnCours.contains(entrepriseId);
  }

  Future<String?> validerEntreprise(String entrepriseId) async {
    if (_validationsEnCours.contains(entrepriseId)) {
      return null;
    }

    _validationsEnCours.add(entrepriseId);
    _errorMessage = null;
    notifyListeners();

    try {
      final message =
          await _repository.validerEntreprise(entrepriseId: entrepriseId);

      final index = _fournisseurs.indexWhere(
        (fournisseur) => fournisseur.id == entrepriseId,
      );

      if (index >= 0) {
        _fournisseurs[index] = Fournisseur(
          id: _fournisseurs[index].id,
          raisonSociale: _fournisseurs[index].raisonSociale,
          nif: _fournisseurs[index].nif,
          stat: _fournisseurs[index].stat,
          statutValidation: 'actif',
          dateCreation: _fournisseurs[index].dateCreation,
        );
      }

      return message;
    } on FournisseurException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage = 'Impossible de valider cette entreprise.';
      return null;
    } finally {
      _validationsEnCours.remove(entrepriseId);
      notifyListeners();
    }
  }
}