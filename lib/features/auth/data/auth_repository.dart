import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import 'auth_user.dart';
import 'login_result.dart';

class AuthRepository {
  AuthRepository({
    Dio? dio,
    SecureStorageService? storage,
  })  : _dio = dio ?? ApiClient.dio,
        _storage = storage ?? SecureStorageService();

  final Dio _dio;
  final SecureStorageService _storage;

  Future<LoginResult> login({
    required String email,
    required String motDePasse,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {
          'email': email.trim(),
          'mot_de_passe': motDePasse,
        },
      );

      final responseData = response.data;

      if (responseData is! Map) {
        return const LoginResult(
          statut: 'erreur',
          message: 'Réponse invalide du serveur.',
        );
      }

      final result = LoginResult.fromJson(
        Map<String, dynamic>.from(responseData),
      );

      final token = result.accessToken;

      if (result.isSuccess && token != null && token.isNotEmpty) {
        await _storage.saveAccessToken(token);
      }

      return result;
    } on DioException catch (error) {
      final responseData = error.response?.data;

      if (responseData is Map) {
        return LoginResult.fromJson(
          Map<String, dynamic>.from(responseData),
        );
      }

      return const LoginResult(
        statut: 'erreur',
        message:
            'Impossible de communiquer avec le serveur. Vérifiez que le backend est démarré.',
      );
    } catch (error) {
      return LoginResult(
        statut: 'erreur',
        message: 'Erreur inattendue : $error',
      );
    }
  }

  Future<LoginResult> validerCode2FA({
    required String challenge2fa,
    required String code,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/2fa/valider-login',
        data: {
          'challenge_2fa': challenge2fa,
          'code': code.trim(),
        },
      );

      final responseData = response.data;

      if (responseData is! Map) {
        return const LoginResult(
          statut: 'erreur',
          message: 'Réponse invalide du serveur.',
        );
      }

      final result = LoginResult.fromJson(
        Map<String, dynamic>.from(responseData),
      );

      final token = result.accessToken;

      if (result.isSuccess && token != null && token.isNotEmpty) {
        await _storage.saveAccessToken(token);
      }

      return result;
    } on DioException catch (error) {
      final responseData = error.response?.data;

      if (responseData is Map) {
        return LoginResult.fromJson(
          Map<String, dynamic>.from(responseData),
        );
      }

      return const LoginResult(
        statut: 'erreur',
        message:
            'Impossible de communiquer avec le serveur. Vérifiez que le backend est démarré.',
      );
    } catch (error) {
      return LoginResult(
        statut: 'erreur',
        message: 'Erreur inattendue : $error',
      );
    }
  }

  /// Reconstruit l'utilisateur connecté à partir du token déjà stocké, en
  /// revalidant son état auprès du serveur (GET /api/users/profil) plutôt
  /// que de faire confiance à un JSON persisté localement — un rôle ou un
  /// statut modifié entre-temps côté serveur doit se refléter immédiatement.
  /// Retourne `null` si aucun token n'est stocké ou si le serveur le
  /// rejette (token expiré/révoqué) ; dans ce dernier cas le token invalide
  /// est aussi supprimé du stockage sécurisé.
  Future<AuthUser?> restaurerUtilisateurConnecte() async {
    final token = await _storage.getAccessToken();

    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final response = await _dio.get(
        '/api/users/profil',
      );

      final responseData = response.data;

      if (responseData is! Map) {
        return null;
      }

      final utilisateurJson =
          Map<String, dynamic>.from(responseData)['utilisateur'];

      if (utilisateurJson is! Map<String, dynamic>) {
        return null;
      }

      return AuthUser.fromJson(utilisateurJson);
    } on DioException {
      await _storage.deleteAccessToken();
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Le backend renvoie toujours une réponse générique (anti-énumération) :
  /// que l'e-mail corresponde ou non à un compte, le message reste neutre.
  Future<String> demanderReinitialisation({
    required String email,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/mot-de-passe-oublie',
        data: {'email': email.trim()},
      );

      final data = response.data;

      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }

      return 'Si un compte existe avec cette adresse, un e-mail a été envoyé.';
    } on DioException catch (error) {
      final responseData = error.response?.data;

      if (responseData is Map && responseData['message'] != null) {
        return responseData['message'].toString();
      }

      return 'Impossible de communiquer avec le serveur.';
    } catch (_) {
      return 'Une erreur inattendue est survenue.';
    }
  }

  Future<AuthActionResult> reinitialiserMotDePasse({
    required String token,
    required String nouveauMotDePasse,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/reinitialiser-mot-de-passe',
        data: {
          'token': token.trim(),
          'nouveau_mot_de_passe': nouveauMotDePasse,
        },
      );

      final data = response.data;

      return AuthActionResult(
        succes: data is Map && data['statut'] == 'ok',
        message: data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Mot de passe réinitialisé avec succès.',
      );
    } on DioException catch (error) {
      final responseData = error.response?.data;

      return AuthActionResult(
        succes: false,
        message: responseData is Map && responseData['message'] != null
            ? responseData['message'].toString()
            : 'Impossible de réinitialiser le mot de passe.',
      );
    } catch (error) {
      return AuthActionResult(
        succes: false,
        message: 'Erreur inattendue : $error',
      );
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }
}

class AuthActionResult {
  const AuthActionResult({
    required this.succes,
    required this.message,
  });

  final bool succes;
  final String message;
}