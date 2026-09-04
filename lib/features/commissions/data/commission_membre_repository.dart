import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/network/dio_error_mapper.dart';
import '../../utilisateurs/data/utilisateur_gestion.dart';

class CommissionMembreRepository {
  CommissionMembreRepository({
    Dio? dio,
  }) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  Future<List<UtilisateurGestion>> listerMembresDisponibles() async {
    try {
      final response = await _dio.get(
        '/api/users/eligibles-commission',
      );

      final data = response.data;

      if (data is! Map) {
        throw const CommissionMembreException(
          'Réponse invalide du serveur.',
        );
      }

      final liste = data['utilisateurs'];

      if (liste is! List) {
        throw const CommissionMembreException(
          'La liste des membres éligibles est invalide.',
        );
      }

      return liste
          .whereType<Map>()
          .map(
            (item) => UtilisateurGestion.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where(
            (utilisateur) =>
                utilisateur.id.isNotEmpty &&
                utilisateur.email.isNotEmpty,
          )
          .toList();
    } on CommissionMembreException {
      rethrow;
    } on DioException catch (error) {
      throw CommissionMembreException(
        _extraireMessageErreur(error),
      );
    } catch (_) {
      throw const CommissionMembreException(
        'Une erreur inattendue est survenue.',
      );
    }
  }

  String _extraireMessageErreur(
    DioException error,
  ) {
    return extraireMessageErreur(
      error,
      'Impossible de récupérer les membres éligibles à une commission.',
      messagesParStatut: const {
        403: 'Vous n’êtes pas autorisé à consulter les membres éligibles.',
      },
    );
  }
}

class CommissionMembreException implements Exception {
  const CommissionMembreException(
    this.message,
  );

  final String message;

  @override
  String toString() => message;
}
