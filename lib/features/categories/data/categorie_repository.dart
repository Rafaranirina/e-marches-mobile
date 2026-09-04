import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/network/dio_error_mapper.dart';
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

  Future<ListeCategoriesResult>
      listerGestion() async {
    try {
      final response = await _dio.get(
        '/api/categories/gestion',
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

  Future<CategorieMarche> obtenirCategorie(
    String categorieId,
  ) async {
    final id = categorieId.trim();

    if (id.isEmpty) {
      throw const CategorieException(
        'La catégorie sélectionnée est invalide.',
      );
    }

    try {
      final response = await _dio.get(
        '/api/categories/$id',
      );

      final data = _convertirMap(
        response.data,
      );

      final categorie =
          _extraireCategorie(data);

      if (categorie == null ||
          categorie.id.isEmpty) {
        throw const CategorieException(
          'La catégorie reçue est invalide.',
        );
      }

      return categorie;
    } on DioException catch (error) {
      throw CategorieException(
        _extraireMessageErreur(
          error,
          'Impossible de charger la catégorie.',
        ),
      );
    } on CategorieException {
      rethrow;
    } catch (_) {
      throw const CategorieException(
        'La catégorie reçue est invalide.',
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

      return ActionCategorieResult(
        message: _extraireMessageReponse(
          data,
          'Catégorie créée avec succès.',
        ),
        categorie:
            _extraireCategorie(data),
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

  Future<ActionCategorieResult>
      modifierCategorie({
    required String categorieId,
    required DonneesCategorie donnees,
  }) async {
    final id = categorieId.trim();

    if (id.isEmpty) {
      throw const CategorieException(
        'La catégorie sélectionnée est invalide.',
      );
    }

    _validerDonnees(
      donnees,
      categorieId: id,
    );

    try {
      final response = await _dio.put(
        '/api/categories/$id',
        data: donnees.versJson(),
      );

      final data = _convertirMap(
        response.data,
      );

      return ActionCategorieResult(
        message: _extraireMessageReponse(
          data,
          'Catégorie modifiée avec succès.',
        ),
        categorie:
            _extraireCategorie(data),
      );
    } on DioException catch (error) {
      throw CategorieException(
        _extraireMessageErreur(
          error,
          'Impossible de modifier la catégorie.',
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

  Future<ActionCategorieResult>
      changerStatut({
    required String categorieId,
    required bool actif,
  }) async {
    final id = categorieId.trim();

    if (id.isEmpty) {
      throw const CategorieException(
        'La catégorie sélectionnée est invalide.',
      );
    }

    try {
      final response = await _dio.patch(
        '/api/categories/$id/statut',
        data: {
          'actif': actif,
        },
      );

      final data = _convertirMap(
        response.data,
      );

      return ActionCategorieResult(
        message: _extraireMessageReponse(
          data,
          actif
              ? 'Catégorie activée avec succès.'
              : 'Catégorie désactivée avec succès.',
        ),
        categorie:
            _extraireCategorie(data),
      );
    } on DioException catch (error) {
      throw CategorieException(
        _extraireMessageErreur(
          error,
          'Impossible de modifier le statut de la catégorie.',
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
    DonneesCategorie donnees, {
    String? categorieId,
  }) {
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

    if (parentId != null &&
        parentId.isNotEmpty &&
        categorieId != null &&
        parentId == categorieId.trim()) {
      throw const CategorieException(
        'Une catégorie ne peut pas être sa propre catégorie parente.',
      );
    }
  }

  CategorieMarche? _extraireCategorie(
    Map<String, dynamic> data,
  ) {
    final categorieData =
        data['categorie'];

    if (categorieData is! Map) {
      return null;
    }

    return CategorieMarche.fromJson(
      Map<String, dynamic>.from(
        categorieData,
      ),
    );
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
    return extraireMessageErreur(
      error,
      messageParDefaut,
      messagesParStatut: const {
        400: 'Les informations transmises sont invalides.',
        403: 'Vous n’êtes pas autorisé à gérer les catégories.',
        404: 'La catégorie est introuvable.',
        409: 'Cette catégorie existe déjà.',
      },
    );
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
