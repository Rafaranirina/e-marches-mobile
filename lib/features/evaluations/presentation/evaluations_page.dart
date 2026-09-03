import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/classement_soumission.dart';
import '../../../shared/models/commission.dart';
import '../../../shared/widgets/statut_chip.dart';
import 'evaluation_controller.dart';

class EvaluationsPage extends StatelessWidget {
  const EvaluationsPage({
    required this.appelOffreId,
    required this.appelOffreReference,
    super.key,
  });

  final String appelOffreId;
  final String appelOffreReference;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EvaluationController(
        appelOffreId: appelOffreId,
      )..charger(),
      child: _EvaluationsView(
        appelOffreReference: appelOffreReference,
      ),
    );
  }
}

class _EvaluationsView extends StatelessWidget {
  const _EvaluationsView({
    required this.appelOffreReference,
  });

  final String appelOffreReference;

  Future<void> _ouvrirEvaluation(
    BuildContext context,
    ClassementSoumission soumission,
  ) async {
    final controller =
        context.read<EvaluationController>();

    if (controller.commissions.isEmpty) {
      _afficherMessage(
        context,
        'Aucune commission n’est associée à cet appel d’offres.',
        estErreur: true,
      );
      return;
    }

    final donnees =
        await showDialog<_EvaluationFormData>(
      context: context,
      builder: (dialogContext) {
        return _EvaluationDialog(
          soumission: soumission,
          commissions: controller.commissions,
        );
      },
    );

    if (donnees == null || !context.mounted) {
      return;
    }

    final resultat = await controller.evaluer(
      soumissionId: soumission.soumissionId,
      commissionId: donnees.commissionId,
      noteTechnique: donnees.noteTechnique,
      noteFinanciere: donnees.noteFinanciere,
      commentaire: donnees.commentaire,
    );

    if (!context.mounted) {
      return;
    }

    _afficherMessage(
      context,
      resultat?.message ??
          controller.errorMessage ??
          'Impossible d’enregistrer l’évaluation.',
      estErreur: resultat == null,
    );
  }

  Future<void> _ouvrirAttribution(
    BuildContext context,
    ClassementSoumission soumission,
  ) async {
    final donnees =
        await showDialog<_AttributionFormData>(
      context: context,
      builder: (dialogContext) {
        return _AttributionDialog(
          soumission: soumission,
        );
      },
    );

    if (donnees == null || !context.mounted) {
      return;
    }

    final controller =
        context.read<EvaluationController>();

    final resultat = await controller.attribuer(
      soumissionId: soumission.soumissionId,
      referenceContrat: donnees.referenceContrat,
      objet: donnees.objet,
    );

    if (!context.mounted) {
      return;
    }

    _afficherMessage(
      context,
      resultat?.message ??
          controller.errorMessage ??
          'Impossible d’attribuer le marché.',
      estErreur: resultat == null,
    );
  }

  void _afficherMessage(
    BuildContext context,
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
              ? Theme.of(context).colorScheme.error
              : null,
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final controller =
        context.watch<EvaluationController>();

    final role = context
            .watch<AuthController>()
            .utilisateur
            ?.role
            .trim()
            .toLowerCase() ??
        '';

    final peutEvaluer = role == 'commission';

    final peutAttribuer =
        role == 'admin_national' ||
        role == 'administration';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Évaluations et classement',
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: controller.isLoading ||
                    controller.isSubmitting
                ? null
                : controller.actualiser,
            icon: const Icon(
              Icons.refresh_outlined,
            ),
          ),
        ],
        bottom: controller.isSubmitting
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _EnteteClassement(
              reference: appelOffreReference,
              nombreSoumissions:
                  controller.nombreSoumissions,
              nombreCommissions:
                  controller.commissions.length,
            ),
            Expanded(
              child: _buildContenu(
                context,
                controller,
                peutEvaluer: peutEvaluer,
                peutAttribuer: peutAttribuer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenu(
    BuildContext context,
    EvaluationController controller, {
    required bool peutEvaluer,
    required bool peutAttribuer,
  }) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (controller.hasError &&
        controller.classement.isEmpty) {
      return _ErreurEvaluations(
        message: controller.errorMessage ??
            'Impossible de charger le classement.',
        onRetry: controller.charger,
      );
    }

    if (controller.classement.isEmpty) {
      return _ClassementVide(
        onActualiser: controller.actualiser,
      );
    }

    return RefreshIndicator(
      onRefresh: controller.actualiser,
      child: ListView.separated(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          24,
        ),
        itemCount: controller.classement.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final soumission =
              controller.classement[index];

          return _ClassementCard(
            position: index + 1,
            soumission: soumission,
            peutEvaluer: peutEvaluer,
            peutAttribuer: peutAttribuer,
            isSubmitting: controller.isSubmitting,
            onEvaluer: () {
              _ouvrirEvaluation(
                context,
                soumission,
              );
            },
            onAttribuer: () {
              _ouvrirAttribution(
                context,
                soumission,
              );
            },
          );
        },
      ),
    );
  }
}

class _EnteteClassement extends StatelessWidget {
  const _EnteteClassement({
    required this.reference,
    required this.nombreSoumissions,
    required this.nombreCommissions,
  });

  final String reference;
  final int nombreSoumissions;
  final int nombreCommissions;

  @override
  Widget build(BuildContext context) {
    final referenceAffichee =
        reference.trim().isEmpty
            ? 'Appel d’offres'
            : reference;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        8,
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 26,
                child: Icon(
                  Icons.leaderboard_outlined,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      referenceAffichee,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight:
                                FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$nombreSoumissions soumission'
                      '${nombreSoumissions > 1 ? 's' : ''}'
                      ' • '
                      '$nombreCommissions commission'
                      '${nombreCommissions > 1 ? 's' : ''}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassementCard extends StatelessWidget {
  const _ClassementCard({
    required this.position,
    required this.soumission,
    required this.peutEvaluer,
    required this.peutAttribuer,
    required this.isSubmitting,
    required this.onEvaluer,
    required this.onAttribuer,
  });

  final int position;
  final ClassementSoumission soumission;
  final bool peutEvaluer;
  final bool peutAttribuer;
  final bool isSubmitting;
  final VoidCallback onEvaluer;
  final VoidCallback onAttribuer;

  @override
  Widget build(BuildContext context) {
    final statutNormalise =
        soumission.statut.trim().toLowerCase();

    final dejaEvaluee =
        soumission.noteGlobale != null;

    final dejaRetenue =
        statutNormalise == 'retenue';

    final peutAfficherEvaluation =
        peutEvaluer && !dejaEvaluee;

    final peutAfficherAttribution =
        peutAttribuer && !dejaRetenue;

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
                  child: Text(
                    position.toString(),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        soumission.reference
                                .trim()
                                .isEmpty
                            ? 'Référence non renseignée'
                            : soumission.reference,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _valeurOuDefaut(
                          soumission.entreprise,
                          defaut:
                              'Entreprise non renseignée',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatutClassementChip(
                  statut: soumission.statut,
                ),
              ],
            ),
            const Divider(height: 28),
            _InformationClassement(
              icon: Icons.payments_outlined,
              label: 'Montant proposé',
              valeur: _formatMontant(
                soumission.montantPropose,
              ),
            ),
            const SizedBox(height: 12),
            _InformationClassement(
              icon: Icons.grade_outlined,
              label: 'Note globale',
              valeur: _formatNote(
                soumission.noteGlobale,
              ),
            ),
            if (peutAfficherEvaluation ||
                peutAfficherAttribution) ...[
              const Divider(height: 30),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 10,
                children: [
                  if (peutAfficherEvaluation)
                    OutlinedButton.icon(
                      onPressed: isSubmitting
                          ? null
                          : onEvaluer,
                      icon: const Icon(
                        Icons.rate_review_outlined,
                      ),
                      label: const Text(
                        'Évaluer',
                      ),
                    ),
                  if (peutAfficherAttribution)
                    FilledButton.icon(
                      onPressed: isSubmitting
                          ? null
                          : onAttribuer,
                      icon: const Icon(
                        Icons.emoji_events_outlined,
                      ),
                      label: const Text(
                        'Attribuer',
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatMontant(
    double? montant,
  ) {
    if (montant == null) {
      return 'Non renseigné';
    }

    return '${NumberFormat.decimalPattern('fr_FR').format(montant)} Ar';
  }

  static String _formatNote(
    double? note,
  ) {
    if (note == null) {
      return 'Non évaluée';
    }

    return NumberFormat(
      '0.##',
      'fr_FR',
    ).format(note);
  }

  static String _valeurOuDefaut(
    String? valeur, {
    required String defaut,
  }) {
    final texte = valeur?.trim() ?? '';

    return texte.isEmpty ? defaut : texte;
  }
}

class _InformationClassement
    extends StatelessWidget {
  const _InformationClassement({
    required this.icon,
    required this.label,
    required this.valeur,
  });

  final IconData icon;
  final String label;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 21,
          color: Theme.of(context)
              .colorScheme
              .primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge,
              ),
              const SizedBox(height: 2),
              Text(valeur),
            ],
          ),
        ),
      ],
    );
  }
}

const _stylesStatutClassement = {
  'retenue': StatutChipStyle(
    libelle: 'Retenue',
    icone: Icons.emoji_events_outlined,
    couleur: StatutChipCouleur.primaire,
  ),
  'evaluee': StatutChipStyle(
    libelle: 'Évaluée',
    icone: Icons.grade_outlined,
    couleur: StatutChipCouleur.tertiaire,
  ),
  'évaluée': StatutChipStyle(
    libelle: 'Évaluée',
    icone: Icons.grade_outlined,
    couleur: StatutChipCouleur.tertiaire,
  ),
  'recevable': StatutChipStyle(
    libelle: 'Recevable',
    icone: Icons.verified_outlined,
    couleur: StatutChipCouleur.secondaire,
  ),
  'irrecevable': StatutChipStyle(
    libelle: 'Irrecevable',
    icone: Icons.cancel_outlined,
    couleur: StatutChipCouleur.erreur,
  ),
  'rejetee': StatutChipStyle(
    libelle: 'Rejetée',
    icone: Icons.block_outlined,
    couleur: StatutChipCouleur.erreur,
  ),
  'rejetée': StatutChipStyle(
    libelle: 'Rejetée',
    icone: Icons.block_outlined,
    couleur: StatutChipCouleur.erreur,
  ),
};

class _StatutClassementChip
    extends StatelessWidget {
  const _StatutClassementChip({
    required this.statut,
  });

  final String statut;

  @override
  Widget build(BuildContext context) {
    return StatutChip(
      statut: statut,
      styles: _stylesStatutClassement,
    );
  }
}

class _EvaluationDialog extends StatefulWidget {
  const _EvaluationDialog({
    required this.soumission,
    required this.commissions,
  });

  final ClassementSoumission soumission;
  final List<Commission> commissions;

  @override
  State<_EvaluationDialog> createState() =>
      _EvaluationDialogState();
}

class _EvaluationDialogState
    extends State<_EvaluationDialog> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController
      _noteTechniqueController =
      TextEditingController();

  final TextEditingController
      _noteFinanciereController =
      TextEditingController();

  final TextEditingController
      _commentaireController =
      TextEditingController();

  String? _commissionId;

  @override
  void initState() {
    super.initState();

    if (widget.commissions.length == 1) {
      _commissionId =
          widget.commissions.first.id;
    }
  }

  @override
  void dispose() {
    _noteTechniqueController.dispose();
    _noteFinanciereController.dispose();
    _commentaireController.dispose();
    super.dispose();
  }

  void _confirmer() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final noteTechnique = _parseNombre(
      _noteTechniqueController.text,
    );

    final noteFinanciere = _parseNombre(
      _noteFinanciereController.text,
    );

    final commissionId = _commissionId;

    if (noteTechnique == null ||
        noteFinanciere == null ||
        commissionId == null ||
        commissionId.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      _EvaluationFormData(
        commissionId: commissionId,
        noteTechnique: noteTechnique,
        noteFinanciere: noteFinanciere,
        commentaire:
            _commentaireController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Évaluer la soumission',
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode:
                AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.soumission.reference,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium,
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: _commissionId,
                  isExpanded: true,
                  decoration:
                      const InputDecoration(
                    labelText: 'Commission *',
                    prefixIcon: Icon(
                      Icons.groups_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                  items: widget.commissions
                      .map(
                        (commission) =>
                            DropdownMenuItem<String>(
                          value: commission.id,
                          child: Text(
                            commission.nom,
                            overflow:
                                TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _commissionId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return 'Sélectionnez une commission.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller:
                      _noteTechniqueController,
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Note technique *',
                    prefixIcon: Icon(
                      Icons.engineering_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                  validator: _validerNote,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller:
                      _noteFinanciereController,
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Note financière *',
                    prefixIcon: Icon(
                      Icons.payments_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                  validator: _validerNote,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller:
                      _commentaireController,
                  minLines: 3,
                  maxLines: 6,
                  textCapitalization:
                      TextCapitalization.sentences,
                  decoration:
                      const InputDecoration(
                    labelText: 'Commentaire',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(
                      Icons.comment_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          onPressed: _confirmer,
          icon: const Icon(
            Icons.save_outlined,
          ),
          label: const Text(
            'Enregistrer',
          ),
        ),
      ],
    );
  }

  static String? _validerNote(
    String? valeur,
  ) {
    if (valeur == null ||
        valeur.trim().isEmpty) {
      return 'La note est obligatoire.';
    }

    final note = _parseNombre(valeur);

    if (note == null) {
      return 'Saisissez une note valide.';
    }

    if (note < 0) {
      return 'La note ne peut pas être négative.';
    }

    return null;
  }

  static double? _parseNombre(
    String valeur,
  ) {
    final texte = valeur
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'\s+'), '')
        .trim();

    if (texte.isEmpty) {
      return null;
    }

    return double.tryParse(texte);
  }
}

class _AttributionDialog extends StatefulWidget {
  const _AttributionDialog({
    required this.soumission,
  });

  final ClassementSoumission soumission;

  @override
  State<_AttributionDialog> createState() =>
      _AttributionDialogState();
}

class _AttributionDialogState
    extends State<_AttributionDialog> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController
      _referenceController =
      TextEditingController();

  final TextEditingController
      _objetController =
      TextEditingController();

  @override
  void dispose() {
    _referenceController.dispose();
    _objetController.dispose();
    super.dispose();
  }

  void _confirmer() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      _AttributionFormData(
        referenceContrat:
            _referenceController.text.trim(),
        objet: _objetController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entreprise =
        widget.soumission.entreprise?.trim() ?? '';

    return AlertDialog(
      title: const Text(
        'Attribuer le marché',
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode:
                AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Soumission : '
                  '${widget.soumission.reference}',
                ),
                const SizedBox(height: 6),
                Text(
                  'Entreprise : '
                  '${entreprise.isEmpty ? 'Non renseignée' : entreprise}',
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller:
                      _referenceController,
                  textCapitalization:
                      TextCapitalization.characters,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Référence du contrat *',
                    hintText:
                        'Exemple : CTR-2026-001',
                    prefixIcon: Icon(
                      Icons.article_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'La référence du contrat est obligatoire.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller:
                      _objetController,
                  minLines: 3,
                  maxLines: 6,
                  textCapitalization:
                      TextCapitalization.sentences,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Objet du contrat',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(
                      Icons.description_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cette action créera automatiquement le contrat et marquera la soumission comme retenue.',
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          onPressed: _confirmer,
          icon: const Icon(
            Icons.emoji_events_outlined,
          ),
          label: const Text(
            'Attribuer',
          ),
        ),
      ],
    );
  }
}

class _ErreurEvaluations
    extends StatelessWidget {
  const _ErreurEvaluations({
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
          mainAxisSize: MainAxisSize.min,
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
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh,
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

class _ClassementVide extends StatelessWidget {
  const _ClassementVide({
    required this.onActualiser,
  });

  final Future<void> Function() onActualiser;

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
            Icons.leaderboard_outlined,
            size: 72,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune soumission disponible dans le classement.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium,
          ),
        ],
      ),
    );
  }
}

class _EvaluationFormData {
  const _EvaluationFormData({
    required this.commissionId,
    required this.noteTechnique,
    required this.noteFinanciere,
    required this.commentaire,
  });

  final String commissionId;
  final double noteTechnique;
  final double noteFinanciere;
  final String commentaire;
}

class _AttributionFormData {
  const _AttributionFormData({
    required this.referenceContrat,
    required this.objet,
  });

  final String referenceContrat;
  final String objet;
}