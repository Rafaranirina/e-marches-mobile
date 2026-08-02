import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'appel_offre.dart';
import 'appel_offre_referentiels.dart';

class AppelOffreRepository {
  AppelOffreRepository({
    Dio? dio,
  }) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  Future<List<AppelOffre>> lister({
    String? statut,
    String? typeMarche,
    String? categorieId,
    String? recherche,
  }) async {
    try {
      final response = await _dio.get(
        '/api/appels-offres',
        queryParameters: {
          if (_isNotEmpty(statut)) 'statut': statut!.trim(),
          if (_isNotEmpty(typeMarche))
            'type_marche': typeMarche!.trim(),
          if (_isNotEmpty(categorieId))
            'categorie_id': categorieId!.trim(),
          if (_isNotEmpty(recherche))
            'recherche': recherche!.trim(),
        },
      );

      final data = _mapResponse(response.data);
      final liste = data['appels_offres'];

      if (liste is! List) {
        throw const AppelOffreException(
          'La liste des appels d’offres est invalide.',
        );
      }

      return liste
          .whereType<Map>()
          .map(
            (item) => AppelOffre.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw AppelOffreException(
        _extractErrorMessage(
          error,
          'Impossible de récupérer les appels d’offres.',
        ),
      );
    }
  }

  Future<AppelOffre> details(String id) async {
    try {
      final response = await _dio.get(
        '/api/appels-offres/$id',
      );

      final data = _mapResponse(response.data);
      final appelOffreJson = data['appel_offre'];

      if (appelOffreJson is! Map) {
        throw const AppelOffreException(
          'Les informations de l’appel d’offres sont invalides.',
        );
      }

      return AppelOffre.fromJson(
        Map<String, dynamic>.from(appelOffreJson),
      );
    } on DioException catch (error) {
      throw AppelOffreException(
        _extractErrorMessage(
          error,
          'Impossible de récupérer cet appel d’offres.',
        ),
      );
    }
  }

  Future<List<AdministrationOption>> listerAdministrations() async {
    try {
      final response = await _dio.get(
        '/api/administrations',
      );

      final data = _mapResponse(response.data);
      final liste = data['administrations'];

      if (liste is! List) {
        throw const AppelOffreException(
          'La liste des administrations est invalide.',
        );
      }

      return liste
          .whereType<Map>()
          .map(
            (item) => AdministrationOption.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where(
            (administration) =>
                administration.id.isNotEmpty &&
                administration.nom.isNotEmpty,
          )
          .toList();
    } on DioException catch (error) {
      throw AppelOffreException(
        _extractErrorMessage(
          error,
          'Impossible de récupérer les administrations.',
        ),
      );
    }
  }

  Future<List<CategorieOption>> listerCategories() async {
    try {
      final response = await _dio.get(
        '/api/categories',
      );

      final data = _mapResponse(response.data);
      final liste = data['categories'];

      if (liste is! List) {
        throw const AppelOffreException(
          'La liste des catégories est invalide.',
        );
      }

      return liste
          .whereType<Map>()
          .map(
            (item) => CategorieOption.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where(
            (categorie) =>
                categorie.id.isNotEmpty &&
                categorie.nom.isNotEmpty,
          )
          .toList();
    } on DioException catch (error) {
      throw AppelOffreException(
        _extractErrorMessage(
          error,
          'Impossible de récupérer les catégories.',
        ),
      );
    }
  }

  Future<AppelOffreActionResult> creer({
    required String reference,
    required String titre,
    required String typeMarche,
    required String administrationId,
    String? description,
    String? categorieId,
    double? montantEstime,
    DateTime? dateLimiteSoumission,
    DateTime? dateOuverturePlis,
  }) async {
    try {
      final response = await _dio.post(
        '/api/appels-offres',
        data: _buildPayload(
          reference: reference,
          titre: titre,
          description: description,
          typeMarche: typeMarche,
          categorieId: categorieId,
          administrationId: administrationId,
          montantEstime: montantEstime,
          dateLimiteSoumission: dateLimiteSoumission,
          dateOuverturePlis: dateOuverturePlis,
        ),
      );

      return _parseActionResult(response.data);
    } on DioException catch (error) {
      throw AppelOffreException(
        _extractErrorMessage(
          error,
          'Impossible de créer l’appel d’offres.',
        ),
      );
    }
  }

  Future<AppelOffreActionResult> modifier({
    required String id,
    required String reference,
    required String titre,
    required String typeMarche,
    required String administrationId,
    String? description,
    String? categorieId,
    double? montantEstime,
    DateTime? dateLimiteSoumission,
    DateTime? dateOuverturePlis,
  }) async {
    try {
      final response = await _dio.patch(
        '/api/appels-offres/$id',
        data: _buildPayload(
          reference: reference,
          titre: titre,
          description: description,
          typeMarche: typeMarche,
          categorieId: categorieId,
          administrationId: administrationId,
          montantEstime: montantEstime,
          dateLimiteSoumission: dateLimiteSoumission,
          dateOuverturePlis: dateOuverturePlis,
        ),
      );

      return _parseActionResult(response.data);
    } on DioException catch (error) {
      throw AppelOffreException(
        _extractErrorMessage(
          error,
          'Impossible de modifier l’appel d’offres.',
        ),
      );
    }
  }

  Future<AppelOffreActionResult> publier(String id) async {
    try {
      final response = await _dio.patch(
        '/api/appels-offres/$id/publier',
      );

      return _parseActionResult(response.data);
    } on DioException catch (error) {
      throw AppelOffreException(
        _extractErrorMessage(
          error,
          'Impossible de publier l’appel d’offres.',
        ),
      );
    }
  }

  Map<String, dynamic> _buildPayload({
    required String reference,
    required String titre,
    required String typeMarche,
    required String administrationId,
    String? description,
    String? categorieId,
    double? montantEstime,
    DateTime? dateLimiteSoumission,
    DateTime? dateOuverturePlis,
  }) {
    return {
      'reference': reference.trim(),
      'titre': titre.trim(),
      'description': _nullableString(description),
      'type_marche': typeMarche.trim(),
      'categorie_id': _nullableString(categorieId),
      'administration_id': administrationId.trim(),
      'montant_estime': montantEstime,
      'date_limite_soumission':
          dateLimiteSoumission?.toIso8601String(),
      'date_ouverture_plis':
          dateOuverturePlis?.toIso8601String(),
    };
  }

  AppelOffreActionResult _parseActionResult(dynamic responseData) {
    final data = _mapResponse(responseData);
    final appelOffreJson = data['appel_offre'];

    return AppelOffreActionResult(
      message: data['message']?.toString() ??
          'Opération réalisée avec succès.',
      appelOffre: appelOffreJson is Map
          ? AppelOffre.fromJson(
              Map<String, dynamic>.from(appelOffreJson),
            )
          : null,
    );
  }

  Map<String, dynamic> _mapResponse(dynamic responseData) {
    if (responseData is! Map) {
      throw const AppelOffreException(
        'Réponse invalide du serveur.',
      );
    }

    return Map<String, dynamic>.from(responseData);
  }

  String _extractErrorMessage(
    DioException error,
    String defaultMessage,
  ) {
    final responseData = error.response?.data;

    if (responseData is Map) {
      final message = responseData['message']?.toString().trim();

      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Le serveur met trop de temps à répondre.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Connexion au serveur impossible.';
    }

    return defaultMessage;
  }

  static bool _isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  static String? _nullableString(String? value) {
    final texte = value?.trim() ?? '';

    return texte.isEmpty ? null : texte;
  }
}

class AppelOffreActionResult {
  const AppelOffreActionResult({
    required this.message,
    this.appelOffre,
  });

  final String message;
  final AppelOffre? appelOffre;
}

class AppelOffreException implements Exception {
  const AppelOffreException(this.message);

  final String message;

  @override
  String toString() => message;
}