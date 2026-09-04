import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/network/dio_error_mapper.dart';
import '../../utilisateurs/data/utilisateur_gestion.dart';

class ParametresRepository {
  ParametresRepository({
    Dio? dio,
  }) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  Future<UtilisateurGestion> modifierProfil({
    required String nom,
    String? prenom,
    String? telephone,
  }) async {
    final nomNormalise = nom.trim();

    if (nomNormalise.isEmpty) {
      throw const ParametresException(
        'Le nom est obligatoire.',
      );
    }

    try {
      final response = await _dio.patch(
        '/api/users/profil',
        data: {
          'nom': nomNormalise,
          'prenom': _nullableString(prenom),
          'telephone': _nullableString(telephone),
        },
      );

      final data = _convertirReponse(response.data);
      final utilisateurData = data['utilisateur'];

      if (utilisateurData is! Map) {
        throw const ParametresException(
          'Le profil reçu est invalide.',
        );
      }

      return UtilisateurGestion.fromJson(
        Map<String, dynamic>.from(utilisateurData),
      );
    } on ParametresException {
      rethrow;
    } on DioException catch (error) {
      throw ParametresException(
        _extraireMessageErreur(
          error,
          'Impossible de modifier le profil.',
        ),
      );
    } catch (_) {
      throw const ParametresException(
        'Une erreur inattendue est survenue.',
      );
    }
  }

  /// Renvoie `null` si aucune photo de profil n'est enregistrée (404).
  Future<PhotoProfil?> chargerPhotoProfil() async {
    try {
      final response = await _dio.get(
        '/api/users/profil/photo',
        options: Options(responseType: ResponseType.bytes),
      );

      final contentType =
          response.headers.value('content-type') ?? 'image/jpeg';

      return PhotoProfil(
        octets: Uint8List.fromList(
          List<int>.from(response.data as List<int>),
        ),
        typeMime: contentType,
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }

      throw ParametresException(
        _extraireMessageErreur(
          error,
          'Impossible de charger la photo de profil.',
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Téléverse une nouvelle photo de profil.
  ///
  /// Piège backend confirmé : cette route unique renvoie
  /// `statut: "succes"` et NON `"ok"` comme partout ailleurs dans l'API
  /// (`photoProfil.controller.js`) — ce n'est pas une faute de frappe côté
  /// mobile, ne pas la "corriger" en filtrant uniquement sur `"ok"`.
  Future<String> uploaderPhotoProfil({
    required String cheminFichier,
  }) async {
    final cheminNormalise = cheminFichier.trim();

    if (cheminNormalise.isEmpty) {
      throw const ParametresException(
        'Sélectionnez une image.',
      );
    }

    final nomFichier =
        cheminNormalise.split(RegExp(r'[\\/]')).last.trim();

    try {
      final fichier = await MultipartFile.fromFile(
        cheminNormalise,
        filename: nomFichier.isEmpty ? 'photo.jpg' : nomFichier,
      );

      final response = await _dio.post(
        '/api/users/profil/photo',
        data: FormData.fromMap({'photo': fichier}),
      );

      final data = _convertirReponse(response.data);
      final statut = data['statut']?.toString();

      if (statut != 'succes' && statut != 'ok') {
        throw ParametresException(
          data['message']?.toString() ??
              'Le téléversement de la photo a échoué.',
        );
      }

      return data['message']?.toString() ??
          'Photo de profil mise à jour.';
    } on ParametresException {
      rethrow;
    } on DioException catch (error) {
      throw ParametresException(
        _extraireMessageErreur(
          error,
          'Impossible de téléverser la photo de profil.',
        ),
      );
    } catch (_) {
      throw const ParametresException(
        'Impossible de lire ou de téléverser le fichier.',
      );
    }
  }

  Future<String> supprimerPhotoProfil() async {
    try {
      final response = await _dio.delete(
        '/api/users/profil/photo',
      );

      final data = _convertirReponse(response.data);

      return data['message']?.toString() ??
          'Photo de profil supprimée.';
    } on DioException catch (error) {
      throw ParametresException(
        _extraireMessageErreur(
          error,
          'Impossible de supprimer la photo de profil.',
        ),
      );
    } catch (_) {
      throw const ParametresException(
        'Une erreur inattendue est survenue.',
      );
    }
  }

  Future<Activation2FA> activer2FA() async {
    try {
      final response = await _dio.post(
        '/api/auth/2fa/activer',
      );

      final data = _convertirReponse(response.data);

      return Activation2FA(
        qrCodeDataUrl: data['qr_code']?.toString() ?? '',
        secret: data['secret']?.toString() ?? '',
      );
    } on DioException catch (error) {
      throw ParametresException(
        _extraireMessageErreur(
          error,
          'Impossible d’activer la double authentification.',
        ),
      );
    } catch (_) {
      throw const ParametresException(
        'Une erreur inattendue est survenue.',
      );
    }
  }

  Future<String> verifier2FA({
    required String code,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/2fa/verifier',
        data: {'code': code.trim()},
      );

      final data = _convertirReponse(response.data);

      return data['message']?.toString() ??
          'Double authentification activée.';
    } on DioException catch (error) {
      throw ParametresException(
        _extraireMessageErreur(
          error,
          'Le code saisi est invalide.',
        ),
      );
    } catch (_) {
      throw const ParametresException(
        'Une erreur inattendue est survenue.',
      );
    }
  }

  Future<String> desactiver2FA({
    required String motDePasse,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/2fa/desactiver',
        data: {'mot_de_passe': motDePasse},
      );

      final data = _convertirReponse(response.data);

      return data['message']?.toString() ??
          'Double authentification désactivée.';
    } on DioException catch (error) {
      throw ParametresException(
        _extraireMessageErreur(
          error,
          'Impossible de désactiver la double authentification.',
        ),
      );
    } catch (_) {
      throw const ParametresException(
        'Une erreur inattendue est survenue.',
      );
    }
  }

  Map<String, dynamic> _convertirReponse(
    dynamic responseData,
  ) {
    if (responseData is! Map) {
      throw const ParametresException(
        'Réponse invalide du serveur.',
      );
    }

    return Map<String, dynamic>.from(responseData);
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
        401: 'Mot de passe incorrect ou session expirée.',
        404: 'Ressource introuvable.',
        409: 'Cette opération a déjà été effectuée.',
        413: 'Le fichier sélectionné est trop volumineux.',
      },
    );
  }

  static String? _nullableString(String? valeur) {
    final texte = valeur?.trim() ?? '';

    return texte.isEmpty ? null : texte;
  }
}

class PhotoProfil {
  const PhotoProfil({
    required this.octets,
    required this.typeMime,
  });

  final Uint8List octets;
  final String typeMime;
}

class Activation2FA {
  const Activation2FA({
    required this.qrCodeDataUrl,
    required this.secret,
  });

  final String qrCodeDataUrl;
  final String secret;
}

class ParametresException implements Exception {
  const ParametresException(this.message);

  final String message;

  @override
  String toString() => message;
}
