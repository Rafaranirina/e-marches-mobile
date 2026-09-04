import '../../../shared/presentation/safe_change_notifier.dart';

import '../data/rapport_repository.dart';
import '../data/rapport_tableau_bord.dart';

class RapportController extends SafeChangeNotifier {
  RapportController({
    RapportRepository? repository,
  }) : _repository =
            repository ?? RapportRepository();

  final RapportRepository _repository;

  StatistiquesTableauBord _statistiques =
      StatistiquesTableauBord.vide;

  List<TopEntreprise> _topEntreprises = [];
  List<ActiviteRecente> _activitesRecentes = [];

  IndicateursTransparence _transparence =
      IndicateursTransparence.vide;

  List<ActiviteMensuelle> _activiteMensuelle = [];

  bool _isLoading = false;
  bool _isRefreshing = false;

  String? _errorMessage;

  StatistiquesTableauBord get statistiques =>
      _statistiques;

  List<TopEntreprise> get topEntreprises =>
      List.unmodifiable(_topEntreprises);

  List<ActiviteRecente> get activitesRecentes =>
      List.unmodifiable(_activitesRecentes);

  IndicateursTransparence get transparence =>
      _transparence;

  List<ActiviteMensuelle> get activiteMensuelle =>
      List.unmodifiable(_activiteMensuelle);

  bool get isLoading => _isLoading;

  bool get isRefreshing => _isRefreshing;

  bool get isBusy =>
      _isLoading || _isRefreshing;

  String? get errorMessage => _errorMessage;

  bool get hasError =>
      _errorMessage != null &&
      _errorMessage!.trim().isNotEmpty;

  bool get hasData =>
      _statistiques.totalAppelsOffres > 0 ||
      _statistiques.totalSoumissions > 0 ||
      _statistiques.totalContrats > 0 ||
      _statistiques.totalEntreprises > 0 ||
      _statistiques.montantTotalContrats > 0 ||
      _topEntreprises.isNotEmpty ||
      _activitesRecentes.isNotEmpty ||
      _transparence.nombreMarchesAttribues > 0 ||
      _transparence.nombreAttribues > 0 ||
      _transparence.nombreInfructueux > 0 ||
      _activiteMensuelle.isNotEmpty;

  Future<void> charger() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat =
          await _repository.chargerTableauBord();

      _appliquerResultat(resultat);
    } on RapportException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible de charger les rapports.';
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
          await _repository.chargerTableauBord();

      _appliquerResultat(resultat);
    } on RapportException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible d’actualiser les rapports.';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> chargerStatistiques() async {
    try {
      _errorMessage = null;

      _statistiques =
          await _repository.chargerStatistiques();

      notifyListeners();
    } on RapportException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
    } catch (_) {
      _errorMessage =
          'Impossible de charger les statistiques.';
      notifyListeners();
    }
  }

  Future<void> chargerTopEntreprises() async {
    try {
      _errorMessage = null;

      _topEntreprises =
          await _repository.chargerTopEntreprises();

      notifyListeners();
    } on RapportException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
    } catch (_) {
      _errorMessage =
          'Impossible de charger le classement des entreprises.';
      notifyListeners();
    }
  }

  Future<void> chargerActivitesRecentes() async {
    try {
      _errorMessage = null;

      _activitesRecentes =
          await _repository.chargerActiviteRecente();

      notifyListeners();
    } on RapportException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
    } catch (_) {
      _errorMessage =
          'Impossible de charger les activités récentes.';
      notifyListeners();
    }
  }

  Future<void> chargerTransparence() async {
    try {
      _errorMessage = null;

      _transparence =
          await _repository.chargerTransparence();

      notifyListeners();
    } on RapportException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
    } catch (_) {
      _errorMessage =
          'Impossible de charger les indicateurs de transparence.';
      notifyListeners();
    }
  }

  Future<void> chargerActiviteMensuelle() async {
    try {
      _errorMessage = null;

      _activiteMensuelle = await _repository
          .chargerActiviteMensuelle();

      notifyListeners();
    } on RapportException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
    } catch (_) {
      _errorMessage =
          'Impossible de charger l’activité mensuelle.';
      notifyListeners();
    }
  }

  void effacerErreur() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  void _appliquerResultat(
    RapportTableauBordData resultat,
  ) {
    _statistiques = resultat.statistiques;

    _topEntreprises = List<TopEntreprise>.from(
      resultat.topEntreprises,
    );

    _activitesRecentes =
        List<ActiviteRecente>.from(
      resultat.activitesRecentes,
    );

    _transparence = resultat.transparence;

    _activiteMensuelle =
        List<ActiviteMensuelle>.from(
      resultat.activiteMensuelle,
    );
  }
}