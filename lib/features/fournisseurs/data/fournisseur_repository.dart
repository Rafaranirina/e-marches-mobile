import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/network/dio_error_mapper.dart';
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

      final data = _convertirMap(
        response.data,
      );

      final liste = data['entreprises'];

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
        'La liste des fournisseurs reçue est invalide.',
      );
    }
  }

  Future<Fournisseur> obtenirDetail(
    String fournisseurId,
  ) async {
    final id = fournisseurId.trim();

    if (id.isEmpty) {
      throw const FournisseurException(
        'Le fournisseur sélectionné est invalide.',
      );
    }

    try {
      final response = await _dio.get(
        '/api/entreprises/$id',
      );

      final data = _convertirMap(
        response.data,
      );

      final fournisseur =
          _extraireFournisseur(data);

      if (fournisseur == null ||
          fournisseur.id.isEmpty) {
        throw const FournisseurException(
          'Le fournisseur reçu est invalide.',
        );
      }

      return fournisseur;
    } on FournisseurException {
      rethrow;
    } on DioException catch (error) {
      throw FournisseurException(
        _extraireMessageErreur(
          error,
          'Impossible de récupérer ce fournisseur.',
        ),
      );
    } catch (_) {
      throw const FournisseurException(
        'Le fournisseur reçu est invalide.',
      );
    }
  }

  Future<List<HistoriqueStatutFournisseur>>
      obtenirHistorique(
    String fournisseurId,
  ) async {
    final id = fournisseurId.trim();

    if (id.isEmpty) {
      throw const FournisseurException(
        'Le fournisseur sélectionné est invalide.',
      );
    }

    try {
      final response = await _dio.get(
        '/api/entreprises/$id/historique',
      );

      final data = _convertirMap(
        response.data,
      );

      final liste = data['historique'];

      if (liste is! List) {
        throw const FournisseurException(
          'L’historique reçu est invalide.',
        );
      }

      return liste
          .whereType<Map>()
          .map(
            (item) =>
                HistoriqueStatutFournisseur.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where(
            (entree) => entree.id.isNotEmpty,
          )
          .toList();
    } on FournisseurException {
      rethrow;
    } on DioException catch (error) {
      throw FournisseurException(
        _extraireMessageErreur(
          error,
          'Impossible de récupérer l’historique de ce fournisseur.',
        ),
      );
    } catch (_) {
      throw const FournisseurException(
        'L’historique reçu est invalide.',
      );
    }
  }

  Future<ActionFournisseurResult> creer(
    DonneesCreationFournisseur donnees,
  ) async {
    if (donnees.raisonSociale.trim().isEmpty) {
      throw const FournisseurException(
        'La raison sociale est obligatoire.',
      );
    }

    try {
      final response = await _dio.post(
        '/api/entreprises',
        data: donnees.versJson(),
      );

      final data = _convertirMap(
        response.data,
      );

      return ActionFournisseurResult(
        message: _extraireMessageReponse(
          data,
          'Fournisseur créé avec succès.',
        ),
        fournisseur:
            _extraireFournisseur(data),
      );
    } on DioException catch (error) {
      throw FournisseurException(
        _extraireMessageErreur(
          error,
          'Impossible de créer le fournisseur.',
        ),
      );
    } on FournisseurException {
      rethrow;
    } catch (_) {
      throw const FournisseurException(
        'La réponse du serveur est invalide.',
      );
    }
  }

  Future<ActionFournisseurResult> modifier({
    required String fournisseurId,
    required DonneesModificationFournisseur
        donnees,
  }) async {
    final id = fournisseurId.trim();

    if (id.isEmpty) {
      throw const FournisseurException(
        'Le fournisseur sélectionné est invalide.',
      );
    }

    try {
      final response = await _dio.put(
        '/api/entreprises/$id',
        data: donnees.versJson(),
      );

      final data = _convertirMap(
        response.data,
      );

      return ActionFournisseurResult(
        message: _extraireMessageReponse(
          data,
          'Fournisseur modifié avec succès.',
        ),
        fournisseur:
            _extraireFournisseur(data),
      );
    } on DioException catch (error) {
      throw FournisseurException(
        _extraireMessageErreur(
          error,
          'Impossible de modifier le fournisseur.',
        ),
      );
    } on FournisseurException {
      rethrow;
    } catch (_) {
      throw const FournisseurException(
        'La réponse du serveur est invalide.',
      );
    }
  }

  Future<ActionFournisseurResult>
      changerStatut({
    required String fournisseurId,
    required String statut,
    String? motif,
  }) async {
    final id = fournisseurId.trim();

    final statutNormalise =
        statut.trim().toLowerCase();

    if (id.isEmpty) {
      throw const FournisseurException(
        'Le fournisseur sélectionné est invalide.',
      );
    }

    if (!Fournisseur.statutsAutorises
        .contains(statutNormalise)) {
      throw const FournisseurException(
        'Le statut sélectionné est invalide.',
      );
    }

    final motifNettoye = motif?.trim() ?? '';

    if ((statutNormalise == 'suspendu' ||
            statutNormalise == 'inactif') &&
        motifNettoye.isEmpty) {
      throw const FournisseurException(
        'Un motif est obligatoire pour suspendre ou désactiver un fournisseur.',
      );
    }

    try {
      final response = await _dio.patch(
        '/api/entreprises/$id/statut',
        data: {
          'statut': statutNormalise,
          if (motifNettoye.isNotEmpty)
            'motif': motifNettoye,
        },
      );

      final data = _convertirMap(
        response.data,
      );

      return ActionFournisseurResult(
        message: _extraireMessageReponse(
          data,
          'Statut du fournisseur modifié avec succès.',
        ),
        fournisseur:
            _extraireFournisseur(data),
      );
    } on DioException catch (error) {
      throw FournisseurException(
        _extraireMessageErreur(
          error,
          'Impossible de modifier le statut du fournisseur.',
        ),
      );
    } on FournisseurException {
      rethrow;
    } catch (_) {
      throw const FournisseurException(
        'La réponse du serveur est invalide.',
      );
    }
  }

  /// Raccourci conservé pour compatibilité : valide une entreprise en
  /// attente (`statut_validation: 'en_attente'`) en la faisant passer
  /// à `'actif'`. Équivaut à [changerStatut] avec `statut: 'actif'`.
  /// Réservé au rôle `admin_national` côté backend
  /// (`entreprise.routes.js`).
  Future<String> validerEntreprise({
    required String entrepriseId,
  }) async {
    final resultat = await changerStatut(
      fournisseurId: entrepriseId,
      statut: 'actif',
    );

    return resultat.message;
  }

  Fournisseur? _extraireFournisseur(
    Map<String, dynamic> data,
  ) {
    final fournisseurData =
        data['entreprise'];

    if (fournisseurData is! Map) {
      return null;
    }

    return Fournisseur.fromJson(
      Map<String, dynamic>.from(
        fournisseurData,
      ),
    );
  }

  Map<String, dynamic> _convertirMap(
    dynamic valeur,
  ) {
    if (valeur is! Map) {
      throw const FournisseurException(
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
        403: 'Vous n’êtes pas autorisé à gérer les fournisseurs.',
        404: 'Le fournisseur est introuvable.',
        409: 'Ces informations sont déjà utilisées par un autre fournisseur.',
      },
    );
  }
}

class ActionFournisseurResult {
  const ActionFournisseurResult({
    required this.message,
    this.fournisseur,
  });

  final String message;
  final Fournisseur? fournisseur;
}

class FournisseurException implements Exception {
  const FournisseurException(this.message);

  final String message;

  @override
  String toString() => message;
}
