import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'categorie_marche.dart';

class CategorieRepository {
  CategorieRepository({
    Dio? dio,
  }) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  Future<ListeCategoriesResult>
      listerCategories() async {
    try {
      final response = await _dio.get(
        '/api/categories',
      );

      final data = _convertirMap(
        response.data,
      );

      return ListeCategoriesResult.fromJson(
        data,
      );
    } on DioException catch (error) {
      throw CategorieException(
        _extraireMessageErreur(
          error,
          'Impossible de charger les catégories.',
        ),
      );
    } on CategorieException {
      rethrow;
    } catch (_) {
      throw const CategorieException(
        'La liste des catégories reçue est invalide.',
      );
    }
  }

  Future<ActionCategorieResult>
      creerCategorie(
    DonneesCategorie donnees,
  ) async {
    _validerDonnees(donnees);

    try {
      final response = await _dio.post(
        '/api/categories',
        data: donnees.versJson(),
      );

      final data = _convertirMap(
        response.data,
      );

      final categorieData =
          data['categorie'];

      CategorieMarche? categorie;

      if (categorieData is Map) {
        categorie =
            CategorieMarche.fromJson(
          Map<String, dynamic>.from(
            categorieData,
          ),
        );
      }

      return ActionCategorieResult(
        message: _extraireMessageReponse(
          data,
          'Catégorie créée avec succès.',
        ),
        categorie: categorie,
      );
    } on DioException catch (error) {
      throw CategorieException(
        _extraireMessageErreur(
          error,
          'Impossible de créer la catégorie.',
        ),
      );
    } on CategorieException {
      rethrow;
    } catch (_) {
      throw const CategorieException(
        'La réponse du serveur est invalide.',
      );
    }
  }

  void _validerDonnees(
    DonneesCategorie donnees,
  ) {
    if (donnees.nom.trim().isEmpty) {
      throw const CategorieException(
        'Le nom de la catégorie est obligatoire.',
      );
    }

    final parentId =
        donnees.categorieParentId?.trim();

    if (parentId != null &&
        parentId.isNotEmpty &&
        parentId == donnees.nom.trim()) {
      throw const CategorieException(
        'La catégorie parente est invalide.',
      );
    }
  }

  Map<String, dynamic> _convertirMap(
    dynamic valeur,
  ) {
    if (valeur is! Map) {
      throw const CategorieException(
        'La réponse du serveur est invalide.',
      );
    }

    return Map<String, dynamic>.from(
      valeur,
    );
  }

  String _extraireMessageReponse(
    Map<String, dynamic> data,
    String messageParDefaut,
  ) {
    final message =
        data['message']?.toString().trim() ?? '';

    return message.isEmpty
        ? messageParDefaut
        : message;
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
            DioExceptionType.connectionTimeout ||
        error.type ==
            DioExceptionType.receiveTimeout ||
        error.type ==
            DioExceptionType.sendTimeout) {
      return 'Le serveur met trop de temps à répondre.';
    }

    if (error.type ==
        DioExceptionType.connectionError) {
      return 'Connexion au serveur impossible.';
    }

    switch (error.response?.statusCode) {
      case 400:
        return 'Les informations transmises sont invalides.';

      case 401:
        return 'Votre session a expiré. Reconnectez-vous.';

      case 403:
        return 'Vous n’êtes pas autorisé à créer une catégorie.';

      case 409:
        return 'Cette catégorie existe déjà.';

      case 500:
        return 'Une erreur interne est survenue sur le serveur.';

      default:
        return messageParDefaut;
    }
  }
}

class ActionCategorieResult {
  const ActionCategorieResult({
    required this.message,
    this.categorie,
  });

  final String message;
  final CategorieMarche? categorie;
}

class CategorieException
    implements Exception {
  const CategorieException(
    this.message,
  );

  final String message;

  @override
  String toString() => message;
}