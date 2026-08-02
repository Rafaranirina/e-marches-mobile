import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'utilisateur_gestion.dart';

class UtilisateurRepository {
  UtilisateurRepository({
    Dio? dio,
  }) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  Future<ListeUtilisateursResult>
      listerUtilisateurs() async {
    try {
      final response = await _dio.get(
        '/api/users',
      );

      final data = _convertirMap(
        response.data,
      );

      return ListeUtilisateursResult.fromJson(
        data,
      );
    } on DioException catch (error) {
      throw UtilisateurException(
        _extraireMessageErreur(
          error,
          'Impossible de charger les utilisateurs.',
        ),
      );
    } on UtilisateurException {
      rethrow;
    } catch (_) {
      throw const UtilisateurException(
        'La liste des utilisateurs reçue est invalide.',
      );
    }
  }

  Future<UtilisateurGestion>
      chargerProfil() async {
    try {
      final response = await _dio.get(
        '/api/users/profil',
      );

      final data = _convertirMap(
        response.data,
      );

      final utilisateurData =
          data['utilisateur'];

      if (utilisateurData is! Map) {
        throw const UtilisateurException(
          'Le profil reçu est invalide.',
        );
      }

      final utilisateur =
          UtilisateurGestion.fromJson(
        Map<String, dynamic>.from(
          utilisateurData,
        ),
      );

      if (utilisateur.id.isEmpty ||
          utilisateur.email.isEmpty) {
        throw const UtilisateurException(
          'Le profil reçu est incomplet.',
        );
      }

      return utilisateur;
    } on DioException catch (error) {
      throw UtilisateurException(
        _extraireMessageErreur(
          error,
          'Impossible de charger le profil.',
        ),
      );
    } on UtilisateurException {
      rethrow;
    } catch (_) {
      throw const UtilisateurException(
        'Le profil reçu est invalide.',
      );
    }
  }

  Future<ActionUtilisateurResult>
      creerUtilisateur(
    DonneesUtilisateur donnees,
  ) async {
    _validerDonneesUtilisateur(
      donnees,
      creation: true,
    );

    try {
      final response = await _dio.post(
        '/api/users',
        data: donnees.versJsonCreation(),
      );

      final data = _convertirMap(
        response.data,
      );

      return ActionUtilisateurResult(
        message: _extraireMessageReponse(
          data,
          'Compte créé avec succès.',
        ),
        utilisateur:
            _extraireUtilisateur(data),
      );
    } on DioException catch (error) {
      throw UtilisateurException(
        _extraireMessageErreur(
          error,
          'Impossible de créer le compte.',
        ),
      );
    } on UtilisateurException {
      rethrow;
    } catch (_) {
      throw const UtilisateurException(
        'La réponse du serveur est invalide.',
      );
    }
  }

  Future<ActionUtilisateurResult>
      modifierUtilisateur({
    required String utilisateurId,
    required DonneesUtilisateur donnees,
  }) async {
    final id = utilisateurId.trim();

    if (id.isEmpty) {
      throw const UtilisateurException(
        'L’utilisateur sélectionné est invalide.',
      );
    }

    _validerDonneesUtilisateur(
      donnees,
      creation: false,
    );

    try {
      final response = await _dio.put(
        '/api/users/$id',
        data:
            donnees.versJsonModification(),
      );

      final data = _convertirMap(
        response.data,
      );

      return ActionUtilisateurResult(
        message: _extraireMessageReponse(
          data,
          'Compte modifié avec succès.',
        ),
        utilisateur:
            _extraireUtilisateur(data),
      );
    } on DioException catch (error) {
      throw UtilisateurException(
        _extraireMessageErreur(
          error,
          'Impossible de modifier le compte.',
        ),
      );
    } on UtilisateurException {
      rethrow;
    } catch (_) {
      throw const UtilisateurException(
        'La réponse du serveur est invalide.',
      );
    }
  }

  Future<ActionUtilisateurResult>
      changerStatut({
    required String utilisateurId,
    required String statut,
  }) async {
    final id = utilisateurId.trim();

    final statutNormalise =
        statut.trim().toLowerCase();

    if (id.isEmpty) {
      throw const UtilisateurException(
        'L’utilisateur sélectionné est invalide.',
      );
    }

    if (!UtilisateurGestion
        .statutsAutorises
        .contains(statutNormalise)) {
      throw const UtilisateurException(
        'Le statut sélectionné est invalide.',
      );
    }

    try {
      final response = await _dio.patch(
        '/api/users/$id/statut',
        data: {
          'statut': statutNormalise,
        },
      );

      final data = _convertirMap(
        response.data,
      );

      return ActionUtilisateurResult(
        message: _extraireMessageReponse(
          data,
          'Statut du compte modifié avec succès.',
        ),
        utilisateur:
            _extraireUtilisateur(data),
      );
    } on DioException catch (error) {
      throw UtilisateurException(
        _extraireMessageErreur(
          error,
          'Impossible de modifier le statut du compte.',
        ),
      );
    } on UtilisateurException {
      rethrow;
    } catch (_) {
      throw const UtilisateurException(
        'La réponse du serveur est invalide.',
      );
    }
  }

  Future<ActionUtilisateurResult>
      reinitialiserMotDePasse({
    required String utilisateurId,
    required String nouveauMotDePasse,
  }) async {
    final id = utilisateurId.trim();

    final motDePasse =
        nouveauMotDePasse.trim();

    if (id.isEmpty) {
      throw const UtilisateurException(
        'L’utilisateur sélectionné est invalide.',
      );
    }

    if (motDePasse.length < 8) {
      throw const UtilisateurException(
        'Le nouveau mot de passe doit contenir au moins 8 caractères.',
      );
    }

    try {
      final response = await _dio.patch(
        '/api/users/$id/mot-de-passe',
        data: {
          'nouveau_mot_de_passe':
              motDePasse,
        },
      );

      final data = _convertirMap(
        response.data,
      );

      return ActionUtilisateurResult(
        message: _extraireMessageReponse(
          data,
          'Mot de passe modifié avec succès.',
        ),
      );
    } on DioException catch (error) {
      throw UtilisateurException(
        _extraireMessageErreur(
          error,
          'Impossible de modifier le mot de passe.',
        ),
      );
    } on UtilisateurException {
      rethrow;
    } catch (_) {
      throw const UtilisateurException(
        'La réponse du serveur est invalide.',
      );
    }
  }

  void _validerDonneesUtilisateur(
    DonneesUtilisateur donnees, {
    required bool creation,
  }) {
    if (donnees.nom.trim().isEmpty) {
      throw const UtilisateurException(
        'Le nom est obligatoire.',
      );
    }

    final email =
        donnees.email.trim();

    if (email.isEmpty) {
      throw const UtilisateurException(
        'L’adresse e-mail est obligatoire.',
      );
    }

    if (!_emailValide(email)) {
      throw const UtilisateurException(
        'L’adresse e-mail est invalide.',
      );
    }

    final role =
        donnees.role.trim().toLowerCase();

    if (!UtilisateurGestion
        .rolesAutorises
        .contains(role)) {
      throw const UtilisateurException(
        'Le rôle sélectionné est invalide.',
      );
    }

    if (creation) {
      final statut = donnees.statut
          .trim()
          .toLowerCase();

      if (!UtilisateurGestion
          .statutsAutorises
          .contains(statut)) {
        throw const UtilisateurException(
          'Le statut sélectionné est invalide.',
        );
      }

      final motDePasse =
          donnees.motDePasse?.trim() ?? '';

      if (motDePasse.length < 8) {
        throw const UtilisateurException(
          'Le mot de passe doit contenir au moins 8 caractères.',
        );
      }
    }
  }

  bool _emailValide(
    String email,
  ) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email.trim());
  }

  UtilisateurGestion?
      _extraireUtilisateur(
    Map<String, dynamic> data,
  ) {
    final utilisateurData =
        data['utilisateur'];

    if (utilisateurData is! Map) {
      return null;
    }

    return UtilisateurGestion.fromJson(
      Map<String, dynamic>.from(
        utilisateurData,
      ),
    );
  }

  Map<String, dynamic> _convertirMap(
    dynamic valeur,
  ) {
    if (valeur is! Map) {
      throw const UtilisateurException(
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
        return 'Vous n’êtes pas autorisé à gérer les utilisateurs.';

      case 404:
        return 'L’utilisateur est introuvable.';

      case 409:
        return 'Cette adresse e-mail est déjà utilisée.';

      default:
        return messageParDefaut;
    }
  }
}

class ActionUtilisateurResult {
  const ActionUtilisateurResult({
    required this.message,
    this.utilisateur,
  });

  final String message;
  final UtilisateurGestion? utilisateur;
}

class UtilisateurException implements Exception {
  const UtilisateurException(
    this.message,
  );

  final String message;

  @override
  String toString() => message;
}