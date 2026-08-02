import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/document_marche.dart';
import 'document_controller.dart';

class DocumentsPage extends StatelessWidget {
  const DocumentsPage({
    required this.contexte,
    required this.contexteId,
    required this.titre,
    this.peutUploader = true,
    super.key,
  });

  final String contexte;
  final String contexteId;
  final String titre;
  final bool peutUploader;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DocumentController(
        contexte: contexte,
        contexteId: contexteId,
      )..charger(),
      child: _DocumentsView(
        titre: titre,
        peutUploader: peutUploader,
      ),
    );
  }
}

class _DocumentsView extends StatefulWidget {
  const _DocumentsView({
    required this.titre,
    required this.peutUploader,
  });

  final String titre;
  final bool peutUploader;

  @override
  State<_DocumentsView> createState() =>
      _DocumentsViewState();
}

class _DocumentsViewState
    extends State<_DocumentsView> {
  String? _documentEnTelechargementId;

  Future<void> _ajouterDocument() async {
    final controller =
        context.read<DocumentController>();

    if (controller.isBusy) {
      return;
    }

    controller.effacerErreur();

    try {
      final resultatSelection =
          await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
        withData: false,
      );

      if (resultatSelection == null ||
          resultatSelection.files.isEmpty ||
          !mounted) {
        return;
      }

      final fichier =
          resultatSelection.files.single;

      final cheminFichier =
          fichier.path?.trim() ?? '';

      if (cheminFichier.isEmpty) {
        _afficherMessage(
          'Le chemin du fichier sélectionné '
          'est indisponible.',
          estErreur: true,
        );
        return;
      }

      final typeDocument =
          await showDialog<String>(
        context: context,
        builder: (_) => _TypeDocumentDialog(
          nomFichier: fichier.name,
        ),
      );

      if (typeDocument == null ||
          !mounted) {
        return;
      }

      final resultat =
          await controller.uploader(
        cheminFichier: cheminFichier,
        typeDocument:
            typeDocument.trim().isEmpty
                ? null
                : typeDocument.trim(),
      );

      if (!mounted) {
        return;
      }

      if (resultat == null) {
        _afficherMessage(
          controller.errorMessage ??
              'Impossible de téléverser le document.',
          estErreur: true,
        );
        return;
      }

      _afficherMessage(
        resultat.message.trim().isEmpty
            ? 'Document téléversé avec succès.'
            : resultat.message,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _afficherMessage(
        'Impossible de sélectionner ou '
        'de téléverser le fichier.',
        estErreur: true,
      );
    }
  }

  Future<void> _telechargerDocument(
    DocumentMarche document,
  ) async {
    if (_documentEnTelechargementId !=
        null) {
      return;
    }

    final controller =
        context.read<DocumentController>();

    controller.effacerErreur();

    setState(() {
      _documentEnTelechargementId =
          document.id;
    });

    try {
      final resultat = await controller
          .obtenirLienTelechargement(
        document.id,
      );

      if (!mounted) {
        return;
      }

      if (resultat == null) {
        _afficherMessage(
          controller.errorMessage ??
              'Impossible de générer le lien '
                  'de téléchargement.',
          estErreur: true,
        );
        return;
      }

      final adresse =
          resultat.urlTelechargement.trim();

      final uri = Uri.tryParse(adresse);

      if (adresse.isEmpty || uri == null) {
        _afficherMessage(
          'Le lien de téléchargement reçu '
          'est invalide.',
          estErreur: true,
        );
        return;
      }

      final ouvertureReussie =
          await launchUrl(
        uri,
        mode:
            LaunchMode.externalApplication,
      );

      if (!ouvertureReussie &&
          mounted) {
        _afficherMessage(
          'Impossible d’ouvrir le document.',
          estErreur: true,
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      _afficherMessage(
        'Impossible de télécharger '
        'le document.',
        estErreur: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _documentEnTelechargementId =
              null;
        });
      }
    }
  }

  void _afficherMessage(
    String message, {
    bool estErreur = false,
  }) {
    final messenger =
        ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: estErreur
              ? Theme.of(context)
                  .colorScheme
                  .error
              : null,
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final controller =
        context.watch<DocumentController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titre),
        actions: [
          if (widget.peutUploader)
            IconButton(
              tooltip:
                  'Ajouter un document',
              onPressed: controller.isBusy
                  ? null
                  : _ajouterDocument,
              icon: const Icon(
                Icons.upload_file_outlined,
              ),
            ),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: controller.isBusy
                ? null
                : controller.actualiser,
            icon: const Icon(
              Icons.refresh_outlined,
            ),
          ),
        ],
        bottom: controller.isUploading
            ? const PreferredSize(
                preferredSize:
                    Size.fromHeight(3),
                child:
                    LinearProgressIndicator(),
              )
            : null,
      ),
      floatingActionButton:
          widget.peutUploader &&
                  !controller.isLoading
              ? FloatingActionButton.extended(
                  onPressed:
                      controller.isBusy
                          ? null
                          : _ajouterDocument,
                  icon: const Icon(
                    Icons.upload_file_outlined,
                  ),
                  label: const Text(
                    'Ajouter',
                  ),
                )
              : null,
      body: SafeArea(
        child: _buildContenu(
          controller,
        ),
      ),
    );
  }

  Widget _buildContenu(
    DocumentController controller,
  ) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (controller.hasError &&
        controller.documents.isEmpty) {
      return _ErreurDocuments(
        message: controller.errorMessage ??
            'Impossible de charger '
                'les documents.',
        onRetry: controller.charger,
      );
    }

    if (controller.documents.isEmpty) {
      return _ListeDocumentsVide(
        peutUploader:
            widget.peutUploader,
        onActualiser:
            controller.actualiser,
        onAjouter:
            widget.peutUploader
                ? _ajouterDocument
                : null,
      );
    }

    return RefreshIndicator(
      onRefresh: controller.actualiser,
      child: ListView.separated(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          110,
        ),
        itemCount:
            controller.documents.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final document =
              controller.documents[index];

          return _DocumentCard(
            document: document,
            enTelechargement:
                _documentEnTelechargementId ==
                    document.id,
            onTelecharger: () {
              _telechargerDocument(
                document,
              );
            },
          );
        },
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    required this.enTelechargement,
    required this.onTelecharger,
  });

  final DocumentMarche document;
  final bool enTelechargement;
  final VoidCallback onTelecharger;

  @override
  Widget build(BuildContext context) {
    final nomFichier =
        document.nomFichier.trim();

    final typeDocumentBrut =
        '${document.typeDocument}'.trim();

    final typeDocument =
        typeDocumentBrut.isEmpty ||
                typeDocumentBrut
                        .toLowerCase() ==
                    'null'
            ? 'Document'
            : typeDocumentBrut;

    final extension =
        document.extension.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 25,
                  child: Icon(
                    _iconeDocument(
                      document,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        nomFichier.isEmpty
                            ? 'Document sans nom'
                            : nomFichier,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(typeDocument),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (extension.isNotEmpty)
                  Chip(
                    avatar: const Icon(
                      Icons
                          .insert_drive_file_outlined,
                      size: 17,
                    ),
                    label: Text(
                      extension.toUpperCase(),
                    ),
                  ),
                Chip(
                  avatar: const Icon(
                    Icons
                        .data_usage_outlined,
                    size: 17,
                  ),
                  label: Text(
                    document.tailleFormatee,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 19,
                  color: Theme.of(context)
                      .colorScheme
                      .primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ajouté le : '
                    '${_formatDate(document.dateUpload)}',
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    enTelechargement
                        ? null
                        : onTelecharger,
                icon: enTelechargement
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.download_outlined,
                      ),
                label: Text(
                  enTelechargement
                      ? 'Préparation...'
                      : 'Télécharger',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconeDocument(
    DocumentMarche document,
  ) {
    if (document.estPdf) {
      return Icons.picture_as_pdf_outlined;
    }

    if (document.estImage) {
      return Icons.image_outlined;
    }

    if (document.estDocumentWord) {
      return Icons.article_outlined;
    }

    if (document.estTableur) {
      return Icons.table_chart_outlined;
    }

    return Icons
        .insert_drive_file_outlined;
  }
}

class _TypeDocumentDialog
    extends StatefulWidget {
  const _TypeDocumentDialog({
    required this.nomFichier,
  });

  final String nomFichier;

  @override
  State<_TypeDocumentDialog>
      createState() =>
          _TypeDocumentDialogState();
}

class _TypeDocumentDialogState
    extends State<_TypeDocumentDialog> {
  final TextEditingController
      _typeController =
      TextEditingController();

  @override
  void dispose() {
    _typeController.dispose();
    super.dispose();
  }

  void _confirmer() {
    Navigator.of(context).pop(
      _typeController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Ajouter un document',
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Fichier sélectionné',
            ),
            const SizedBox(height: 6),
            Text(
              widget.nomFichier,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(
                    fontWeight:
                        FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller:
                  _typeController,
              textCapitalization:
                  TextCapitalization.sentences,
              decoration:
                  const InputDecoration(
                labelText:
                    'Type du document',
                hintText:
                    'Exemple : Dossier d’appel d’offres',
                helperText:
                    'Ce champ est facultatif.',
                prefixIcon: Icon(
                  Icons
                      .description_outlined,
                ),
                border:
                    OutlineInputBorder(),
              ),
              onSubmitted: (_) {
                _confirmer();
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'Annuler',
          ),
        ),
        FilledButton.icon(
          onPressed: _confirmer,
          icon: const Icon(
            Icons.upload_outlined,
          ),
          label: const Text(
            'Téléverser',
          ),
        ),
      ],
    );
  }
}

class _ErreurDocuments
    extends StatelessWidget {
  const _ErreurDocuments({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign:
                  TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh_outlined,
              ),
              label: const Text(
                'Réessayer',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListeDocumentsVide
    extends StatelessWidget {
  const _ListeDocumentsVide({
    required this.peutUploader,
    required this.onActualiser,
    required this.onAjouter,
  });

  final bool peutUploader;
  final Future<void> Function()
      onActualiser;
  final VoidCallback? onAjouter;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onActualiser,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Icon(
            Icons.folder_open_outlined,
            size: 72,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun document disponible.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium,
          ),
          if (peutUploader &&
              onAjouter != null) ...[
            const SizedBox(height: 24),
            Center(
              child: FilledButton.icon(
                onPressed: onAjouter,
                icon: const Icon(
                  Icons
                      .upload_file_outlined,
                ),
                label: const Text(
                  'Ajouter un document',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _formatDate(
  DateTime? date,
) {
  if (date == null) {
    return 'Non renseignée';
  }

  final dateLocale = date.toLocal();

  final jour = dateLocale.day
      .toString()
      .padLeft(2, '0');

  final mois = dateLocale.month
      .toString()
      .padLeft(2, '0');

  final heure = dateLocale.hour
      .toString()
      .padLeft(2, '0');

  final minute = dateLocale.minute
      .toString()
      .padLeft(2, '0');

  return '$jour/$mois/${dateLocale.year} '
      'à $heure:$minute';
}