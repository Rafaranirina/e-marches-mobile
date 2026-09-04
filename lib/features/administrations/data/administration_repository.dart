import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/network/dio_error_mapper.dart';
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

  Future<ListeAdministrationsResult>
      listerGestion() async {
    try {
      final response = await _dio.get(
        '/api/administrations/gestion',
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

  Future<AdministrationMarche> obtenir(
    String administrationId,
  ) async {
    final id = administrationId.trim();

    if (id.isEmpty) {
      throw const AdministrationException(
        'L’administration sélectionnée est invalide.',
      );
    }

    try {
      final response = await _dio.get(
        '/api/administrations/$id',
      );

      final data = _convertirMap(
        response.data,
      );

      final administrationData =
          data['administration'];

      if (administrationData is! Map) {
        throw const AdministrationException(
          'L’administration reçue est invalide.',
        );
      }

      final administration =
          AdministrationMarche.fromJson(
        Map<String, dynamic>.from(
          administrationData,
        ),
      );

      if (administration.id.isEmpty) {
        throw const AdministrationException(
          'L’administration reçue est invalide.',
        );
      }

      return administration;
    } on DioException catch (error) {
      throw AdministrationException(
        _extraireMessageErreur(
          error,
          'Impossible de charger l’administration.',
        ),
      );
    } on AdministrationException {
      rethrow;
    } catch (_) {
      throw const AdministrationException(
        'L’administration reçue est invalide.',
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

  Future<ActionAdministrationResult>
      modifier({
    required String administrationId,
    required DonneesAdministration donnees,
  }) async {
    final id = administrationId.trim();

    if (id.isEmpty) {
      throw const AdministrationException(
        'L’administration sélectionnée est invalide.',
      );
    }

    _validerDonnees(
      donnees,
    );

    try {
      final response = await _dio.put(
        '/api/administrations/$id',
        data: donnees.versJson(),
      );

      final data = _convertirMap(
        response.data,
      );

      return ActionAdministrationResult(
        message: _extraireMessageReponse(
          data,
          'Administration modifiée avec succès.',
        ),
        administration:
            _extraireAdministration(data),
      );
    } on DioException catch (error) {
      throw AdministrationException(
        _extraireMessageErreur(
          error,
          'Impossible de modifier l’administration.',
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

  Future<ActionAdministrationResult>
      changerStatut({
    required String administrationId,
    required bool actif,
  }) async {
    final id = administrationId.trim();

    if (id.isEmpty) {
      throw const AdministrationException(
        'L’administration sélectionnée est invalide.',
      );
    }

    try {
      final response = await _dio.patch(
        '/api/administrations/$id/statut',
        data: {
          'actif': actif,
        },
      );

      final data = _convertirMap(
        response.data,
      );

      return ActionAdministrationResult(
        message: _extraireMessageReponse(
          data,
          actif
              ? 'Administration activée avec succès.'
              : 'Administration désactivée avec succès.',
        ),
        administration:
            _extraireAdministration(data),
      );
    } on DioException catch (error) {
      throw AdministrationException(
        _extraireMessageErreur(
          error,
          'Impossible de modifier le statut de l’administration.',
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

  AdministrationMarche?
      _extraireAdministration(
    Map<String, dynamic> data,
  ) {
    final administrationData =
        data['administration'];

    if (administrationData is! Map) {
      return null;
    }

    return AdministrationMarche.fromJson(
      Map<String, dynamic>.from(
        administrationData,
      ),
    );
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
    return extraireMessageErreur(
      error,
      messageParDefaut,
      messagesParStatut: const {
        400: 'Les informations transmises sont invalides.',
        403: 'Vous n’êtes pas autorisé à gérer les administrations.',
        404: 'L’administration est introuvable.',
        409: 'Cette administration existe déjà.',
      },
    );
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