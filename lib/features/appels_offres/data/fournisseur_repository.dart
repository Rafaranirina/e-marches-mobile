import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'fournisseur.dart';

class FournisseurRepository {
  FournisseurRepository({
    Dio? dio,
  }) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  Future<List<Fournisseur>> lister() async {
    try {
      final response = await _dio.get(
        '/api/entreprises',
      );

      final data = response.data;

      if (data is! Map) {
        throw const FournisseurException(
          'Réponse invalide du serveur.',
        );
      }

      final json = Map<String, dynamic>.from(data);
      final liste = json['entreprises'];

      if (liste is! List) {
        throw const FournisseurException(
          'La liste des fournisseurs est invalide.',
        );
      }

      return liste
          .whereType<Map>()
          .map(
            (item) => Fournisseur.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where(
            (fournisseur) =>
                fournisseur.id.isNotEmpty &&
                fournisseur.raisonSociale.isNotEmpty,
          )
          .toList();
    } on FournisseurException {
      rethrow;
    } on DioException catch (error) {
      throw FournisseurException(
        _extraireMessageErreur(
          error,
          'Impossible de récupérer les fournisseurs.',
        ),
      );
    } catch (_) {
      throw const FournisseurException(
        'Une erreur inattendue est survenue.',
      );
    }
  }

  String _extraireMessageErreur(
    DioException error,
    String messageParDefaut,
  ) {
    final responseData = error.response?.data;

    if (responseData is Map) {
      final message =
          responseData['message']?.toString().trim();

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

    if (error.response?.statusCode == 401) {
      return 'Votre session a expiré. Reconnectez-vous.';
    }

    if (error.response?.statusCode == 403) {
      return 'Vous n’êtes pas autorisé à consulter les fournisseurs.';
    }

    return messageParDefaut;
  }
}

class FournisseurException implements Exception {
  const FournisseurException(this.message);

  final String message;

  @override
  String toString() => message;
}