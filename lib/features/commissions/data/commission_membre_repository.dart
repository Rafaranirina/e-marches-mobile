import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../utilisateurs/data/utilisateur_gestion.dart';

class CommissionMembreRepository {
  CommissionMembreRepository({
    Dio? dio,
  }) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  Future<List<UtilisateurGestion>> listerMembresDisponibles() async {
    try {
      final response = await _dio.get(
        '/api/users/membres-commission',
      );

      final data = _convertirMap(response.data);
      final utilisateurs = _extraireUtilisateurs(data);

      utilisateurs.sort(
        (a, b) => a.nomComplet.toLowerCase().compareTo(
              b.nomComplet.toLowerCase(),
            ),
      );

      return utilisateurs;
    } on DioException catch (error) {
      throw CommissionMembreException(
        _extraireMessageErreur(
          error,
          'Impossible de charger les membres disponibles.',
        ),
      );
    } on CommissionMembreException {
      rethrow;
    } catch (_) {
      throw const CommissionMembreException(
        'La liste des membres reçue est invalide.',
      );
    }
  }

  List<UtilisateurGestion> _extraireUtilisateurs(
    Map<String, dynamic> data,
  ) {
    dynamic liste = data['utilisateurs'];

    liste ??= data['membres'];
    liste ??= data['users'];

    if (liste is! List) {
      return <UtilisateurGestion>[];
    }

    return liste
        .whereType<Map>()
        .map(
          (element) => UtilisateurGestion.fromJson(
            Map<String, dynamic>.from(element),
          ),
        )
        .where(
          (utilisateur) =>
              utilisateur.id.isNotEmpty &&
              utilisateur.email.isNotEmpty,
        )
        .toList();
  }

  Map<String, dynamic> _convertirMap(
    dynamic valeur,
  ) {
    if (valeur is! Map) {
      throw const CommissionMembreException(
        'La réponse du serveur est invalide.',
      );
    }

    return Map<String, dynamic>.from(valeur);
  }

  String _extraireMessageErreur(
    DioException error,
    String messageParDefaut,
  ) {
    final responseData = error.response?.data;

    if (responseData is Map) {
      final message = responseData['message']
              ?.toString()
              .trim() ??
          '';

      if (message.isNotEmpty) {
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

    switch (error.response?.statusCode) {
      case 400:
        return 'La demande transmise est invalide.';

      case 401:
        return 'Votre session a expiré. Reconnectez-vous.';

      case 403:
        return 'Vous n’êtes pas autorisé à consulter les membres de commission.';

      case 404:
        return 'La route des membres de commission est introuvable.';

      case 500:
        return 'Une erreur interne est survenue sur le serveur.';

      default:
        return messageParDefaut;
    }
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