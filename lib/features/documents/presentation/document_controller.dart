import 'package:flutter/foundation.dart';

import '../data/document_marche.dart';
import '../data/document_repository.dart';

class DocumentController extends ChangeNotifier {
  DocumentController({
    required this.contexte,
    required this.contexteId,
    DocumentRepository? repository,
  }) : _repository =
            repository ?? DocumentRepository();

  final String contexte;
  final String contexteId;
  final DocumentRepository _repository;

  List<DocumentMarche> _documents = [];

  bool _isLoading = false;
  bool _isUploading = false;
  bool _isGeneratingLink = false;

  String? _errorMessage;

  List<DocumentMarche> get documents =>
      List.unmodifiable(_documents);

  bool get isLoading => _isLoading;

  bool get isUploading => _isUploading;

  bool get isGeneratingLink =>
      _isGeneratingLink;

  bool get isBusy =>
      _isLoading ||
      _isUploading ||
      _isGeneratingLink;

  String? get errorMessage =>
      _errorMessage;

  bool get hasError =>
      _errorMessage != null;

  int get nombreDocuments =>
      _documents.length;

  Future<void> charger() async {
    if (!_contexteValide()) {
      _errorMessage =
          'Le contexte des documents est invalide.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _documents =
          await _repository.lister(
        contexte: contexte,
        contexteId: contexteId,
      );
    } on DocumentException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible de charger les documents.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> actualiser() async {
    if (!_contexteValide()) {
      return;
    }

    try {
      _errorMessage = null;

      _documents =
          await _repository.lister(
        contexte: contexte,
        contexteId: contexteId,
      );
    } on DocumentException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible d’actualiser les documents.';
    } finally {
      notifyListeners();
    }
  }

  Future<UploadDocumentResult?> uploader({
    required String cheminFichier,
    String? typeDocument,
  }) async {
    if (!_contexteValide()) {
      _errorMessage =
          'Le contexte des documents est invalide.';
      notifyListeners();
      return null;
    }

    if (cheminFichier.trim().isEmpty) {
      _errorMessage =
          'Sélectionnez un fichier.';
      notifyListeners();
      return null;
    }

    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat =
          await _repository.uploader(
        cheminFichier:
            cheminFichier.trim(),
        contexte: contexte,
        contexteId: contexteId,
        typeDocument: typeDocument,
      );

      _documents =
          await _repository.lister(
        contexte: contexte,
        contexteId: contexteId,
      );

      return resultat;
    } on DocumentException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Impossible de téléverser le document.';
      return null;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<TelechargementDocumentResult?>
      obtenirLienTelechargement(
    String documentId,
  ) async {
    if (documentId.trim().isEmpty) {
      _errorMessage =
          'Le document sélectionné est invalide.';
      notifyListeners();
      return null;
    }

    _isGeneratingLink = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await _repository
          .obtenirLienTelechargement(
        documentId.trim(),
      );
    } on DocumentException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Impossible de générer le lien de téléchargement.';
      return null;
    } finally {
      _isGeneratingLink = false;
      notifyListeners();
    }
  }

  DocumentMarche? trouverDocument(
    String documentId,
  ) {
    for (final document in _documents) {
      if (document.id == documentId) {
        return document;
      }
    }

    return null;
  }

  void effacerErreur() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  bool _contexteValide() {
    final contexteNormalise =
        contexte.trim().toLowerCase();

    return DocumentRepository
            .contextesAutorises
            .contains(contexteNormalise) &&
        contexteId.trim().isNotEmpty;
  }
}