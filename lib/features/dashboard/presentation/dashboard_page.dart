import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/hero_header.dart';
import '../../../shared/widgets/official_seal.dart';
import '../../../shared/widgets/procurement_logo.dart';
import '../../administrations/presentation/administrations_page.dart';
import '../../appels_offres/presentation/appels_offres_page.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../categories/presentation/categories_page.dart';
import '../../commissions/presentation/mes_commissions_page.dart';
import '../../contrats/presentation/contrats_page.dart';
import '../../fournisseurs/presentation/fournisseurs_page.dart';
import '../../notifications/presentation/notification_controller.dart';
import '../../notifications/presentation/notifications_page.dart';
import '../../parametres/presentation/parametres_page.dart';
import '../../profil/presentation/profil_page.dart';
import '../../rapports/presentation/rapports_page.dart';
import '../../soumissions/presentation/mes_soumissions_page.dart';
import '../../utilisateurs/presentation/utilisateurs_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<NotificationController>(
      create: (_) => NotificationController()..charger(),
      child: const _DashboardView(),
    );
  }
}

class _ModuleDef {
  const _ModuleDef({
    required this.icon,
    required this.titre,
    required this.description,
    required this.onTap,
    this.badgeCount,
  });

  final IconData icon;
  final String titre;
  final String description;
  final VoidCallback onTap;
  final int? badgeCount;
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final notificationController = context.watch<NotificationController>();
    final scheme = Theme.of(context).colorScheme;

    final utilisateur = authController.utilisateur;

    final role = utilisateur?.role.trim().toLowerCase() ?? '';

    final estAdministrateurNational = role == 'admin_national';
    final estFournisseur = role == 'fournisseur';
    final estCommission = role == 'commission';

    final peutVoirFournisseurs = estAdministrateurNational ||
        role == 'administration' ||
        role == 'commission';

    final peutVoirContrats = estAdministrateurNational ||
        role == 'administration' ||
        role == 'commission';

    final peutVoirRapports =
        estAdministrateurNational || role == 'administration';

    final nombreNotificationsNonLues = notificationController.nombreNonLues;

    if (utilisateur == null) {
      return const Scaffold(
        body: Center(
          child: Text('Aucun utilisateur connecté.'),
        ),
      );
    }

    final modules = <_ModuleDef>[
      _ModuleDef(
        icon: Icons.person_outline,
        titre: 'Mon profil',
        description: 'Vos informations de compte',
        onTap: () => _ouvrir(context, const ProfilPage()),
      ),
      _ModuleDef(
        icon: Icons.account_balance_outlined,
        titre: 'Administrations',
        description: 'Entités publiques enregistrées',
        onTap: () => _ouvrir(context, const AdministrationsPage()),
      ),
      _ModuleDef(
        icon: Icons.category_outlined,
        titre: 'Catégories',
        description: 'Familles de marchés',
        onTap: () => _ouvrir(context, const CategoriesPage()),
      ),
      _ModuleDef(
        icon: Icons.campaign_outlined,
        titre: 'Appels d’offres',
        description: 'Publication et suivi des marchés',
        onTap: () => _ouvrir(context, const AppelsOffresPage()),
      ),
      _ModuleDef(
        icon: Icons.notifications_outlined,
        titre: 'Notifications',
        description: 'Alertes liées à votre compte',
        badgeCount: nombreNotificationsNonLues,
        onTap: () => _ouvrir(context, const NotificationsPage()).then((_) {
          if (context.mounted) {
            context.read<NotificationController>().actualiser();
          }
        }),
      ),
      if (estCommission)
        _ModuleDef(
          icon: Icons.groups_outlined,
          titre: 'Mes commissions',
          description: 'Commissions d’évaluation assignées',
          onTap: () => _ouvrir(context, const MesCommissionsPage()),
        ),
      if (peutVoirFournisseurs)
        _ModuleDef(
          icon: Icons.business_outlined,
          titre: 'Fournisseurs',
          description: 'Entreprises et prestataires',
          onTap: () => _ouvrir(context, const FournisseursPage()),
        ),
      if (peutVoirContrats)
        _ModuleDef(
          icon: Icons.description_outlined,
          titre: 'Contrats',
          description: 'Exécution, jalons et paiements',
          onTap: () => _ouvrir(context, const ContratsPage()),
        ),
      _ModuleDef(
        icon: Icons.assignment_turned_in_outlined,
        titre: estFournisseur ? 'Mes soumissions' : 'Soumissions',
        description: estFournisseur
            ? 'Déposer et suivre vos offres'
            : 'Depuis chaque appel d’offres',
        onTap: () => _ouvrir(
          context,
          estFournisseur ? const MesSoumissionsPage() : const AppelsOffresPage(),
        ),
      ),
      if (peutVoirRapports)
        _ModuleDef(
          icon: Icons.analytics_outlined,
          titre: 'Rapports',
          description: 'Statistiques et transparence',
          onTap: () => _ouvrir(context, const RapportsPage()),
        ),
      if (estAdministrateurNational)
        _ModuleDef(
          icon: Icons.manage_accounts_outlined,
          titre: 'Utilisateurs',
          description: 'Comptes et rôles',
          onTap: () => _ouvrir(context, const UtilisateursPage()),
        ),
      _ModuleDef(
        icon: Icons.settings_outlined,
        titre: 'Paramètres',
        description: 'Profil, photo, double authentification',
        onTap: () => _ouvrir(context, const ParametresPage()),
      ),
    ];

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => context.read<NotificationController>().actualiser(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: HeroHeader(
                  color: scheme.primary,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const ProcurementLogo(
                            iconSize: 34,
                            wordmarkFontSize: 15,
                            showCaption: false,
                            inverse: true,
                          ),
                          const Spacer(),
                          _ActionIcon(
                            icon: Icons.notifications_outlined,
                            badgeCount: nombreNotificationsNonLues,
                            onPressed: () =>
                                _ouvrir(context, const NotificationsPage())
                                    .then((_) {
                              if (context.mounted) {
                                context
                                    .read<NotificationController>()
                                    .actualiser();
                              }
                            }),
                          ),
                          _ActionIcon(
                            icon: Icons.logout,
                            onPressed: () async {
                              await context.read<AuthController>().logout();

                              if (!context.mounted) return;

                              Navigator.of(context)
                                  .popUntil((route) => route.isFirst);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _ouvrir(context, const ProfilPage()),
                            child: OfficialSeal(
                              diametre: 64,
                              couleurAnneau: scheme.secondary,
                              couleurFond:
                                  scheme.onPrimary.withValues(alpha: 0.10),
                              couleurMonogramme: scheme.onPrimary,
                              monogramme: _initiales(utilisateur.nomComplet),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  utilisateur.nomComplet.trim().isEmpty
                                      ? utilisateur.email
                                      : utilisateur.nomComplet,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(color: scheme.onPrimary),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: scheme.secondary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _libelleRole(utilisateur.role),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: scheme.onSecondary,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.4,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    'Modules',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.98,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _ModuleTile(
                    module: modules[index],
                    accent: _accentPour(index, scheme),
                  ),
                  childCount: modules.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<T?> _ouvrir<T>(BuildContext context, Widget page) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(builder: (_) => page),
    );
  }

  static Color _accentPour(int index, ColorScheme scheme) {
    switch (index % 3) {
      case 0:
        return scheme.primary;
      case 1:
        return scheme.secondary;
      default:
        return scheme.tertiary;
    }
  }

  static String _initiales(String nomComplet) {
    final morceaux = nomComplet
        .trim()
        .split(RegExp(r'\s+'))
        .where((element) => element.isNotEmpty)
        .toList();

    if (morceaux.isEmpty) {
      return '?';
    }

    if (morceaux.length == 1) {
      return morceaux.first.substring(0, 1).toUpperCase();
    }

    return (morceaux.first.substring(0, 1) + morceaux.last.substring(0, 1))
        .toUpperCase();
  }

  static String _libelleRole(String role) {
    switch (role.trim().toLowerCase()) {
      case 'admin_national':
        return 'ADMINISTRATEUR NATIONAL';

      case 'administration':
        return 'ADMINISTRATION';

      case 'commission':
        return 'COMMISSION';

      case 'fournisseur':
        return 'FOURNISSEUR';

      default:
        final valeur = role.replaceAll('_', ' ').trim().toUpperCase();

        return valeur.isEmpty ? 'NON DÉFINI' : valeur;
    }
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.onPressed,
    this.badgeCount,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final compte = badgeCount ?? 0;

    return IconButton(
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: compte > 0,
        label: Text(compte.toString()),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.module,
    required this.accent,
  });

  final _ModuleDef module;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final compte = module.badgeCount ?? 0;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: module.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(module.icon, color: accent, size: 22),
                  ),
                  if (compte > 0)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Badge(label: Text(compte.toString())),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                module.titre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 3),
              Text(
                module.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
