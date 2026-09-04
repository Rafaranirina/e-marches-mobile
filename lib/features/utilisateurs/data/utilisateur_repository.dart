import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/network/dio_error_mapper.dart';
import 'utilisateur_gestion.dart';

class UtilisateurRepository {
  UtilisateurRepository({
    Dio? dio,
  }) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  // Profil de l'utilisateur connecté, partagé en mémoire entre les écrans
  // Profil et Paramètres (tous deux affichent les mêmes informations) pour
  // éviter deux appels GET /api/users/profil indépendants lors d'une même
  // session — voir chargerProfil().
  static UtilisateurGestion? _profilEnCache;

  /// À appeler après une mutation qui invalide le cache ailleurs que via
  /// [chargerProfil] (ex. déconnexion), pour forcer un prochain appel à
  /// revenir chercher les données sur le serveur.
  static void invaliderProfilEnCache() {
    _profilEnCache = null;
  }

  /// À appeler après une mutation du profil obtenue par un autre appel que
  /// [chargerProfil] (ex. modification du profil, activation de la 2FA),
  /// pour que le cache reste synchronisé avec les données les plus
  /// récentes.
  static void definirProfilEnCache(
    UtilisateurGestion profil,
  ) {
    _profilEnCache = profil;
  }

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

  Future<UtilisateurGestion> chargerProfil({
    bool forcerActualisation = false,
  }) async {
    final enCache = _profilEnCache;

    if (!forcerActualisation && enCache != null) {
      return enCache;
    }

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

      _profilEnCache = utilisateur;

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
    return extraireMessageErreur(
      error,
      messageParDefaut,
      messagesParStatut: const {
        400: 'Les informations transmises sont invalides.',
        403: 'Vous n’êtes pas autorisé à gérer les utilisateurs.',
        404: 'L’utilisateur est introuvable.',
        409: 'Cette adresse e-mail est déjà utilisée.',
      },
    );
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