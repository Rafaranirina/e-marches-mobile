import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'administration_marche.dart';

class AdministrationRepository {
  AdministrationRepository({
    Dio? dio,
  }) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  Future<ListeAdministrationsResult>
      listerAdministrations() async {
    try {
      final response = await _dio.get(
        '/api/administrations',
      );

      final data = _convertirMap(
        response.data,
      );

      return ListeAdministrationsResult.fromJson(
        data,
      );
    } on DioException catch (error) {
      throw AdministrationException(
        _extraireMessageErreur(
          error,
          'Impossible de charger les administrations.',
        ),
      );
    } on AdministrationException {
      rethrow;
    } catch (_) {
      throw const AdministrationException(
        'La liste des administrations reçue est invalide.',
      );
    }
  }

  Future<ActionAdministrationResult>
      creerAdministration(
    DonneesAdministration donnees,
  ) async {
    _validerDonnees(
      donnees,
    );

    try {
      final response = await _dio.post(
        '/api/administrations',
        data: donnees.versJson(),
      );

      final data = _convertirMap(
        response.data,
      );

      final administrationData =
          data['administration'];

      AdministrationMarche? administration;

      if (administrationData is Map) {
        administration =
            AdministrationMarche.fromJson(
          Map<String, dynamic>.from(
            administrationData,
          ),
        );
      }

      return ActionAdministrationResult(
        message: _extraireMessageReponse(
          data,
          'Administration créée avec succès.',
        ),
        administration: administration,
      );
    } on DioException catch (error) {
      throw AdministrationException(
        _extraireMessageErreur(
          error,
          'Impossible de créer l’administration.',
        ),
      );
    } on AdministrationException {
      rethrow;
    } catch (_) {
      throw const AdministrationException(
        'La réponse du serveur est invalide.',
      );
    }
  }

  void _validerDonnees(
    DonneesAdministration donnees,
  ) {
    if (donnees.nom.trim().isEmpty) {
      throw const AdministrationException(
        'Le nom de l’administration est obligatoire.',
      );
    }

    final email = donnees.email.trim();

    if (email.isNotEmpty &&
        !_emailValide(email)) {
      throw const AdministrationException(
        'L’adresse e-mail est invalide.',
      );
    }
  }

  bool _emailValide(
    String email,
  ) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(
      email.trim(),
    );
  }

  Map<String, dynamic> _convertirMap(
    dynamic valeur,
  ) {
    if (valeur is! Map) {
      throw const AdministrationException(
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
        return 'Vous n’êtes pas autorisé à créer une administration.';

      case 409:
        return 'Cette administration existe déjà.';

      case 500:
        return 'Une erreur interne est survenue sur le serveur.';

      default:
        return messageParDefaut;
    }
  }
}

class ActionAdministrationResult {
  const ActionAdministrationResult({
    required this.message,
    this.administration,
  });

  final String message;
  final AdministrationMarche? administration;
}

class AdministrationException
    implements Exception {
  const AdministrationException(
    this.message,
  );

  final String message;

  @override
  String toString() => message;
}