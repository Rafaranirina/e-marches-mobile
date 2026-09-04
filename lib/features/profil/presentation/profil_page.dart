import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/circle_icon.dart';
import '../../../shared/widgets/statut_chip.dart';
import '../../utilisateurs/data/utilisateur_gestion.dart';
import '../../utilisateurs/presentation/utilisateur_statut_styles.dart';
import 'profil_controller.dart';

class ProfilPage extends StatelessWidget {
  const ProfilPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfilController()
        ..charger(),
      child: const _ProfilView(),
    );
  }
}

class _ProfilView extends StatelessWidget {
  const _ProfilView();

  @override
  Widget build(BuildContext context) {
    final controller =
        context.watch<ProfilController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mon profil',
        ),
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
    ProfilController controller,
  ) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (controller.hasError &&
        !controller.hasProfil) {
      return _ErreurProfil(
        message: controller.errorMessage ??
            'Impossible de charger votre profil.',
        onRetry: controller.charger,
      );
    }

    final profil = controller.profil;

    if (profil == null) {
      return _ProfilVide(
        onActualiser:
            controller.actualiser,
      );
    }

    return RefreshIndicator(
      onRefresh: controller.actualiser,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          32,
        ),
        children: [
          _EnteteProfil(
            profil: profil,
          ),
          const SizedBox(height: 16),
          _SectionProfil(
            titre:
                'Informations personnelles',
            icon: Icons.person_outline,
            enfants: [
              _LigneProfil(
                icon:
                    Icons.badge_outlined,
                label: 'Nom',
                valeur: profil.nom,
              ),
              _LigneProfil(
                icon:
                    Icons.badge_outlined,
                label: 'Prénom',
                valeur: profil.prenom,
              ),
              _LigneProfil(
                icon:
                    Icons.email_outlined,
                label:
                    'Adresse e-mail',
                valeur: profil.email,
              ),
              _LigneProfil(
                icon:
                    Icons.phone_outlined,
                label: 'Téléphone',
                valeur:
                    profil.telephone,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionProfil(
            titre:
                'Compte et autorisations',
            icon:
                Icons.manage_accounts_outlined,
            enfants: [
              _LigneProfil(
                icon:
                    Icons.security_outlined,
                label: 'Rôle',
                valeur:
                    profil.roleFormate,
              ),
              _LigneProfil(
                icon:
                    Icons.info_outline,
                label: 'Statut',
                valeur:
                    profil.statutFormate,
              ),
              _LigneProfil(
                icon: Icons
                    .verified_user_outlined,
                label:
                    'Double authentification',
                valeur:
                    profil.doubleAuthActive
                        ? 'Activée'
                        : 'Désactivée',
              ),
            ],
          ),
          if (profil.administrationId !=
                  null ||
              profil.entrepriseId !=
                  null) ...[
            const SizedBox(height: 16),
            _SectionProfil(
              titre:
                  'Rattachement',
              icon:
                  Icons.account_tree_outlined,
              enfants: [
                if (profil
                        .administrationId !=
                    null)
                  _LigneProfil(
                    icon: Icons
                        .account_balance_outlined,
                    label:
                        'Identifiant administration',
                    valeur: profil
                        .administrationId!,
                  ),
                if (profil.entrepriseId !=
                    null)
                  _LigneProfil(
                    icon:
                        Icons.business_outlined,
                    label:
                        'Identifiant entreprise',
                    valeur:
                        profil.entrepriseId!,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          _SectionProfil(
            titre: 'Activité du compte',
            icon:
                Icons.history_outlined,
            enfants: [
              _LigneProfil(
                icon:
                    Icons.login_outlined,
                label:
                    'Dernière connexion',
                valeur: _formatDateHeure(
                  profil
                      .derniereConnexion,
                ),
              ),
              _LigneProfil(
                icon:
                    Icons.event_outlined,
                label:
                    'Date de création',
                valeur: _formatDateHeure(
                  profil.dateCreation,
                ),
              ),
              _LigneProfil(
                icon:
                    Icons.update_outlined,
                label:
                    'Dernière modification',
                valeur: _formatDateHeure(
                  profil.dateMaj,
                ),
              ),
            ],
          ),
          if (controller.hasError) ...[
            const SizedBox(height: 16),
            _AvertissementProfil(
              message:
                  controller.errorMessage!,
            ),
          ],
        ],
      ),
    );
  }
}

class _EnteteProfil extends StatelessWidget {
  const _EnteteProfil({
    required this.profil,
  });

  final UtilisateurGestion profil;

  @override
  Widget build(BuildContext context) {
    final nomComplet =
        profil.nomComplet.trim();
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              child: Text(
                _initiales(profil),
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(
                      fontWeight:
                          FontWeight.bold,
                      color: scheme.onPrimaryContainer,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              nomComplet.isEmpty
                  ? profil.email
                  : nomComplet,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    fontWeight:
                        FontWeight.bold,
                    color: scheme.onSurface,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              profil.email,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment:
                  WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(
                    Icons.badge_outlined,
                    size: 18,
                  ),
                  label: Text(
                    profil.roleFormate,
                  ),
                ),
                StatutChip(
                  statut: profil.statut,
                  styles: utilisateurStatutStyles,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _initiales(
    UtilisateurGestion profil,
  ) {
    final prenom =
        profil.prenom.trim();

    final nom = profil.nom.trim();

    final premiere = prenom.isNotEmpty
        ? prenom[0]
        : '';

    final seconde =
        nom.isNotEmpty ? nom[0] : '';

    final initiales =
        '$premiere$seconde'
            .toUpperCase();

    return initiales.isEmpty
        ? '?'
        : initiales;
  }
}

class _SectionProfil extends StatelessWidget {
  const _SectionProfil({
    required this.titre,
    required this.icon,
    required this.enfants,
  });

  final String titre;
  final IconData icon;
  final List<Widget> enfants;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: scheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    titre,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            for (var index = 0;
                index < enfants.length;
                index++) ...[
              enfants[index],
              if (index <
                  enfants.length - 1)
                const Divider(
                  height: 24,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LigneProfil extends StatelessWidget {
  const _LigneProfil({
    required this.icon,
    required this.label,
    required this.valeur,
  });

  final IconData icon;
  final String label;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final valeurAffichee =
        valeur.trim().isEmpty
            ? 'Non renseigné'
            : valeur.trim();

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: scheme.primary,
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
                    .bodySmall
                    ?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 3),
              SelectableText(
                valeurAffichee,
                style: TextStyle(
                  fontWeight:
                      FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvertissementProfil
    extends StatelessWidget {
  const _AvertissementProfil({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final couleurs =
        Theme.of(context).colorScheme;

    return Card(
      color: couleurs.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_outlined,
              color:
                  couleurs.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: couleurs
                      .onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErreurProfil extends StatelessWidget {
  const _ErreurProfil({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            CircleIcon.erreur(
              context,
              icon: Icons.person_off_outlined,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign:
                  TextAlign.center,
              style: TextStyle(color: scheme.onSurface),
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

class _ProfilVide extends StatelessWidget {
  const _ProfilVide({
    required this.onActualiser,
  });

  final Future<void> Function()
      onActualiser;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onActualiser,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          CircleIcon.neutre(
            context,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune information de profil disponible.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface,
                ),
          ),
        ],
      ),
    );
  }
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

  return '$jour/$mois/${dateLocale.year} '
      'à $heure:$minute';
}