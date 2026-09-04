import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/circle_icon.dart';
import '../../../shared/widgets/statut_chip.dart';
import '../../appels_offres/presentation/appel_offre_statut_styles.dart';
import '../data/ma_commission.dart';
import 'commissions_page.dart';
import 'mes_commissions_controller.dart';

/// Écran listant les commissions dont l'utilisateur connecté (rôle
/// `commission`) est membre, avec l'appel d'offres correspondant. Un tap sur
/// une commission ouvre [CommissionsPage] pour l'appel d'offres associé.
class MesCommissionsPage extends StatelessWidget {
  const MesCommissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          MesCommissionsController()..charger(),
      child: const _MesCommissionsView(),
    );
  }
}

class _MesCommissionsView extends StatelessWidget {
  const _MesCommissionsView();

  void _ouvrirCommission(
    BuildContext context,
    MaCommission commission,
  ) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CommissionsPage(
          appelOffreId: commission.appelOffreId,
          appelOffreTitre:
              commission.appelOffreTitre,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller =
        context.watch<MesCommissionsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes commissions'),
        actions: [
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
        bottom: controller.isRefreshing
            ? const PreferredSize(
                preferredSize:
                    Size.fromHeight(3),
                child:
                    LinearProgressIndicator(),
              )
            : null,
      ),
      body: SafeArea(
        child: _buildContenu(
          context,
          controller,
        ),
      ),
    );
  }

  Widget _buildContenu(
    BuildContext context,
    MesCommissionsController controller,
  ) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (controller.hasError &&
        controller.commissions.isEmpty) {
      return _ErreurMesCommissions(
        message: controller.errorMessage ??
            'Impossible de charger vos commissions.',
        onRetry: controller.charger,
      );
    }

    if (controller.commissions.isEmpty) {
      return _MesCommissionsVides(
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
          12,
          16,
          24,
        ),
        itemCount:
            controller.commissions.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final commission =
              controller.commissions[index];

          return _MaCommissionCard(
            commission: commission,
            onTap: () => _ouvrirCommission(
              context,
              commission,
            ),
          );
        },
      ),
    );
  }
}

class _MaCommissionCard extends StatelessWidget {
  const _MaCommissionCard({
    required this.commission,
    required this.onTap,
  });

  final MaCommission commission;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reference =
        commission.appelOffreReference.trim();

    final statut =
        commission.appelOffreStatut?.trim() ?? '';

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    child: Icon(
                      Icons.groups_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          commission
                              .commissionNom,
                          style: Theme.of(
                            context,
                          )
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        Text(
                          commission
                              .fonctionAffichee,
                          style: Theme.of(
                            context,
                          )
                              .textTheme
                              .bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      commission
                          .appelOffreTitre,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (reference.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.tag_outlined,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reference,
                        maxLines: 1,
                        overflow: TextOverflow
                            .ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
              if (statut.isNotEmpty) ...[
                const SizedBox(height: 12),
                Align(
                  alignment:
                      Alignment.centerLeft,
                  child: StatutChip(
                    statut: statut,
                    styles: appelOffreStatutStyles,
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

class _ErreurMesCommissions
    extends StatelessWidget {
  const _ErreurMesCommissions({
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
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MesCommissionsVides
    extends StatelessWidget {
  const _MesCommissionsVides({
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
          CircleIcon.neutre(context, icon: Icons.groups_outlined),
          const SizedBox(height: 20),
          Text(
            'Vous n’êtes membre d’aucune commission pour le moment.',
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

