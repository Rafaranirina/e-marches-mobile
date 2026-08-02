import 'package:flutter/foundation.dart';

import '../data/appel_offre.dart';
import '../data/appel_offre_repository.dart';

class AppelOffreController extends ChangeNotifier {
  AppelOffreController({
    AppelOffreRepository? repository,
  }) : _repository = repository ?? AppelOffreRepository();

  final AppelOffreRepository _repository;

  List<AppelOffre> _appelsOffres = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _recherche = '';

  List<AppelOffre> get appelsOffres =>
      List.unmodifiable(_appelsOffres);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String get recherche => _recherche;

  bool get hasError => _errorMessage != null;

  bool get isEmpty => _appelsOffres.isEmpty;

  Future<void> charger({
    String? recherche,
    String? statut,
    String? typeMarche,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    if (recherche != null) {
      _recherche = recherche.trim();
    }

    notifyListeners();

    try {
      _appelsOffres = await _repository.lister(
        recherche: _recherche,
        statut: statut,
        typeMarche: typeMarche,
      );
    } on AppelOffreException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Une erreur inattendue est survenue.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> rechercher(String valeur) async {
    await charger(recherche: valeur);
  }

  Future<void> actualiser() async {
    await charger(recherche: _recherche);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}