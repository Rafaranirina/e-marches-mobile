import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
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

      return RapportTableauBordData(
        statistiques: statistiques,
        topEntreprises: topEntreprises,
        activitesRecentes:
            activitesRecentes,
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
    final responseData =
        error.response?.data;

    if (responseData is Map) {
      final message =
          responseData['message']
              ?.toString()
              .trim();

      if (message != null &&
          message.isNotEmpty) {
        return message;
      }
    }

    if (error.type ==
            DioExceptionType
                .connectionTimeout ||
        error.type ==
            DioExceptionType
                .receiveTimeout ||
        error.type ==
            DioExceptionType
                .sendTimeout) {
      return 'Le serveur met trop de temps à répondre.';
    }

    if (error.type ==
        DioExceptionType.connectionError) {
      return 'Connexion au serveur impossible.';
    }

    switch (error.response?.statusCode) {
      case 401:
        return 'Votre session a expiré. Reconnectez-vous.';

      case 403:
        return 'Vous n’êtes pas autorisé à consulter ces rapports.';

      case 404:
        return 'Le service de rapports est introuvable.';

      default:
        return messageParDefaut;
    }
  }
}

class RapportTableauBordData {
  const RapportTableauBordData({
    required this.statistiques,
    required this.topEntreprises,
    required this.activitesRecentes,
  });

  final StatistiquesTableauBord statistiques;
  final List<TopEntreprise> topEntreprises;
  final List<ActiviteRecente> activitesRecentes;
}

class RapportException implements Exception {
  const RapportException(
    this.message,
  );

  final String message;

  @override
  String toString() => message;
}