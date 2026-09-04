import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/network/dio_error_mapper.dart';
import 'rapport_tableau_bord.dart';

class RapportRepository {
  RapportRepository({
    Dio? dio,
  }) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  Future<RapportTableauBordData>
      chargerTableauBord() async {
    try {
      final statistiques =
          await chargerStatistiques();

      final topEntreprises =
          await chargerTopEntreprises();

      final activitesRecentes =
          await chargerActiviteRecente();

      final transparence =
          await chargerTransparence();

      final activiteMensuelle =
          await chargerActiviteMensuelle();

      return RapportTableauBordData(
        statistiques: statistiques,
        topEntreprises: topEntreprises,
        activitesRecentes:
            activitesRecentes,
        transparence: transparence,
        activiteMensuelle:
            activiteMensuelle,
      );
    } on RapportException {
      rethrow;
    } catch (_) {
      throw const RapportException(
        'Impossible de charger le tableau de bord.',
      );
    }
  }

  Future<StatistiquesTableauBord>
      chargerStatistiques() async {
    try {
      final response = await _dio.get(
        '/api/dashboard/statistiques',
      );

      final data = _convertirMap(
        response.data,
      );

      return StatistiquesTableauBord
          .fromJson(data);
    } on DioException catch (error) {
      throw RapportException(
        _extraireMessageErreur(
          error,
          'Impossible de charger les statistiques.',
        ),
      );
    } on RapportException {
      rethrow;
    } catch (_) {
      throw const RapportException(
        'Les statistiques reçues sont invalides.',
      );
    }
  }

  Future<List<TopEntreprise>>
      chargerTopEntreprises() async {
    try {
      final response = await _dio.get(
        '/api/dashboard/top-entreprises',
      );

      final data = _convertirMap(
        response.data,
      );

      final classement = _convertirListe(
        data['classement'],
      );

      return classement
          .map(TopEntreprise.fromJson)
          .where(
            (entreprise) =>
                entreprise.entreprise.isNotEmpty,
          )
          .toList();
    } on DioException catch (error) {
      throw RapportException(
        _extraireMessageErreur(
          error,
          'Impossible de charger le classement des entreprises.',
        ),
      );
    } on RapportException {
      rethrow;
    } catch (_) {
      throw const RapportException(
        'Le classement reçu est invalide.',
      );
    }
  }

  Future<List<ActiviteRecente>>
      chargerActiviteRecente() async {
    try {
      final response = await _dio.get(
        '/api/dashboard/activite-recente',
      );

      final data = _convertirMap(
        response.data,
      );

      final appelsOffres =
          _convertirListe(
        data['derniers_appels_offres'],
      );

      return appelsOffres
          .map(ActiviteRecente.fromJson)
          .where(
            (activite) =>
                activite.reference.isNotEmpty ||
                activite.titre.isNotEmpty,
          )
          .toList();
    } on DioException catch (error) {
      throw RapportException(
        _extraireMessageErreur(
          error,
          'Impossible de charger les activités récentes.',
        ),
      );
    } on RapportException {
      rethrow;
    } catch (_) {
      throw const RapportException(
        'Les activités reçues sont invalides.',
      );
    }
  }

  Future<IndicateursTransparence>
      chargerTransparence() async {
    try {
      final response = await _dio.get(
        '/api/dashboard/transparence',
      );

      final data = _convertirMap(
        response.data,
      );

      final transparence = _convertirMap(
        data['transparence'],
      );

      return IndicateursTransparence
          .fromJson(transparence);
    } on DioException catch (error) {
      throw RapportException(
        _extraireMessageErreur(
          error,
          'Impossible de charger les indicateurs de transparence.',
        ),
      );
    } on RapportException {
      rethrow;
    } catch (_) {
      throw const RapportException(
        'Les indicateurs de transparence reçus sont invalides.',
      );
    }
  }

  Future<List<ActiviteMensuelle>>
      chargerActiviteMensuelle() async {
    try {
      final response = await _dio.get(
        '/api/dashboard/activite-mensuelle',
      );

      final data = _convertirMap(
        response.data,
      );

      final activiteMensuelle =
          _convertirListe(
        data['activite_mensuelle'],
      );

      return activiteMensuelle
          .map(ActiviteMensuelle.fromJson)
          .toList();
    } on DioException catch (error) {
      throw RapportException(
        _extraireMessageErreur(
          error,
          'Impossible de charger l’activité mensuelle.',
        ),
      );
    } on RapportException {
      rethrow;
    } catch (_) {
      throw const RapportException(
        'L’activité mensuelle reçue est invalide.',
      );
    }
  }

  Map<String, dynamic> _convertirMap(
    dynamic valeur,
  ) {
    if (valeur is! Map) {
      throw const RapportException(
        'La réponse du serveur est invalide.',
      );
    }

    return Map<String, dynamic>.from(
      valeur,
    );
  }

  List<Map<String, dynamic>>
      _convertirListe(
    dynamic valeur,
  ) {
    if (valeur == null) {
      return <Map<String, dynamic>>[];
    }

    if (valeur is! List) {
      throw const RapportException(
        'La liste reçue du serveur est invalide.',
      );
    }

    return valeur
        .whereType<Map>()
        .map(
          (element) =>
              Map<String, dynamic>.from(
            element,
          ),
        )
        .toList();
  }

  String _extraireMessageErreur(
    DioException error,
    String messageParDefaut,
  ) {
    return extraireMessageErreur(
      error,
      messageParDefaut,
      messagesParStatut: const {
        403: 'Vous n’êtes pas autorisé à consulter ces rapports.',
        404: 'Le service de rapports est introuvable.',
      },
    );
  }
}

class RapportTableauBordData {
  const RapportTableauBordData({
    required this.statistiques,
    required this.topEntreprises,
    required this.activitesRecentes,
    required this.transparence,
    required this.activiteMensuelle,
  });

  final StatistiquesTableauBord statistiques;
  final List<TopEntreprise> topEntreprises;
  final List<ActiviteRecente> activitesRecentes;
  final IndicateursTransparence transparence;
  final List<ActiviteMensuelle> activiteMensuelle;
}

class RapportException implements Exception {
  const RapportException(
    this.message,
  );

  final String message;

  @override
  String toString() => message;
}