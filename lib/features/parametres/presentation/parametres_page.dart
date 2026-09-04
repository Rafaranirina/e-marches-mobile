import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'parametres_controller.dart';

// Le backend limite la photo de profil à 5 Mo
// (photoProfil.middleware.js) — on le vérifie côté client pour éviter un
// aller-retour réseau inutile en cas de fichier trop volumineux.
const int _tailleMaxPhotoOctets = 5 * 1024 * 1024;

class ParametresPage extends StatelessWidget {
  const ParametresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ParametresController()..charger(),
      child: const _ParametresView(),
    );
  }
}

class _ParametresView extends StatefulWidget {
  const _ParametresView();

  @override
  State<_ParametresView> createState() => _ParametresViewState();
}

class _ParametresViewState extends State<_ParametresView> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();

  bool _champsInitialises = false;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  void _afficherMessage(String message, {bool estErreur = false}) {
    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor:
              estErreur ? Theme.of(context).colorScheme.error : null,
          content: Text(message),
        ),
      );
  }

  Future<void> _enregistrerProfil() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = context.read<ParametresController>();

    final message = await controller.modifierProfil(
      nom: _nomController.text,
      prenom: _prenomController.text,
      telephone: _telephoneController.text,
    );

    if (!mounted) {
      return;
    }

    _afficherMessage(
      message ?? controller.errorMessage ?? 'Impossible de modifier le profil.',
      estErreur: message == null,
    );
  }

  Future<void> _changerPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Prendre une photo'),
                onTap: () => Navigator.of(sheetContext).pop(
                  ImageSource.camera,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choisir depuis la galerie'),
                onTap: () => Navigator.of(sheetContext).pop(
                  ImageSource.gallery,
                ),
              ),
            ],
          ),
        );
      },
    );

    if (source == null || !mounted) {
      return;
    }

    final String? chemin;

    if (source == ImageSource.camera) {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 85,
      );

      chemin = photo?.path;
    } else {
      final resultat = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      chemin = resultat?.files.single.path;
    }

    if (chemin == null || !mounted) {
      return;
    }

    final taille = await File(chemin).length();

    if (!mounted) {
      return;
    }

    if (taille > _tailleMaxPhotoOctets) {
      _afficherMessage(
        'Cette image dépasse la taille maximale autorisée (5 Mo). '
        'Choisissez une image plus légère.',
        estErreur: true,
      );
      return;
    }

    final controller = context.read<ParametresController>();
    final message = await controller.uploaderPhoto(chemin);

    if (!mounted) {
      return;
    }

    _afficherMessage(
      message ??
          controller.errorMessage ??
          'Impossible de téléverser la photo.',
      estErreur: message == null,
    );
  }

  Future<void> _supprimerPhoto() async {
    final controller = context.read<ParametresController>();
    final message = await controller.supprimerPhoto();

    if (!mounted) {
      return;
    }

    _afficherMessage(
      message ??
          controller.errorMessage ??
          'Impossible de supprimer la photo.',
      estErreur: message == null,
    );
  }

  Future<void> _confirmerCode2FA(
    TextEditingController codeController,
  ) async {
    final controller = context.read<ParametresController>();
    final message =
        await controller.confirmerActivation2FA(codeController.text);

    if (!mounted) {
      return;
    }

    _afficherMessage(
      message ?? controller.errorMessage ?? 'Le code saisi est invalide.',
      estErreur: message == null,
    );
  }

  Future<void> _desactiver2FA() async {
    final motDePasseController = TextEditingController();

    final confirmer = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Désactiver la double authentification'),
          content: TextField(
            controller: motDePasseController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Mot de passe actuel',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Désactiver'),
            ),
          ],
        );
      },
    );

    if (confirmer != true || !mounted) {
      motDePasseController.dispose();
      return;
    }

    final controller = context.read<ParametresController>();
    final message =
        await controller.desactiver2FA(motDePasseController.text);

    motDePasseController.dispose();

    if (!mounted) {
      return;
    }

    _afficherMessage(
      message ??
          controller.errorMessage ??
          'Impossible de désactiver la double authentification.',
      estErreur: message == null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ParametresController>();

    if (!_champsInitialises && controller.profil != null) {
      _nomController.text = controller.profil!.nom;
      _prenomController.text = controller.profil!.prenom;
      _telephoneController.text = controller.profil!.telephone;
      _champsInitialises = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: SafeArea(
        child: controller.isLoading && controller.profil == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _CarteSectionPhoto(
                    controller: controller,
                    onChanger: _changerPhoto,
                    onSupprimer: _supprimerPhoto,
                  ),
                  const SizedBox(height: 16),
                  _CarteSectionProfil(
                    formKey: _formKey,
                    nomController: _nomController,
                    prenomController: _prenomController,
                    telephoneController: _telephoneController,
                    isSaving: controller.isSavingProfil,
                    onEnregistrer: _enregistrerProfil,
                  ),
                  const SizedBox(height: 16),
                  _CarteSection2FA(
                    controller: controller,
                    onDemarrerActivation:
                        controller.demarrerActivation2FA,
                    onAnnulerActivation:
                        controller.annulerActivation2FA,
                    onConfirmerCode: _confirmerCode2FA,
                    onDesactiver: _desactiver2FA,
                  ),
                ],
              ),
      ),
    );
  }
}

class _CarteSectionPhoto extends StatelessWidget {
  const _CarteSectionPhoto({
    required this.controller,
    required this.onChanger,
    required this.onSupprimer,
  });

  final ParametresController controller;
  final VoidCallback onChanger;
  final VoidCallback onSupprimer;

  @override
  Widget build(BuildContext context) {
    final photo = controller.photo;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundImage:
                  photo != null ? MemoryImage(photo.octets) : null,
              child: photo == null
                  ? const Icon(Icons.person_outline, size: 48)
                  : null,
            ),
            const SizedBox(height: 16),
            if (controller.isUploadingPhoto)
              const CircularProgressIndicator()
            else
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: onChanger,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(
                      photo == null
                          ? 'Ajouter une photo'
                          : 'Changer la photo',
                    ),
                  ),
                  if (photo != null)
                    OutlinedButton.icon(
                      onPressed: onSupprimer,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Supprimer'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _CarteSectionProfil extends StatelessWidget {
  const _CarteSectionProfil({
    required this.formKey,
    required this.nomController,
    required this.prenomController,
    required this.telephoneController,
    required this.isSaving,
    required this.onEnregistrer,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nomController;
  final TextEditingController prenomController;
  final TextEditingController telephoneController;
  final bool isSaving;
  final VoidCallback onEnregistrer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Mes informations',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Divider(height: 28),
              TextFormField(
                controller: nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est obligatoire.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: prenomController,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: telephoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: isSaving ? null : onEnregistrer,
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarteSection2FA extends StatefulWidget {
  const _CarteSection2FA({
    required this.controller,
    required this.onDemarrerActivation,
    required this.onAnnulerActivation,
    required this.onConfirmerCode,
    required this.onDesactiver,
  });

  final ParametresController controller;
  final Future<void> Function() onDemarrerActivation;
  final VoidCallback onAnnulerActivation;
  final Future<void> Function(TextEditingController) onConfirmerCode;
  final Future<void> Function() onDesactiver;

  @override
  State<_CarteSection2FA> createState() => _CarteSection2FAState();
}

class _CarteSection2FAState extends State<_CarteSection2FA> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final activation = controller.activation2FAEnCours;
    final doubleAuthActive = controller.profil?.doubleAuthActive ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Double authentification',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            if (activation != null) ...[
              const Text(
                'Scannez ce QR code avec votre application d’authentification, puis saisissez le code généré.',
              ),
              const SizedBox(height: 16),
              if (activation.qrCodeDataUrl.isNotEmpty)
                Center(
                  child: Image.memory(
                    _decoderQrCode(activation.qrCodeDataUrl),
                    width: 180,
                    height: 180,
                  ),
                ),
              const SizedBox(height: 12),
              if (activation.secret.isNotEmpty) ...[
                Text(
                  'Clé secrète (si le scan est impossible) :',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                SelectableText(
                  activation.secret,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Code à 6 chiffres',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              if (controller.isTogglingDeuxFacteurs)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onAnnulerActivation,
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            widget.onConfirmerCode(_codeController),
                        child: const Text('Confirmer'),
                      ),
                    ),
                  ],
                ),
            ] else ...[
              Text(
                doubleAuthActive
                    ? 'La double authentification est activée sur votre compte.'
                    : 'La double authentification n’est pas activée. Elle ajoute une étape de sécurité à la connexion.',
              ),
              const SizedBox(height: 16),
              if (controller.isTogglingDeuxFacteurs)
                const Center(child: CircularProgressIndicator())
              else
                FilledButton.icon(
                  onPressed: doubleAuthActive
                      ? widget.onDesactiver
                      : widget.onDemarrerActivation,
                  icon: Icon(
                    doubleAuthActive
                        ? Icons.lock_open_outlined
                        : Icons.lock_outline,
                  ),
                  label: Text(
                    doubleAuthActive ? 'Désactiver' : 'Activer',
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  static Uint8List _decoderQrCode(String dataUrl) {
    final index = dataUrl.indexOf(',');
    final base64Data = index >= 0 ? dataUrl.substring(index + 1) : dataUrl;

    return base64Decode(base64Data);
  }
}
