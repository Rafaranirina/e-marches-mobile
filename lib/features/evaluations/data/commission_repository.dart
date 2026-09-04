import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/models/commission.dart';
import '../../../shared/network/dio_error_mapper.dart';

class CommissionRepository {
  CommissionRepository({
    Dio? dio,
  }) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  Future<List<Commission>> listerParAppelOffre(
    String appelOffreId,
  ) async {
    if (appelOffreId.trim().isEmpty) {
      throw const CommissionException(
        'L’identifiant de l’appel d’offres est invalide.',
      );
    }

    try {
      final response = await _dio.get(
        '/api/commissions/appel-offre/${appelOffreId.trim()}',
      );

      final data = _convertirReponse(
        response.data,
      );

      final liste = data['commissions'];

      if (liste is! List) {
        throw const CommissionException(
          'La liste des commissions est invalide.',
        );
      }

      return liste
          .whereType<Map>()
          .map(
            (item) => Commission.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where(
            (commission) =>
                commission.id.isNotEmpty &&
                commission.nom.isNotEmpty,
          )
          .toList();
    } on CommissionException {
      rethrow;
    } on DioException catch (error) {
      throw CommissionException(
        _extraireMessageErreur(
          error,
          'Impossible de récupérer les commissions.',
        ),
      );
    } catch (_) {
      throw const CommissionException(
        'Une erreur inattendue est survenue.',
      );
    }
  }

  Map<String, dynamic> _convertirReponse(
    dynamic responseData,
  ) {
    if (responseData is! Map) {
      throw const CommissionException(
        'Réponse invalide du serveur.',
      );
    }

    return Map<String, dynamic>.from(
      responseData,
    );
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
        404: 'La commission, l’utilisateur ou l’appel d’offres est introuvable.',
        409: 'Cette opération a déjà été effectuée.',
      },
    );
  }
}

class CommissionException implements Exception {
  const CommissionException(
    this.message,
  );

  final String message;

  @override
  String toString() => message;
}
