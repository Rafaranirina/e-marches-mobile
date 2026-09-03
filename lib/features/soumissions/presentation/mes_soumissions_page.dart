import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../documents/presentation/documents_page.dart';
import '../data/soumission.dart';
import 'mes_soumissions_controller.dart';
import 'recepisse_dialog.dart';

class MesSoumissionsPage extends StatelessWidget {
  const MesSoumissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MesSoumissionsController()..charger(),
      child: const _MesSoumissionsView(),
    );
  }
}

class _MesSoumissionsView extends StatelessWidget {
  const _MesSoumissionsView();

  Future<void> _ouvrirDocuments(
    BuildContext context, {
    required Soumission soumission,
  }) async {
    final reference = soumission.reference.trim();

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DocumentsPage(
          contexte: 'soumission',
          contexteId: soumission.id,
          titre: reference.isEmpty
              ? 'Documents de la soumission'
              : 'Documents de la soumission $reference',
          peutUploader: soumission.estBrouillon,
        ),
      ),
    );
  }

  Future<void> _modifierBrouillon(
    BuildContext context, {
    required Soumission soumission,
  }) async {
    final controller =
        context.read<MesSoumissionsController>();

    final donnees = await showDialog<_DonneesModification>(
      context: context,
      builder: (_) => _ModifierBrouillonDialog(
        soumission: soumission,
      ),
    );

    if (donnees == null || !context.mounted) {
      return;
    }

    final resultat = await controller.modifierBrouillon(
      soumissionId: soumission.id,
      montantPropose: donnees.montantPropose,
      delaiExecution: donnees.delaiExecution,
    );

    if (!context.mounted) {
      return;
    }

    _afficherMessage(
      context,
      resultat?.message ??
          controller.errorMessage ??
          'Impossible de modifier la soumission.',
      estErreur: resultat == null,
    );
  }

  Future<void> _transmettre(
    BuildContext context, {
    required Soumission soumission,
  }) async {
    final controller =
        context.read<MesSoumissionsController>();

    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Transmettre définitivement'),
          content: const Text(
            'Après transmission, la soumission ne pourra plus être modifiée. '
            'Assurez-vous d’avoir ajouté tous les documents nécessaires. Continuer ?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Transmettre'),
            ),
          ],
        );
      },
    );

    if (confirmation != true || !context.mounted) {
      return;
    }

    final resultat = await controller.transmettre(
      soumissionId: soumission.id,
    );

    if (!context.mounted) {
      return;
    }

    if (resultat == null) {
      _afficherMessage(
        context,
        controller.errorMessage ??
            'Impossible de transmettre la soumission.',
        estErreur: true,
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => RecepisseDialog(
        recepisse: resultat.recepisse,
      ),
    );
  }

  void _afficherMessage(
    BuildContext context,
    String message, {
    bool estErreur = false,
  }) {
    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: estErreur
              ? Theme.of(context).colorScheme.error
              : null,
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MesSoumissionsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes soumissions'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed:
                controller.isLoading ? null : controller.actualiser,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: _buildContenu(context, controller),
      ),
    );
  }

  Widget _buildContenu(
    BuildContext context,
    MesSoumissionsController controller,
  ) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.hasError && controller.soumissions.isEmpty) {
      return _Erreur(
        message: controller.errorMessage ??
            'Impossible de charger vos soumissions.',
        onRetry: controller.charger,
      );
    }

    if (controller.soumissions.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.actualiser,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 80),
            Icon(Icons.inbox_outlined, size: 72),
            SizedBox(height: 16),
            Text(
              'Vous n’avez déposé aucune soumission pour le moment.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.actualiser,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: controller.soumissions.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final soumission = controller.soumissions[index];

          return _MaSoumissionCard(
            soumission: soumission,
            actionEnCours:
                controller.actionEnCours(soumission.id),
            onDocuments: () => _ouvrirDocuments(
              context,
              soumission: soumission,
            ),
            onModifier: () => _modifierBrouillon(
              context,
              soumission: soumission,
            ),
            onTransmettre: () => _transmettre(
              context,
              soumission: soumission,
            ),
          );
        },
      ),
    );
  }
}

class _MaSoumissionCard extends StatelessWidget {
  const _MaSoumissionCard({
    required this.soumission,
    required this.actionEnCours,
    required this.onDocuments,
    required this.onModifier,
    required this.onTransmettre,
  });

  final Soumission soumission;
  final bool actionEnCours;
  final VoidCallback onDocuments;
  final VoidCallback onModifier;
  final VoidCallback onTransmettre;

  @override
  Widget build(BuildContext context) {
    final reference = soumission.reference.trim();
    final appelOffre = soumission.appelOffreReference?.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    reference.isEmpty
                        ? 'Référence en attente de transmission'
                        : reference,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                _StatutSoumissionChip(statut: soumission.statut),
              ],
            ),
            if (appelOffre != null && appelOffre.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Appel d’offres : $appelOffre',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            _Information(
              icon: Icons.payments_outlined,
              label: 'Montant proposé',
              valeur: _formatMontant(soumission.montantPropose),
            ),
            const SizedBox(height: 12),
            _Information(
              icon: Icons.timer_outlined,
              label: 'Délai d’exécution',
              valeur: soumission.delaiExecution,
            ),
            const SizedBox(height: 12),
            _Information(
              icon: Icons.folder_outlined,
              label: 'Documents',
              valeur: (soumission.nombreDocuments ?? 0).toString(),
            ),
            const Divider(height: 30),
            if (actionEnCours)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onDocuments,
                  icon: const Icon(Icons.folder_outlined),
                  label: const Text('Documents de la soumission'),
                ),
              ),
              if (soumission.estBrouillon) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onModifier,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Modifier'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onTransmettre,
                        icon: const Icon(Icons.send_outlined),
                        label: const Text('Transmettre'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  static String _formatMontant(double? montant) {
    if (montant == null) {
      return 'Non renseigné';
    }

    return '${NumberFormat.decimalPattern('fr_FR').format(montant)} Ar';
  }
}

class _Information extends StatelessWidget {
  const _Information({
    required this.icon,
    required this.label,
    required this.valeur,
  });

  final IconData icon;
  final String label;
  final String? valeur;

  @override
  Widget build(BuildContext context) {
    final texte = valeur?.trim() ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 21, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 2),
              Text(texte.isEmpty ? 'Non renseigné' : texte),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatutSoumissionChip extends StatelessWidget {
  const _StatutSoumissionChip({required this.statut});

  final String statut;

  @override
  Widget build(BuildContext context) {
    final statutNormalise = statut.trim().toLowerCase();
    final couleurs = Theme.of(context).colorScheme;

    final String libelle;
    final Color fond;
    final Color premierPlan;
    final IconData icone;

    switch (statutNormalise) {
      case 'brouillon':
        libelle = 'Brouillon';
        fond = couleurs.surfaceContainerHighest;
        premierPlan = couleurs.onSurfaceVariant;
        icone = Icons.edit_note_outlined;
        break;

      case 'soumise':
        libelle = 'Transmise';
        fond = couleurs.secondaryContainer;
        premierPlan = couleurs.onSecondaryContainer;
        icone = Icons.schedule_outlined;
        break;

      case 'recevable':
        libelle = 'Recevable';
        fond = couleurs.primaryContainer;
        premierPlan = couleurs.onPrimaryContainer;
        icone = Icons.verified_outlined;
        break;

      case 'irrecevable':
        libelle = 'Irrecevable';
        fond = couleurs.errorContainer;
        premierPlan = couleurs.onErrorContainer;
        icone = Icons.cancel_outlined;
        break;

      case 'evaluee':
        libelle = 'Évaluée';
        fond = couleurs.secondaryContainer;
        premierPlan = couleurs.onSecondaryContainer;
        icone = Icons.fact_check_outlined;
        break;

      case 'retenue':
        libelle = 'Retenue';
        fond = couleurs.primaryContainer;
        premierPlan = couleurs.onPrimaryContainer;
        icone = Icons.emoji_events_outlined;
        break;

      case 'rejetee':
        libelle = 'Rejetée';
        fond = couleurs.errorContainer;
        premierPlan = couleurs.onErrorContainer;
        icone = Icons.block_outlined;
        break;

      default:
        libelle = statutNormalise.isEmpty
            ? 'Non défini'
            : statut.replaceAll('_', ' ');
        fond = couleurs.surfaceContainerHighest;
        premierPlan = couleurs.onSurfaceVariant;
        icone = Icons.info_outline;
    }

    return Chip(
      backgroundColor: fond,
      side: BorderSide.none,
      avatar: Icon(icone, size: 17, color: premierPlan),
      label: Text(
        libelle,
        style: TextStyle(color: premierPlan, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ModifierBrouillonDialog extends StatefulWidget {
  const _ModifierBrouillonDialog({required this.soumission});

  final Soumission soumission;

  @override
  State<_ModifierBrouillonDialog> createState() =>
      _ModifierBrouillonDialogState();
}

class _ModifierBrouillonDialogState
    extends State<_ModifierBrouillonDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _montantController;
  late final TextEditingController _delaiController;

  @override
  void initState() {
    super.initState();
    _montantController = TextEditingController(
      text: widget.soumission.montantPropose?.toString() ?? '',
    );
    _delaiController = TextEditingController(
      text: widget.soumission.delaiExecution ?? '',
    );
  }

  @override
  void dispose() {
    _montantController.dispose();
    _delaiController.dispose();
    super.dispose();
  }

  void _confirmer() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      _DonneesModification(
        montantPropose: _parseMontant(_montantController.text),
        delaiExecution: _delaiController.text,
      ),
    );
  }

  static double? _parseMontant(String valeur) {
    final texte = valeur
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(',', '.')
        .trim();

    if (texte.isEmpty) {
      return null;
    }

    return double.tryParse(texte);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier la soumission'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _montantController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Montant proposé *',
                  suffixText: 'Ar',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final montant = _parseMontant(value ?? '');

                  if (value == null || value.trim().isEmpty) {
                    return 'Le montant proposé est obligatoire.';
                  }

                  if (montant == null || montant <= 0) {
                    return 'Saisissez un montant valide.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _delaiController,
                decoration: const InputDecoration(
                  labelText: 'Délai d’exécution',
                  hintText: 'Exemple : 60 jours',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _confirmer,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

class _DonneesModification {
  const _DonneesModification({
    this.montantPropose,
    this.delaiExecution,
  });

  final double? montantPropose;
  final String? delaiExecution;
}

class _Erreur extends StatelessWidget {
  const _Erreur({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
