import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../administrations/presentation/administrations_page.dart';
import '../../appels_offres/presentation/appels_offres_page.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../categories/presentation/categories_page.dart';
import '../../contrats/presentation/contrats_page.dart';
import '../../fournisseurs/presentation/fournisseurs_page.dart';
import '../../notifications/presentation/notifications_page.dart';
import '../../profil/presentation/profil_page.dart';
import '../../rapports/presentation/rapports_page.dart';
import '../../utilisateurs/presentation/utilisateurs_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final authController =
        context.watch<AuthController>();

    final utilisateur =
        authController.utilisateur;

    final role = utilisateur?.role
            .trim()
            .toLowerCase() ??
        '';

    final estAdministrateurNational =
        role == 'admin_national';

    final peutVoirFournisseurs =
        estAdministrateurNational ||
            role == 'administration' ||
            role == 'commission';

    final peutVoirContrats =
        estAdministrateurNational ||
            role == 'administration' ||
            role == 'commission';

    final peutVoirRapports =
        estAdministrateurNational ||
            role == 'administration';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tableau de bord',
        ),
        actions: [
          IconButton(
            tooltip: 'Mon profil',
            onPressed: utilisateur == null
                ? null
                : () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const ProfilPage(),
                      ),
                    );
                  },
            icon: const Icon(
              Icons.account_circle_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: utilisateur == null
                ? null
                : () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const NotificationsPage(),
                      ),
                    );
                  },
            icon: const Icon(
              Icons.notifications_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Déconnexion',
            onPressed: utilisateur == null
                ? null
                : () async {
                    await context
                        .read<AuthController>()
                        .logout();

                    if (!context.mounted) {
                      return;
                    }

                    Navigator.of(context).popUntil(
                      (route) => route.isFirst,
                    );
                  },
            icon: const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: utilisateur == null
            ? const Center(
                child: Text(
                  'Aucun utilisateur connecté.',
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  IconButton(
                    tooltip: 'Ouvrir mon profil',
                    onPressed: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const ProfilPage(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.account_circle,
                      size: 90,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    utilisateur.nomComplet
                            .trim()
                            .isEmpty
                        ? utilisateur.email
                        : utilisateur.nomComplet,
                    textAlign: TextAlign.center,
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
                    utilisateur.email,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rôle : ${_libelleRole(utilisateur.role)}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Modules',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),

                  _ModuleCard(
                    icon: Icons.person_outline,
                    titre: 'Mon profil',
                    description:
                        'Consulter les informations de votre compte',
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const ProfilPage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  _ModuleCard(
                    icon: Icons
                        .account_balance_outlined,
                    titre: 'Administrations',
                    description:
                        'Consulter les administrations enregistrées',
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const AdministrationsPage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  _ModuleCard(
                    icon: Icons.category_outlined,
                    titre: 'Catégories',
                    description:
                        'Consulter les catégories et sous-catégories de marchés',
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const CategoriesPage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  _ModuleCard(
                    icon: Icons.campaign_outlined,
                    titre: 'Appels d’offres',
                    description:
                        'Consulter et gérer les marchés publics',
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const AppelsOffresPage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  _ModuleCard(
                    icon: Icons
                        .notifications_outlined,
                    titre: 'Notifications',
                    description:
                        'Consulter les alertes et les informations liées à votre compte',
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const NotificationsPage(),
                        ),
                      );
                    },
                  ),

                  if (peutVoirFournisseurs) ...[
                    const SizedBox(height: 8),
                    _ModuleCard(
                      icon:
                          Icons.business_outlined,
                      titre: 'Fournisseurs',
                      description:
                          'Consulter les entreprises et prestataires',
                      onTap: () {
                        Navigator.of(context)
                            .push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const FournisseursPage(),
                          ),
                        );
                      },
                    ),
                  ],

                  if (peutVoirContrats) ...[
                    const SizedBox(height: 8),
                    _ModuleCard(
                      icon: Icons
                          .description_outlined,
                      titre: 'Contrats',
                      description:
                          'Suivre les marchés attribués, les contrats et les paiements',
                      onTap: () {
                        Navigator.of(context)
                            .push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const ContratsPage(),
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 8),

                  _ModuleCard(
                    icon: Icons
                        .assignment_turned_in_outlined,
                    titre: 'Soumissions',
                    description:
                        'Les soumissions sont accessibles depuis chaque appel d’offres',
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const AppelsOffresPage(),
                        ),
                      );
                    },
                  ),

                  if (peutVoirRapports) ...[
                    const SizedBox(height: 8),
                    _ModuleCard(
                      icon:
                          Icons.analytics_outlined,
                      titre:
                          'Rapports et statistiques',
                      description:
                          'Consulter les indicateurs, les répartitions et l’activité récente',
                      onTap: () {
                        Navigator.of(context)
                            .push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const RapportsPage(),
                          ),
                        );
                      },
                    ),
                  ],

                  if (estAdministrateurNational) ...[
                    const SizedBox(height: 8),
                    _ModuleCard(
                      icon: Icons
                          .manage_accounts_outlined,
                      titre:
                          'Gestion des utilisateurs',
                      description:
                          'Créer, modifier et administrer les comptes utilisateurs',
                      onTap: () {
                        Navigator.of(context)
                            .push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const UtilisateursPage(),
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }

  static String _libelleRole(
    String role,
  ) {
    switch (role.trim().toLowerCase()) {
      case 'admin_national':
        return 'Administrateur national';

      case 'administration':
        return 'Administration';

      case 'commission':
        return 'Commission';

      case 'fournisseur':
        return 'Fournisseur';

      default:
        final valeur = role
            .replaceAll('_', ' ')
            .trim();

        return valeur.isEmpty
            ? 'Non défini'
            : valeur;
    }
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.icon,
    required this.titre,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String titre;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          titre,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          description,
        ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: onTap,
      ),
    );
  }
}