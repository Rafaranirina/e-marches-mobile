import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'contrat.dart';
import 'paiement.dart';

class ContratRepository {
  ContratRepository({
    Dio? dio,
  }) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  Future<List<Contrat>> lister() async {
    try {
      final response = await _dio.get(
        '/api/contrats',
      );

      final data = _convertirReponse(
        response.data,
      );

      final liste = data['contrats'];

      if (liste is! List) {
        throw const ContratException(
          'La liste des contrats est invalide.',
        );
      }

      return liste
          .whereType<Map>()
          .map(
            (item) => Contrat.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where(
            (contrat) =>
                contrat.id.isNotEmpty &&
                contrat.reference.isNotEmpty,
          )
          .toList();
    } on ContratException {
      rethrow;
    } on DioException catch (error) {
      throw ContratException(
        _extraireMessageErreur(
          error,
          'Impossible de récupérer les contrats.',
        ),
      );
    } catch (_) {
      throw const ContratException(
        'Une erreur inattendue est survenue.',
      );
    }
  }

  Future<ContratDetailsResult> details(
    String contratId,
  ) async {
    final contratIdNormalise =
        contratId.trim();

    if (contratIdNormalise.isEmpty) {
      throw const ContratException(
        'L’identifiant du contrat est invalide.',
      );
    }

    try {
      final response = await _dio.get(
        '/api/contrats/$contratIdNormalise',
      );

      final data = _convertirReponse(
        response.data,
      );

      final contratData = data['contrat'];

      if (contratData is! Map) {
        throw const ContratException(
          'Les informations du contrat sont invalides.',
        );
      }

      final paiementsData = data['paiements'];

      final paiements = paiementsData is List
          ? paiementsData
              .whereType<Map>()
              .map(
                (item) => Paiement.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .where(
                (paiement) =>
                    paiement.id.isNotEmpty,
              )
              .toList()
          : <Paiement>[];

      return ContratDetailsResult(
        contrat: Contrat.fromJson(
          Map<String, dynamic>.from(
            contratData,
          ),
        ),
        paiements: paiements,
      );
    } on ContratException {
      rethrow;
    } on DioException catch (error) {
      throw ContratException(
        _extraireMessageErreur(
          error,
          'Impossible de récupérer le contrat.',
        ),
      );
    } catch (_) {
      throw const ContratException(
        'Une erreur inattendue est survenue.',
      );
    }
  }

  Future<ContratActionResult> mettreAJourStatut({
    required String contratId,
    String? statut,
    DateTime? dateSignature,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    final contratIdNormalise =
        contratId.trim();

    if (contratIdNormalise.isEmpty) {
      throw const ContratException(
        'L’identifiant du contrat est invalide.',
      );
    }

    final statutNormalise =
        statut?.trim().toLowerCase();

    const statutsAutorises = {
      'en_cours',
      'suspendu',
      'termine',
      'resilie',
    };

    if (statutNormalise != null &&
        statutNormalise.isNotEmpty &&
        !statutsAutorises.contains(
          statutNormalise,
        )) {
      throw const ContratException(
        'Le statut sélectionné est invalide.',
      );
    }

    try {
      final response = await _dio.patch(
        '/api/contrats/$contratIdNormalise/statut',
        data: {
          'statut':
              _nullableString(statutNormalise),
          'date_signature':
              _formatDateApi(dateSignature),
          'date_debut':
              _formatDateApi(dateDebut),
          'date_fin':
              _formatDateApi(dateFin),
        },
      );

      final data = _convertirReponse(
        response.data,
      );

      final contratData = data['contrat'];

      return ContratActionResult(
        message: _extraireMessageReponse(
          data,
          'Contrat mis à jour.',
        ),
        contrat: contratData is Map
            ? Contrat.fromJson(
                Map<String, dynamic>.from(
                  contratData,
                ),
              )
            : null,
      );
    } on ContratException {
      rethrow;
    } on DioException catch (error) {
      throw ContratException(
        _extraireMessageErreur(
          error,
          'Impossible de mettre à jour le contrat.',
        ),
      );
    } catch (_) {
      throw const ContratException(
        'Une erreur inattendue est survenue.',
      );
    }
  }

  Future<PaiementActionResult> ajouterPaiement({
    required String contratId,
    required double montant,
    String? reference,
    String? description,
    DateTime? dateEcheance,
  }) async {
    final contratIdNormalise =
        contratId.trim();

    if (contratIdNormalise.isEmpty) {
      throw const ContratException(
        'L’identifiant du contrat est invalide.',
      );
    }

    if (montant <= 0) {
      throw const ContratException(
        'Le montant du paiement doit être supérieur à zéro.',
      );
    }

    try {
      final response = await _dio.post(
        '/api/contrats/$contratIdNormalise/paiements',
        data: {
          'reference':
              _nullableString(reference),
          'description':
              _nullableString(description),
          'montant': montant,
          'date_echeance':
              _formatDateApi(dateEcheance),
        },
      );

      final data = _convertirReponse(
        response.data,
      );

      final paiementData =
          data['paiement'];

      return PaiementActionResult(
        message: _extraireMessageReponse(
          data,
          'Paiement ajouté.',
        ),
        paiement: paiementData is Map
            ? Paiement.fromJson(
                Map<String, dynamic>.from(
                  paiementData,
                ),
              )
            : null,
      );
    } on ContratException {
      rethrow;
    } on DioException catch (error) {
      throw ContratException(
        _extraireMessageErreur(
          error,
          'Impossible d’ajouter le paiement.',
        ),
      );
    } catch (_) {
      throw const ContratException(
        'Une erreur inattendue est survenue.',
      );
    }
  }

  Future<PaiementActionResult> validerPaiement(
    String paiementId,
  ) async {
    final paiementIdNormalise =
        paiementId.trim();

    if (paiementIdNormalise.isEmpty) {
      throw const ContratException(
        'L’identifiant du paiement est invalide.',
      );
    }

    try {
      final response = await _dio.patch(
        '/api/contrats/paiements/'
        '$paiementIdNormalise/valider',
      );

      final data = _convertirReponse(
        response.data,
      );

      final paiementData =
          data['paiement'];

      return PaiementActionResult(
        message: _extraireMessageReponse(
          data,
          'Paiement validé.',
        ),
        paiement: paiementData is Map
            ? Paiement.fromJson(
                Map<String, dynamic>.from(
                  paiementData,
                ),
              )
            : null,
      );
    } on ContratException {
      rethrow;
    } on DioException catch (error) {
      throw ContratException(
        _extraireMessageErreur(
          error,
          'Impossible de valider le paiement.',
        ),
      );
    } catch (_) {
      throw const ContratException(
        'Une erreur inattendue est survenue.',
      );
    }
  }

  Map<String, dynamic> _convertirReponse(
    dynamic responseData,
  ) {
    if (responseData is! Map) {
      throw const ContratException(
        'Réponse invalide du serveur.',
      );
    }

    return Map<String, dynamic>.from(
      responseData,
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
        return 'Vous n’êtes pas autorisé à effectuer cette action.';

      case 404:
        return 'Le contrat ou le paiement est introuvable.';

      case 409:
        return 'Cette opération a déjà été effectuée.';

      default:
        return messageParDefaut;
    }
  }

  static String? _nullableString(
    String? valeur,
  ) {
    final texte = valeur?.trim() ?? '';

    return texte.isEmpty ? null : texte;
  }

  static String? _formatDateApi(
    DateTime? date,
  ) {
    if (date == null) {
      return null;
    }

    final annee = date.year
        .toString()
        .padLeft(4, '0');

    final mois = date.month
        .toString()
        .padLeft(2, '0');

    final jour = date.day
        .toString()
        .padLeft(2, '0');

    return '$annee-$mois-$jour';
  }
}

class ContratDetailsResult {
  const ContratDetailsResult({
    required this.contrat,
    required this.paiements,
  });

  final Contrat contrat;
  final List<Paiement> paiements;
}

class ContratActionResult {
  const ContratActionResult({
    required this.message,
    this.contrat,
  });

  final String message;
  final Contrat? contrat;
}

class PaiementActionResult {
  const PaiementActionResult({
    required this.message,
    this.paiement,
  });

  final String message;
  final Paiement? paiement;
}

class ContratException implements Exception {
  const ContratException(
    this.message,
  );

  final String message;

  @override
  String toString() => message;
}