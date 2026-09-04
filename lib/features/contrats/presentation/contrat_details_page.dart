import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/circle_icon.dart';
import '../../../shared/widgets/statut_chip.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../documents/presentation/documents_page.dart';
import '../data/contrat.dart';
import '../data/jalon_contrat.dart';
import '../data/paiement.dart';
import 'contrat_details_controller.dart';
import 'contrat_statut_styles.dart';

class ContratDetailsPage extends StatelessWidget {
  const ContratDetailsPage({
    required this.contratId,
    super.key,
  });

  final String contratId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ContratDetailsController(
        contratId: contratId,
      )..charger(),
      child: const _ContratDetailsView(),
    );
  }
}

class _ContratDetailsView extends StatelessWidget {
  const _ContratDetailsView();

  Future<void> _ouvrirDocuments(
    BuildContext context,
    Contrat contrat, {
    required bool peutUploader,
  }) async {
    final reference = contrat.reference.trim();

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DocumentsPage(
          contexte: 'contrat',
          contexteId: contrat.id,
          titre: reference.isEmpty
              ? 'Documents du contrat'
              : 'Documents du contrat $reference',
          peutUploader: peutUploader,
        ),
      ),
    );
  }

  Future<void> _modifierContrat(
    BuildContext context,
    Contrat contrat,
  ) async {
    final donnees =
        await showDialog<_ModificationContratData>(
      context: context,
      builder: (_) => _ModificationContratDialog(
        contrat: contrat,
      ),
    );

    if (donnees == null || !context.mounted) {
      return;
    }

    final controller =
        context.read<ContratDetailsController>();

    final resultat =
        await controller.mettreAJourContrat(
      statut: donnees.statut,
      dateSignature: donnees.dateSignature,
      dateDebut: donnees.dateDebut,
      dateFin: donnees.dateFin,
    );

    if (!context.mounted) {
      return;
    }

    _afficherMessage(
      context,
      resultat?.message ??
          controller.errorMessage ??
          'Impossible de mettre à jour le contrat.',
      estErreur: resultat == null,
    );
  }

  Future<void> _ajouterPaiement(
    BuildContext context,
  ) async {
    final donnees =
        await showDialog<_AjoutPaiementData>(
      context: context,
      builder: (_) =>
          const _AjoutPaiementDialog(),
    );

    if (donnees == null || !context.mounted) {
      return;
    }

    final controller =
        context.read<ContratDetailsController>();

    final resultat =
        await controller.ajouterPaiement(
      montant: donnees.montant,
      reference: donnees.reference,
      description: donnees.description,
      dateEcheance: donnees.dateEcheance,
    );

    if (!context.mounted) {
      return;
    }

    _afficherMessage(
      context,
      resultat?.message ??
          controller.errorMessage ??
          'Impossible d’ajouter le paiement.',
      estErreur: resultat == null,
    );
  }

  Future<void> _validerPaiement(
    BuildContext context,
    Paiement paiement,
  ) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Valider le paiement',
          ),
          content: Text(
            'Confirmer le paiement de '
            '${_formatMontant(paiement.montant)} ?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                'Annuler',
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              icon: const Icon(
                Icons.check_circle_outline,
              ),
              label: const Text(
                'Valider',
              ),
            ),
          ],
        );
      },
    );

    if (confirmation != true ||
        !context.mounted) {
      return;
    }

    final controller =
        context.read<ContratDetailsController>();

    final resultat =
        await controller.validerPaiement(
      paiement.id,
    );

    if (!context.mounted) {
      return;
    }

    _afficherMessage(
      context,
      resultat?.message ??
          controller.errorMessage ??
          'Impossible de valider le paiement.',
      estErreur: resultat == null,
    );
  }

  Future<void> _archiverContrat(
    BuildContext context,
  ) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Archiver le contrat',
          ),
          content: const Text(
            'Ce contrat ne sera plus visible dans la liste active. '
            'Confirmer l’archivage ?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                'Annuler',
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              icon: const Icon(
                Icons.archive_outlined,
              ),
              label: const Text(
                'Archiver',
              ),
            ),
          ],
        );
      },
    );

    if (confirmation != true ||
        !context.mounted) {
      return;
    }

    final controller =
        context.read<ContratDetailsController>();

    final resultat =
        await controller.archiver();

    if (!context.mounted) {
      return;
    }

    _afficherMessage(
      context,
      resultat?.message ??
          controller.errorMessage ??
          'Impossible d’archiver le contrat.',
      estErreur: resultat == null,
    );
  }

  Future<void> _desarchiverContrat(
    BuildContext context,
  ) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Désarchiver le contrat',
          ),
          content: const Text(
            'Ce contrat redeviendra visible dans la liste active. '
            'Confirmer le désarchivage ?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                'Annuler',
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              icon: const Icon(
                Icons.unarchive_outlined,
              ),
              label: const Text(
                'Désarchiver',
              ),
            ),
          ],
        );
      },
    );

    if (confirmation != true ||
        !context.mounted) {
      return;
    }

    final controller =
        context.read<ContratDetailsController>();

    final resultat =
        await controller.desarchiver();

    if (!context.mounted) {
      return;
    }

    _afficherMessage(
      context,
      resultat?.message ??
          controller.errorMessage ??
          'Impossible de désarchiver le contrat.',
      estErreur: resultat == null,
    );
  }

  Future<void> _modifierAvancement(
    BuildContext context,
    int avancementActuel,
  ) async {
    final nouvelAvancement =
        await showDialog<int>(
      context: context,
      builder: (_) => _AvancementDialog(
        avancementInitial: avancementActuel,
      ),
    );

    if (nouvelAvancement == null ||
        !context.mounted) {
      return;
    }

    final controller =
        context.read<ContratDetailsController>();

    final resultat = await controller
        .mettreAJourAvancement(
      nouvelAvancement,
    );

    if (!context.mounted) {
      return;
    }

    _afficherMessage(
      context,
      resultat?.message ??
          controller.errorMessage ??
          'Impossible de mettre à jour l’avancement.',
      estErreur: resultat == null,
    );
  }

  Future<void> _ajouterJalon(
    BuildContext context,
  ) async {
    final donnees =
        await showDialog<_JalonFormData>(
      context: context,
      builder: (_) => const _JalonDialog(),
    );

    if (donnees == null || !context.mounted) {
      return;
    }

    final controller =
        context.read<ContratDetailsController>();

    final resultat = await controller.creerJalon(
      titre: donnees.titre,
      description: donnees.description,
      ordre: donnees.ordre,
      datePrevue: donnees.datePrevue,
    );

    if (!context.mounted) {
      return;
    }

    _afficherMessage(
      context,
      resultat?.message ??
          controller.errorMessage ??
          'Impossible de créer le jalon.',
      estErreur: resultat == null,
    );
  }

  Future<void> _modifierJalon(
    BuildContext context,
    JalonContrat jalon,
  ) async {
    final donnees =
        await showDialog<_JalonFormData>(
      context: context,
      builder: (_) => _JalonDialog(
        jalon: jalon,
      ),
    );

    if (donnees == null || !context.mounted) {
      return;
    }

    final controller =
        context.read<ContratDetailsController>();

    final resultat = await controller.modifierJalon(
      jalonId: jalon.id,
      titre: donnees.titre,
      description: donnees.description,
      statut: donnees.statut,
      datePrevue: donnees.datePrevue,
      dateReelle: donnees.dateReelle,
    );

    if (!context.mounted) {
      return;
    }

    _afficherMessage(
      context,
      resultat?.message ??
          controller.errorMessage ??
          'Impossible de mettre à jour le jalon.',
      estErreur: resultat == null,
    );
  }

  Future<void> _supprimerJalon(
    BuildContext context,
    JalonContrat jalon,
  ) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Supprimer le jalon',
          ),
          content: Text(
            'Confirmer la suppression du jalon '
            '« ${jalon.titre} » ?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                'Annuler',
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              icon: const Icon(
                Icons.delete_outline,
              ),
              label: const Text(
                'Supprimer',
              ),
            ),
          ],
        );
      },
    );

    if (confirmation != true ||
        !context.mounted) {
      return;
    }

    final controller =
        context.read<ContratDetailsController>();

    final succes =
        await controller.supprimerJalon(
      jalon.id,
    );

    if (!context.mounted) {
      return;
    }

    _afficherMessage(
      context,
      succes
          ? 'Jalon supprimé.'
          : controller.errorMessage ??
              'Impossible de supprimer le jalon.',
      estErreur: !succes,
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
        context.watch<ContratDetailsController>();

    final role = context
            .watch<AuthController>()
            .utilisateur
            ?.role
            .trim()
            .toLowerCase() ??
        '';

    final peutGerer =
        role == 'admin_national' ||
            role == 'administration';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Détail du contrat',
        ),
        actions: [
          if (controller.contrat != null)
            IconButton(
              tooltip: 'Documents du contrat',
              onPressed:
                  controller.isSubmitting
                      ? null
                      : () {
                          _ouvrirDocuments(
                            context,
                            controller.contrat!,
                            peutUploader:
                                peutGerer,
                          );
                        },
              icon: const Icon(
                Icons.folder_outlined,
              ),
            ),
          if (peutGerer &&
              controller.contrat != null)
            IconButton(
              tooltip: 'Modifier le contrat',
              onPressed:
                  controller.isSubmitting
                      ? null
                      : () {
                          _modifierContrat(
                            context,
                            controller.contrat!,
                          );
                        },
              icon: const Icon(
                Icons.edit_outlined,
              ),
            ),
          if (peutGerer &&
              controller.contrat != null)
            PopupMenuButton<_ActionContrat>(
              tooltip: 'Autres actions',
              enabled: !controller.isSubmitting,
              onSelected: (action) {
                switch (action) {
                  case _ActionContrat.archiver:
                    _archiverContrat(context);
                    break;

                  case _ActionContrat.desarchiver:
                    _desarchiverContrat(context);
                    break;
                }
              },
              itemBuilder: (_) => [
                if (!controller.contrat!.archive)
                  const PopupMenuItem(
                    value:
                        _ActionContrat.archiver,
                    child: ListTile(
                      leading: Icon(
                        Icons.archive_outlined,
                      ),
                      title: Text(
                        'Archiver le contrat',
                      ),
                    ),
                  )
                else
                  const PopupMenuItem(
                    value: _ActionContrat
                        .desarchiver,
                    child: ListTile(
                      leading: Icon(
                        Icons.unarchive_outlined,
                      ),
                      title: Text(
                        'Désarchiver le contrat',
                      ),
                    ),
                  ),
              ],
            ),
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
                preferredSize:
                    Size.fromHeight(3),
                child:
                    LinearProgressIndicator(),
              )
            : null,
      ),
      floatingActionButton:
          peutGerer &&
                  !controller.isLoading &&
                  controller.contrat != null
              ? FloatingActionButton.extended(
                  onPressed:
                      controller.isSubmitting
                          ? null
                          : () {
                              _ajouterPaiement(
                                context,
                              );
                            },
                  icon: const Icon(
                    Icons.add_card_outlined,
                  ),
                  label: const Text(
                    'Ajouter un paiement',
                  ),
                )
              : null,
      body: SafeArea(
        child: _buildContenu(
          context,
          controller,
          peutGerer: peutGerer,
        ),
      ),
    );
  }

  Widget _buildContenu(
    BuildContext context,
    ContratDetailsController controller, {
    required bool peutGerer,
  }) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (controller.contrat == null) {
      return _ErreurContrat(
        message: controller.errorMessage ??
            'Le contrat est introuvable.',
        onRetry: controller.charger,
      );
    }

    final contrat = controller.contrat!;

    return RefreshIndicator(
      onRefresh: controller.actualiser,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          110,
        ),
        children: [
          _EnteteContrat(
            contrat: contrat,
          ),
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              leading: const CircleAvatar(
                child: Icon(
                  Icons.folder_outlined,
                ),
              ),
              title: const Text(
                'Documents du contrat',
              ),
              subtitle: Text(
                peutGerer
                    ? 'Consulter, ajouter et télécharger les documents'
                    : 'Consulter et télécharger les documents',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: controller.isSubmitting
                  ? null
                  : () {
                      _ouvrirDocuments(
                        context,
                        contrat,
                        peutUploader:
                            peutGerer,
                      );
                    },
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            titre: 'Informations générales',
            enfants: [
              _InformationRow(
                icon:
                    Icons.business_outlined,
                label: 'Entreprise',
                valeur: contrat.entreprise,
              ),
              _InformationRow(
                icon: Icons
                    .account_balance_outlined,
                label: 'Administration',
                valeur:
                    contrat.administration,
              ),
              _InformationRow(
                icon:
                    Icons.campaign_outlined,
                label: 'Appel d’offres',
                valeur: contrat.appelOffre,
              ),
              _InformationRow(
                icon:
                    Icons.payments_outlined,
                label: 'Montant du contrat',
                valeur: _formatMontant(
                  contrat.montant,
                ),
              ),
              _InformationRow(
                icon:
                    Icons.description_outlined,
                label: 'Objet',
                valeur: contrat.objet,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            titre: 'Calendrier du contrat',
            enfants: [
              _InformationRow(
                icon:
                    Icons.draw_outlined,
                label: 'Date de signature',
                valeur: _formatDate(
                  contrat.dateSignature,
                ),
              ),
              _InformationRow(
                icon:
                    Icons.play_circle_outline,
                label: 'Date de début',
                valeur: _formatDate(
                  contrat.dateDebut,
                ),
              ),
              _InformationRow(
                icon: Icons
                    .event_available_outlined,
                label: 'Date de fin',
                valeur: _formatDate(
                  contrat.dateFin,
                ),
              ),
              _InformationRow(
                icon:
                    Icons.add_circle_outline,
                label: 'Date de création',
                valeur: _formatDateHeure(
                  contrat.dateCreation,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _AvancementCard(
            avancement: contrat.avancement,
            peutGerer: peutGerer,
            isSubmitting:
                controller.isSubmitting,
            onModifier: () {
              _modifierAvancement(
                context,
                contrat.avancement,
              );
            },
          ),
          const SizedBox(height: 12),
          _JalonsCard(
            jalons: controller.jalons,
            peutGerer: peutGerer,
            isSubmitting:
                controller.isSubmitting,
            onAjouter: () {
              _ajouterJalon(context);
            },
            onModifier: (jalon) {
              _modifierJalon(context, jalon);
            },
            onSupprimer: (jalon) {
              _supprimerJalon(context, jalon);
            },
          ),
          const SizedBox(height: 12),
          _ResumePaiements(
            montantContrat:
                contrat.montant,
            montantProgramme:
                controller
                    .montantTotalPaiements,
            montantPaye:
                controller.montantTotalPaye,
            montantEnAttente:
                controller
                    .montantTotalEnAttente,
          ),
          const SizedBox(height: 12),
          _PaiementsCard(
            paiements: controller.paiements,
            peutGerer: peutGerer,
            isSubmitting:
                controller.isSubmitting,
            onAjouter: () {
              _ajouterPaiement(context);
            },
            onValider: (paiement) {
              _validerPaiement(
                context,
                paiement,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EnteteContrat extends StatelessWidget {
  const _EnteteContrat({
    required this.contrat,
  });

  final Contrat contrat;

  @override
  Widget build(BuildContext context) {
    final reference =
        contrat.reference.trim().isEmpty
            ? 'Contrat sans référence'
            : contrat.reference;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatutChip(
                  statut: contrat.statut,
                  styles: contratStatutStyles,
                ),
                if (contrat.archive)
                  _ArchiveChip(
                    dateArchivage:
                        contrat.dateArchivage,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              reference,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    fontWeight:
                        FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _valeurOuDefaut(
                contrat.objet,
                defaut:
                    'Objet du contrat non renseigné',
              ),
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumePaiements extends StatelessWidget {
  const _ResumePaiements({
    required this.montantContrat,
    required this.montantProgramme,
    required this.montantPaye,
    required this.montantEnAttente,
  });

  final double? montantContrat;
  final double montantProgramme;
  final double montantPaye;
  final double montantEnAttente;

  @override
  Widget build(BuildContext context) {
    final montantRestant =
        (montantContrat ?? 0) -
            montantPaye;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Text(
              'Situation financière',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight:
                        FontWeight.bold,
                  ),
            ),
            const Divider(height: 28),
            _ResumeMontantRow(
              label: 'Montant du contrat',
              valeur: _formatMontant(
                montantContrat,
              ),
              icon: Icons
                  .account_balance_wallet_outlined,
            ),
            const SizedBox(height: 14),
            _ResumeMontantRow(
              label:
                  'Paiements programmés',
              valeur: _formatMontant(
                montantProgramme,
              ),
              icon: Icons
                  .calendar_month_outlined,
            ),
            const SizedBox(height: 14),
            _ResumeMontantRow(
              label: 'Montant payé',
              valeur: _formatMontant(
                montantPaye,
              ),
              icon:
                  Icons.check_circle_outline,
            ),
            const SizedBox(height: 14),
            _ResumeMontantRow(
              label: 'En attente',
              valeur: _formatMontant(
                montantEnAttente,
              ),
              icon: Icons
                  .hourglass_empty_outlined,
            ),
            const SizedBox(height: 14),
            _ResumeMontantRow(
              label: 'Reste à payer',
              valeur: _formatMontant(
                montantRestant < 0
                    ? 0
                    : montantRestant,
              ),
              icon: Icons
                  .pending_actions_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumeMontantRow
    extends StatelessWidget {
  const _ResumeMontantRow({
    required this.label,
    required this.valeur,
    required this.icon,
  });

  final String label;
  final String valeur;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context)
              .colorScheme
              .primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label),
        ),
        Text(
          valeur,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _PaiementsCard extends StatelessWidget {
  const _PaiementsCard({
    required this.paiements,
    required this.peutGerer,
    required this.isSubmitting,
    required this.onAjouter,
    required this.onValider,
  });

  final List<Paiement> paiements;
  final bool peutGerer;
  final bool isSubmitting;
  final VoidCallback onAjouter;
  final ValueChanged<Paiement> onValider;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Paiements',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                  ),
                ),
                Chip(
                  avatar: const Icon(
                    Icons.payments_outlined,
                    size: 18,
                  ),
                  label: Text(
                    paiements.length
                        .toString(),
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            if (paiements.isEmpty) ...[
              const Padding(
                padding:
                    EdgeInsets.symmetric(
                  vertical: 16,
                ),
                child: Text(
                  'Aucun paiement n’est encore enregistré.',
                  textAlign:
                      TextAlign.center,
                ),
              ),
              if (peutGerer)
                Center(
                  child: OutlinedButton.icon(
                    onPressed: isSubmitting
                        ? null
                        : onAjouter,
                    icon: const Icon(
                      Icons.add_card_outlined,
                    ),
                    label: const Text(
                      'Ajouter un paiement',
                    ),
                  ),
                ),
            ] else
              ...paiements.map(
                (paiement) {
                  return _PaiementTile(
                    paiement: paiement,
                    peutValider:
                        peutGerer &&
                            paiement
                                .estEnAttente,
                    isSubmitting:
                        isSubmitting,
                    onValider: () {
                      onValider(paiement);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _PaiementTile extends StatelessWidget {
  const _PaiementTile({
    required this.paiement,
    required this.peutValider,
    required this.isSubmitting,
    required this.onValider,
  });

  final Paiement paiement;
  final bool peutValider;
  final bool isSubmitting;
  final VoidCallback onValider;

  @override
  Widget build(BuildContext context) {
    final reference =
        paiement.reference?.trim() ?? '';

    final description =
        paiement.description?.trim() ?? '';

    final titre = reference.isNotEmpty
        ? reference
        : description.isNotEmpty
            ? description
            : 'Paiement';

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant,
          ),
          borderRadius:
              BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    child: Icon(
                      paiement.estPaye
                          ? Icons
                              .check_circle_outline
                          : Icons
                              .hourglass_empty_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          titre,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          _formatMontant(
                            paiement.montant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatutChip(
                    statut: paiement.statut,
                    styles: paiementStatutStyles,
                  ),
                ],
              ),
              if (description.isNotEmpty &&
                  description != titre) ...[
                const SizedBox(height: 12),
                Text(description),
              ],
              const SizedBox(height: 12),
              _PetitDetail(
                icon:
                    Icons.event_outlined,
                texte:
                    'Échéance : ${_formatDate(paiement.dateEcheance)}',
              ),
              if (paiement.datePaiement !=
                  null) ...[
                const SizedBox(height: 6),
                _PetitDetail(
                  icon: Icons
                      .event_available_outlined,
                  texte:
                      'Payé le : ${_formatDateHeure(paiement.datePaiement)}',
                ),
              ],
              if (peutValider) ...[
                const SizedBox(height: 14),
                Align(
                  alignment:
                      Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed:
                        isSubmitting
                            ? null
                            : onValider,
                    icon: const Icon(
                      Icons
                          .check_circle_outline,
                    ),
                    label: const Text(
                      'Valider le paiement',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PetitDetail extends StatelessWidget {
  const _PetitDetail({
    required this.icon,
    required this.texte,
  });

  final IconData icon;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context)
              .colorScheme
              .onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texte,
            style: Theme.of(context)
                .textTheme
                .bodySmall,
          ),
        ),
      ],
    );
  }
}

class _ModificationContratDialog
    extends StatefulWidget {
  const _ModificationContratDialog({
    required this.contrat,
  });

  final Contrat contrat;

  @override
  State<_ModificationContratDialog>
      createState() =>
          _ModificationContratDialogState();
}

class _ModificationContratDialogState
    extends State<_ModificationContratDialog> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  late String _statut;
  DateTime? _dateSignature;
  DateTime? _dateDebut;
  DateTime? _dateFin;

  @override
  void initState() {
    super.initState();

    const statuts = {
      'en_cours',
      'suspendu',
      'termine',
      'resilie',
    };

    final statutActuel =
        widget.contrat.statut
            .trim()
            .toLowerCase();

    _statut = statuts.contains(
      statutActuel,
    )
        ? statutActuel
        : 'en_cours';

    _dateSignature =
        widget.contrat.dateSignature;

    _dateDebut =
        widget.contrat.dateDebut;

    _dateFin =
        widget.contrat.dateFin;
  }

  Future<void> _selectionnerDate(
    _TypeDateContrat type,
  ) async {
    DateTime? dateActuelle;

    switch (type) {
      case _TypeDateContrat.signature:
        dateActuelle = _dateSignature;
        break;

      case _TypeDateContrat.debut:
        dateActuelle = _dateDebut;
        break;

      case _TypeDateContrat.fin:
        dateActuelle = _dateFin;
        break;
    }

    final dateSelectionnee =
        await showDatePicker(
      context: context,
      initialDate:
          dateActuelle ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Sélectionner une date',
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
    );

    if (dateSelectionnee == null) {
      return;
    }

    setState(() {
      switch (type) {
        case _TypeDateContrat.signature:
          _dateSignature =
              dateSelectionnee;
          break;

        case _TypeDateContrat.debut:
          _dateDebut =
              dateSelectionnee;
          break;

        case _TypeDateContrat.fin:
          _dateFin =
              dateSelectionnee;
          break;
      }
    });
  }

  void _confirmer() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_dateDebut != null &&
        _dateFin != null &&
        _dateFin!.isBefore(_dateDebut!)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'La date de fin ne peut pas être antérieure à la date de début.',
            ),
          ),
        );

      return;
    }

    Navigator.of(context).pop(
      _ModificationContratData(
        statut: _statut,
        dateSignature: _dateSignature,
        dateDebut: _dateDebut,
        dateFin: _dateFin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Modifier le contrat',
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _statut,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Statut du contrat',
                    prefixIcon: Icon(
                      Icons.info_outline,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'en_cours',
                      child: Text(
                        'En cours',
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'suspendu',
                      child: Text(
                        'Suspendu',
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'termine',
                      child: Text(
                        'Terminé',
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'resilie',
                      child: Text(
                        'Résilié',
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _statut = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _DateSelectionTile(
                  label:
                      'Date de signature',
                  date: _dateSignature,
                  icon: Icons.draw_outlined,
                  onTap: () {
                    _selectionnerDate(
                      _TypeDateContrat
                          .signature,
                    );
                  },
                ),
                const SizedBox(height: 12),
                _DateSelectionTile(
                  label: 'Date de début',
                  date: _dateDebut,
                  icon: Icons
                      .play_circle_outline,
                  onTap: () {
                    _selectionnerDate(
                      _TypeDateContrat.debut,
                    );
                  },
                ),
                const SizedBox(height: 12),
                _DateSelectionTile(
                  label: 'Date de fin',
                  date: _dateFin,
                  icon: Icons
                      .event_available_outlined,
                  onTap: () {
                    _selectionnerDate(
                      _TypeDateContrat.fin,
                    );
                  },
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
          child: const Text(
            'Annuler',
          ),
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
}

class _AjoutPaiementDialog
    extends StatefulWidget {
  const _AjoutPaiementDialog();

  @override
  State<_AjoutPaiementDialog> createState() =>
      _AjoutPaiementDialogState();
}

class _AjoutPaiementDialogState
    extends State<_AjoutPaiementDialog> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController
      _referenceController =
      TextEditingController();

  final TextEditingController
      _descriptionController =
      TextEditingController();

  final TextEditingController
      _montantController =
      TextEditingController();

  DateTime? _dateEcheance;

  @override
  void dispose() {
    _referenceController.dispose();
    _descriptionController.dispose();
    _montantController.dispose();
    super.dispose();
  }

  Future<void> _selectionnerDate() async {
    final dateSelectionnee =
        await showDatePicker(
      context: context,
      initialDate:
          _dateEcheance ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText:
          'Date d’échéance du paiement',
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
    );

    if (dateSelectionnee == null) {
      return;
    }

    setState(() {
      _dateEcheance =
          dateSelectionnee;
    });
  }

  void _confirmer() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final montant = _parseMontant(
      _montantController.text,
    );

    if (montant == null || montant <= 0) {
      return;
    }

    Navigator.of(context).pop(
      _AjoutPaiementData(
        montant: montant,
        reference:
            _referenceController
                .text
                .trim(),
        description:
            _descriptionController
                .text
                .trim(),
        dateEcheance: _dateEcheance,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Ajouter un paiement',
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode:
                AutovalidateMode
                    .onUserInteraction,
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                TextFormField(
                  controller:
                      _referenceController,
                  textCapitalization:
                      TextCapitalization
                          .characters,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Référence du paiement',
                    hintText:
                        'Exemple : PAY-2026-001',
                    prefixIcon: Icon(
                      Icons.tag_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller:
                      _montantController,
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      const InputDecoration(
                    labelText: 'Montant *',
                    suffixText: 'Ar',
                    prefixIcon: Icon(
                      Icons.payments_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value
                            .trim()
                            .isEmpty) {
                      return 'Le montant est obligatoire.';
                    }

                    final montant =
                        _parseMontant(value);

                    if (montant == null) {
                      return 'Saisissez un montant valide.';
                    }

                    if (montant <= 0) {
                      return 'Le montant doit être supérieur à zéro.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller:
                      _descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  textCapitalization:
                      TextCapitalization
                          .sentences,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Description',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(
                      Icons
                          .description_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                _DateSelectionTile(
                  label:
                      'Date d’échéance',
                  date: _dateEcheance,
                  icon:
                      Icons.event_outlined,
                  onTap: _selectionnerDate,
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
          child: const Text(
            'Annuler',
          ),
        ),
        FilledButton.icon(
          onPressed: _confirmer,
          icon: const Icon(
            Icons.add_card_outlined,
          ),
          label: const Text(
            'Ajouter',
          ),
        ),
      ],
    );
  }

  static double? _parseMontant(
    String valeur,
  ) {
    final texte = valeur
        .replaceAll(',', '.')
        .replaceAll(
          RegExp(r'\s+'),
          '',
        )
        .trim();

    if (texte.isEmpty) {
      return null;
    }

    return double.tryParse(texte);
  }
}

class _AvancementCard extends StatelessWidget {
  const _AvancementCard({
    required this.avancement,
    required this.peutGerer,
    required this.isSubmitting,
    required this.onModifier,
  });

  final int avancement;
  final bool peutGerer;
  final bool isSubmitting;
  final VoidCallback onModifier;

  @override
  Widget build(BuildContext context) {
    final avancementBorne =
        avancement.clamp(0, 100);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Avancement physique',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                  ),
                ),
                if (peutGerer)
                  IconButton(
                    tooltip:
                        'Modifier l’avancement',
                    onPressed: isSubmitting
                        ? null
                        : onModifier,
                    icon: const Icon(
                      Icons.edit_outlined,
                    ),
                  ),
              ],
            ),
            const Divider(height: 28),
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: avancementBorne / 100,
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$avancementBorne %',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(
                    fontWeight:
                        FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvancementDialog
    extends StatefulWidget {
  const _AvancementDialog({
    required this.avancementInitial,
  });

  final int avancementInitial;

  @override
  State<_AvancementDialog> createState() =>
      _AvancementDialogState();
}

class _AvancementDialogState
    extends State<_AvancementDialog> {
  late double _valeur;

  @override
  void initState() {
    super.initState();

    _valeur = widget.avancementInitial
        .clamp(0, 100)
        .toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final valeurArrondie = _valeur.round();

    return AlertDialog(
      title: const Text(
        'Modifier l’avancement',
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$valeurArrondie %',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    fontWeight:
                        FontWeight.bold,
                  ),
            ),
            Slider(
              value: _valeur,
              min: 0,
              max: 100,
              divisions: 100,
              label: '$valeurArrondie %',
              onChanged: (value) {
                setState(() {
                  _valeur = value;
                });
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
          onPressed: () {
            Navigator.of(context).pop(
              valeurArrondie,
            );
          },
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
}

class _JalonsCard extends StatelessWidget {
  const _JalonsCard({
    required this.jalons,
    required this.peutGerer,
    required this.isSubmitting,
    required this.onAjouter,
    required this.onModifier,
    required this.onSupprimer,
  });

  final List<JalonContrat> jalons;
  final bool peutGerer;
  final bool isSubmitting;
  final VoidCallback onAjouter;
  final ValueChanged<JalonContrat> onModifier;
  final ValueChanged<JalonContrat>
      onSupprimer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Jalons d’exécution',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                  ),
                ),
                Chip(
                  avatar: const Icon(
                    Icons.flag_outlined,
                    size: 18,
                  ),
                  label: Text(
                    jalons.length.toString(),
                  ),
                ),
                if (peutGerer)
                  IconButton(
                    tooltip:
                        'Ajouter un jalon',
                    onPressed: isSubmitting
                        ? null
                        : onAjouter,
                    icon: const Icon(
                      Icons
                          .add_circle_outline,
                    ),
                  ),
              ],
            ),
            const Divider(height: 28),
            if (jalons.isEmpty)
              const Padding(
                padding:
                    EdgeInsets.symmetric(
                  vertical: 16,
                ),
                child: Text(
                  'Aucun jalon n’est encore défini pour ce contrat.',
                  textAlign:
                      TextAlign.center,
                ),
              )
            else
              ...jalons.map(
                (jalon) {
                  return _JalonTile(
                    jalon: jalon,
                    peutGerer: peutGerer,
                    isSubmitting:
                        isSubmitting,
                    onModifier: () {
                      onModifier(jalon);
                    },
                    onSupprimer: () {
                      onSupprimer(jalon);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _JalonTile extends StatelessWidget {
  const _JalonTile({
    required this.jalon,
    required this.peutGerer,
    required this.isSubmitting,
    required this.onModifier,
    required this.onSupprimer,
  });

  final JalonContrat jalon;
  final bool peutGerer;
  final bool isSubmitting;
  final VoidCallback onModifier;
  final VoidCallback onSupprimer;

  @override
  Widget build(BuildContext context) {
    final description =
        jalon.description?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant,
          ),
          borderRadius:
              BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      jalon.titre.isEmpty
                          ? 'Jalon'
                          : jalon.titre,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                    ),
                  ),
                  StatutChip(
                    statut: jalon.statut,
                    styles: jalonStatutStyles,
                  ),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(description),
              ],
              const SizedBox(height: 10),
              _PetitDetail(
                icon:
                    Icons.event_outlined,
                texte:
                    'Prévu : ${_formatDate(jalon.datePrevue)}',
              ),
              if (jalon.dateReelle !=
                  null) ...[
                const SizedBox(height: 6),
                _PetitDetail(
                  icon: Icons
                      .event_available_outlined,
                  texte:
                      'Réalisé : ${_formatDate(jalon.dateReelle)}',
                ),
              ],
              if (peutGerer) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed:
                          isSubmitting
                              ? null
                              : onModifier,
                      icon: const Icon(
                        Icons.edit_outlined,
                      ),
                      label: const Text(
                        'Modifier',
                      ),
                    ),
                    TextButton.icon(
                      onPressed:
                          isSubmitting
                              ? null
                              : onSupprimer,
                      icon: const Icon(
                        Icons
                            .delete_outline,
                      ),
                      label: const Text(
                        'Supprimer',
                      ),
                      style: TextButton
                          .styleFrom(
                        foregroundColor:
                            Theme.of(context)
                                .colorScheme
                                .error,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _JalonDialog extends StatefulWidget {
  const _JalonDialog({
    this.jalon,
  });

  final JalonContrat? jalon;

  @override
  State<_JalonDialog> createState() =>
      _JalonDialogState();
}

class _JalonDialogState
    extends State<_JalonDialog> {
  static const _statuts = {
    'a_venir': 'À venir',
    'en_cours': 'En cours',
    'termine': 'Terminé',
    'retard': 'En retard',
  };

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController
      _titreController =
      TextEditingController();

  final TextEditingController
      _descriptionController =
      TextEditingController();

  final TextEditingController
      _ordreController =
      TextEditingController();

  DateTime? _datePrevue;
  DateTime? _dateReelle;
  late String _statut;

  bool get _estModification =>
      widget.jalon != null;

  @override
  void initState() {
    super.initState();

    final jalon = widget.jalon;

    if (jalon != null) {
      _titreController.text = jalon.titre;
      _descriptionController.text =
          jalon.description ?? '';
      _ordreController.text =
          jalon.ordre.toString();
      _datePrevue = jalon.datePrevue;
      _dateReelle = jalon.dateReelle;

      final statutActuel =
          jalon.statut.trim().toLowerCase();

      _statut = _statuts.containsKey(
        statutActuel,
      )
          ? statutActuel
          : 'a_venir';
    } else {
      _statut = 'a_venir';
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _ordreController.dispose();
    super.dispose();
  }

  Future<void> _selectionnerDate({
    required bool reelle,
  }) async {
    final dateActuelle =
        reelle ? _dateReelle : _datePrevue;

    final dateSelectionnee =
        await showDatePicker(
      context: context,
      initialDate:
          dateActuelle ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: reelle
          ? 'Date réelle du jalon'
          : 'Date prévue du jalon',
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
    );

    if (dateSelectionnee == null) {
      return;
    }

    setState(() {
      if (reelle) {
        _dateReelle = dateSelectionnee;
      } else {
        _datePrevue = dateSelectionnee;
      }
    });
  }

  void _confirmer() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final ordreTexte =
        _ordreController.text.trim();

    Navigator.of(context).pop(
      _JalonFormData(
        titre: _titreController.text.trim(),
        description: _descriptionController
            .text
            .trim(),
        ordre: ordreTexte.isEmpty
            ? null
            : int.tryParse(ordreTexte),
        datePrevue: _datePrevue,
        dateReelle: _dateReelle,
        statut: _estModification
            ? _statut
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _estModification
            ? 'Modifier le jalon'
            : 'Ajouter un jalon',
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode:
                AutovalidateMode
                    .onUserInteraction,
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                TextFormField(
                  controller:
                      _titreController,
                  textCapitalization:
                      TextCapitalization
                          .sentences,
                  decoration:
                      const InputDecoration(
                    labelText: 'Titre *',
                    prefixIcon: Icon(
                      Icons.flag_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value
                            .trim()
                            .isEmpty) {
                      return 'Le titre est obligatoire.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller:
                      _descriptionController,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization:
                      TextCapitalization
                          .sentences,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Description',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(
                      Icons
                          .description_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                ),
                if (!_estModification) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller:
                        _ordreController,
                    keyboardType:
                        TextInputType.number,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Ordre (optionnel)',
                      prefixIcon: Icon(
                        Icons.sort_outlined,
                      ),
                      border:
                          OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _DateSelectionTile(
                  label: 'Date prévue',
                  date: _datePrevue,
                  icon:
                      Icons.event_outlined,
                  onTap: () {
                    _selectionnerDate(
                      reelle: false,
                    );
                  },
                ),
                if (_estModification) ...[
                  const SizedBox(height: 12),
                  _DateSelectionTile(
                    label: 'Date réelle',
                    date: _dateReelle,
                    icon: Icons
                        .event_available_outlined,
                    onTap: () {
                      _selectionnerDate(
                        reelle: true,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<
                      String>(
                    initialValue: _statut,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Statut du jalon',
                      prefixIcon: Icon(
                        Icons.info_outline,
                      ),
                      border:
                          OutlineInputBorder(),
                    ),
                    items: _statuts.entries
                        .map(
                          (entree) =>
                              DropdownMenuItem(
                            value: entree.key,
                            child: Text(
                              entree.value,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _statut = value;
                      });
                    },
                  ),
                ],
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
          child: const Text(
            'Annuler',
          ),
        ),
        FilledButton.icon(
          onPressed: _confirmer,
          icon: Icon(
            _estModification
                ? Icons.save_outlined
                : Icons.add_outlined,
          ),
          label: Text(
            _estModification
                ? 'Enregistrer'
                : 'Ajouter',
          ),
        ),
      ],
    );
  }
}

class _DateSelectionTile
    extends StatelessWidget {
  const _DateSelectionTile({
    required this.label,
    required this.date,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: const Icon(
            Icons
                .calendar_month_outlined,
          ),
          border:
              const OutlineInputBorder(),
        ),
        child: Text(
          _formatDate(date),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.titre,
    required this.enfants,
  });

  final String titre;
  final List<Widget> enfants;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Text(
              titre,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight:
                        FontWeight.bold,
                  ),
            ),
            const Divider(height: 28),
            ...enfants,
          ],
        ),
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.icon,
    required this.label,
    required this.valeur,
  });

  final IconData icon;
  final String label;
  final String? valeur;

  @override
  Widget build(BuildContext context) {
    final texte =
        valeur?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22,
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
                const SizedBox(height: 3),
                Text(
                  texte.isEmpty
                      ? 'Non renseigné'
                      : texte,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchiveChip extends StatelessWidget {
  const _ArchiveChip({
    required this.dateArchivage,
  });

  final DateTime? dateArchivage;

  @override
  Widget build(BuildContext context) {
    final couleurs =
        Theme.of(context).colorScheme;

    return Chip(
      backgroundColor:
          couleurs.errorContainer,
      side: BorderSide.none,
      avatar: Icon(
        Icons.archive_outlined,
        size: 18,
        color: couleurs.onErrorContainer,
      ),
      label: Text(
        dateArchivage == null
            ? 'Archivé'
            : 'Archivé le ${_formatDate(dateArchivage)}',
        style: TextStyle(
          color:
              couleurs.onErrorContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ErreurContrat extends StatelessWidget {
  const _ErreurContrat({
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
            CircleIcon.erreur(context),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
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

class _ModificationContratData {
  const _ModificationContratData({
    required this.statut,
    required this.dateSignature,
    required this.dateDebut,
    required this.dateFin,
  });

  final String statut;
  final DateTime? dateSignature;
  final DateTime? dateDebut;
  final DateTime? dateFin;
}

class _AjoutPaiementData {
  const _AjoutPaiementData({
    required this.montant,
    required this.reference,
    required this.description,
    required this.dateEcheance,
  });

  final double montant;
  final String reference;
  final String description;
  final DateTime? dateEcheance;
}

class _JalonFormData {
  const _JalonFormData({
    required this.titre,
    required this.description,
    required this.ordre,
    required this.datePrevue,
    required this.dateReelle,
    required this.statut,
  });

  final String titre;
  final String description;
  final int? ordre;
  final DateTime? datePrevue;
  final DateTime? dateReelle;
  final String? statut;
}

enum _TypeDateContrat {
  signature,
  debut,
  fin,
}

enum _ActionContrat {
  archiver,
  desarchiver,
}

String _formatMontant(
  double? montant,
) {
  if (montant == null) {
    return 'Non renseigné';
  }

  return '${NumberFormat.decimalPattern('fr_FR').format(montant)} Ar';
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

  return '$jour/$mois/${dateLocale.year}';
}

String _formatDateHeure(
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

  return '$jour/$mois/${dateLocale.year} à $heure:$minute';
}

String _valeurOuDefaut(
  String? valeur, {
  required String defaut,
}) {
  final texte =
      valeur?.trim() ?? '';

  return texte.isEmpty
      ? defaut
      : texte;
}