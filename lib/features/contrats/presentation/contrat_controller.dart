import '../../../shared/presentation/safe_change_notifier.dart';

import '../data/contrat.dart';
import '../data/contrat_repository.dart';

class ContratController extends SafeChangeNotifier {
  ContratController({
    ContratRepository? repository,
  }) : _repository =
            repository ?? ContratRepository();

  final ContratRepository _repository;

  List<Contrat> _contrats = [];

  bool _isLoading = false;
  bool _isRefreshing = false;

  String? _errorMessage;
  String _recherche = '';
  String? _statutSelectionne;

  List<Contrat> get contrats =>
      List.unmodifiable(_contrats);

  bool get isLoading => _isLoading;

  bool get isRefreshing => _isRefreshing;

  String? get errorMessage => _errorMessage;

  bool get hasError =>
      _errorMessage != null;

  String get recherche => _recherche;

  String? get statutSelectionne =>
      _statutSelectionne;

  int get nombreContrats =>
      _contrats.length;

  List<Contrat> get contratsFiltres {
    final rechercheNormalisee =
        _recherche.trim().toLowerCase();

    return _contrats.where((contrat) {
      final correspondStatut =
          _statutSelectionne == null ||
              _statutSelectionne!.isEmpty ||
              contrat.statut
                      .trim()
                      .toLowerCase() ==
                  _statutSelectionne;

      if (!correspondStatut) {
        return false;
      }

      if (rechercheNormalisee.isEmpty) {
        return true;
      }

      final contenu = [
        contrat.reference,
        contrat.objet ?? '',
        contrat.entreprise ?? '',
        contrat.administration ?? '',
        contrat.appelOffre ?? '',
        contrat.statut,
      ].join(' ').toLowerCase();

      return contenu.contains(
        rechercheNormalisee,
      );
    }).toList();
  }

  int nombreParStatut(String statut) {
    final statutNormalise =
        statut.trim().toLowerCase();

    return _contrats.where((contrat) {
      return contrat.statut
              .trim()
              .toLowerCase() ==
          statutNormalise;
    }).length;
  }

  Future<void> charger() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _contrats =
          await _repository.lister();
    } on ContratException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible de charger les contrats.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> actualiser() async {
    if (_isRefreshing) {
      return;
    }

    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _contrats =
          await _repository.lister();
    } on ContratException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible d’actualiser les contrats.';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  void rechercher(String valeur) {
    final nouvelleValeur = valeur.trim();

    if (_recherche == nouvelleValeur) {
      return;
    }

    _recherche = nouvelleValeur;
    notifyListeners();
  }

  void filtrerParStatut(
    String? statut,
  ) {
    final statutNormalise =
        statut?.trim().toLowerCase();

    if (_statutSelectionne ==
        statutNormalise) {
      return;
    }

    _statutSelectionne =
        statutNormalise == null ||
                statutNormalise.isEmpty
            ? null
            : statutNormalise;

    notifyListeners();
  }

  void reinitialiserFiltres() {
    if (_recherche.isEmpty &&
        _statutSelectionne == null) {
      return;
    }

    _recherche = '';
    _statutSelectionne = null;
    notifyListeners();
  }

  void remplacerContrat(
    Contrat contrat,
  ) {
    final index = _contrats.indexWhere(
      (element) =>
          element.id == contrat.id,
    );

    if (index < 0) {
      _contrats.insert(0, contrat);
    } else {
      _contrats[index] = contrat;
    }

    notifyListeners();
  }

  void effacerErreur() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }
}