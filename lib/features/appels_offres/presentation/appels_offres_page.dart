import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/appel_offre.dart';
import '../data/appel_offre_repository.dart';
import 'appel_offre_details_page.dart';
import 'appel_offre_form_page.dart';

class AppelsOffresPage extends StatefulWidget {
  const AppelsOffresPage({super.key});

  @override
  State<AppelsOffresPage> createState() =>
      _AppelsOffresPageState();
}

class _AppelsOffresPageState extends State<AppelsOffresPage> {
  final AppelOffreRepository _repository =
      AppelOffreRepository();

  final TextEditingController _rechercheController =
      TextEditingController();

  List<AppelOffre> _appelsOffres = [];

  bool _isLoading = true;
  String? _errorMessage;
  Timer? _rechercheTimer;

  @override
  void initState() {
    super.initState();
    _chargerAppelsOffres();
  }

  @override
  void dispose() {
    _rechercheTimer?.cancel();
    _rechercheController.dispose();
    super.dispose();
  }

  Future<void> _chargerAppelsOffres({
    bool afficherChargement = true,
  }) async {
    if (afficherChargement && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final recherche =
          _rechercheController.text.trim();

      final appelsOffres = await _repository.lister(
        recherche: recherche.isEmpty ? null : recherche,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _appelsOffres = appelsOffres;
        _errorMessage = null;
      });
    } on AppelOffreException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            'Impossible de charger les appels d’offres.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _rechercher(String valeur) {
    _rechercheTimer?.cancel();

    _rechercheTimer = Timer(
      const Duration(milliseconds: 500),
      () {
        _chargerAppelsOffres();
      },
    );
  }

  void _effacerRecherche() {
    _rechercheController.clear();
    _rechercheTimer?.cancel();
    _chargerAppelsOffres();
  }

  Future<void> _actualiser() async {
    await _chargerAppelsOffres(
      afficherChargement: false,
    );
  }

  Future<void> _creerAppelOffre() async {
    final resultat =
        await Navigator.of(context)
            .push<AppelOffreActionResult>(
      MaterialPageRoute<AppelOffreActionResult>(
        builder: (_) => const AppelOffreFormPage(),
      ),
    );

    if (!mounted || resultat == null) {
      return;
    }

    await _chargerAppelsOffres();
  }

  Future<void> _ouvrirDetails(
    AppelOffre appelOffre,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AppelOffreDetailsPage(
          appelOffre: appelOffre,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _actualiser();
  }

  @override
  Widget build(BuildContext context) {
    final role =
        context.watch<AuthController>().utilisateur?.role;

    final peutGerer =
        role == 'admin_national' ||
        role == 'administration';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Appels d’offres',
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed:
                _isLoading ? null : _actualiser,
            icon: const Icon(
              Icons.refresh_outlined,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildRecherche(),
            Expanded(
              child: _buildContenu(),
            ),
          ],
        ),
      ),
      floatingActionButton: peutGerer
          ? FloatingActionButton.extended(
              onPressed: _isLoading
                  ? null
                  : _creerAppelOffre,
              icon: const Icon(Icons.add),
              label: const Text(
                'Nouvel appel',
              ),
            )
          : null,
    );
  }

  Widget _buildRecherche() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        8,
      ),
      child: TextField(
        controller: _rechercheController,
        textInputAction: TextInputAction.search,
        onChanged: _rechercher,
        onSubmitted: (_) {
          _rechercheTimer?.cancel();
          _chargerAppelsOffres();
        },
        decoration: InputDecoration(
          labelText:
              'Rechercher un appel d’offres',
          hintText:
              'Référence, titre ou description',
          prefixIcon: const Icon(
            Icons.search,
          ),
          suffixIcon:
              _rechercheController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip:
                          'Effacer la recherche',
                      onPressed:
                          _effacerRecherche,
                      icon: const Icon(
                        Icons.clear,
                      ),
                    ),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildContenu() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildErreur();
    }

    if (_appelsOffres.isEmpty) {
      return _buildListeVide();
    }

    return RefreshIndicator(
      onRefresh: _actualiser,
      child: ListView.separated(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          100,
        ),
        itemCount: _appelsOffres.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final appelOffre =
              _appelsOffres[index];

          return _AppelOffreCard(
            appelOffre: appelOffre,
            onTap: () =>
                _ouvrirDetails(appelOffre),
          );
        },
      ),
    );
  }

  Widget _buildErreur() {
    return RefreshIndicator(
      onRefresh: _actualiser,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context)
                .colorScheme
                .error,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ??
                'Une erreur est survenue.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge,
          ),
          const SizedBox(height: 24),
          Center(
            child: FilledButton.icon(
              onPressed:
                  _chargerAppelsOffres,
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text(
                'Réessayer',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListeVide() {
    final recherche =
        _rechercheController.text.trim();

    return RefreshIndicator(
      onRefresh: _actualiser,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Icon(
            Icons.assignment_outlined,
            size: 72,
          ),
          const SizedBox(height: 16),
          Text(
            recherche.isEmpty
                ? 'Aucun appel d’offres disponible.'
                : 'Aucun résultat pour cette recherche.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium,
          ),
          if (recherche.isNotEmpty) ...[
            const SizedBox(height: 20),
            Center(
              child: OutlinedButton.icon(
                onPressed:
                    _effacerRecherche,
                icon: const Icon(
                  Icons.clear,
                ),
                label: const Text(
                  'Effacer la recherche',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AppelOffreCard extends StatelessWidget {
  const _AppelOffreCard({
    required this.appelOffre,
    required this.onTap,
  });

  final AppelOffre appelOffre;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final administration =
        _administrationLibelle(appelOffre);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                  Expanded(
                    child: Text(
                      appelOffre.reference,
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(
                            fontWeight:
                                FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StatutBadge(
                    statut:
                        appelOffre.statut,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                appelOffre.titre,
                maxLines: 3,
                overflow:
                    TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w600,
                    ),
              ),
              if (appelOffre.description !=
                      null &&
                  appelOffre.description!
                      .trim()
                      .isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  appelOffre.description!,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium,
                ),
              ],
              const Divider(height: 28),
              _InformationLigne(
                icon: Icons.work_outline,
                texte: _libelleTypeMarche(
                  appelOffre.typeMarche,
                ),
              ),
              const SizedBox(height: 8),
              _InformationLigne(
                icon: Icons
                    .account_balance_outlined,
                texte: administration,
              ),
              if (appelOffre
                      .dateLimiteSoumission !=
                  null) ...[
                const SizedBox(height: 8),
                _InformationLigne(
                  icon:
                      Icons.event_outlined,
                  texte:
                      'Date limite : ${_formatDateHeure(appelOffre.dateLimiteSoumission!)}',
                ),
              ],
              if (appelOffre.montantEstime !=
                  null) ...[
                const SizedBox(height: 8),
                _InformationLigne(
                  icon:
                      Icons.payments_outlined,
                  texte:
                      'Montant estimé : ${_formatMontant(appelOffre.montantEstime!)}',
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment:
                    Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(
                    Icons.visibility_outlined,
                  ),
                  label: const Text(
                    'Voir les détails',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _administrationLibelle(
    AppelOffre appelOffre,
  ) {
    final nom =
        appelOffre.administrationNom?.trim() ?? '';

    final sigle =
        appelOffre.administrationSigle
                ?.trim() ??
            '';

    if (nom.isEmpty) {
      return 'Administration non renseignée';
    }

    if (sigle.isEmpty) {
      return nom;
    }

    return '$nom ($sigle)';
  }
}

class _InformationLigne extends StatelessWidget {
  const _InformationLigne({
    required this.icon,
    required this.texte,
  });

  final IconData icon;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context)
              .colorScheme
              .primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            texte,
            style: Theme.of(context)
                .textTheme
                .bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _StatutBadge extends StatelessWidget {
  const _StatutBadge({
    required this.statut,
  });

  final String statut;

  @override
  Widget build(BuildContext context) {
    final couleurs =
        _couleursStatut(context, statut);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: couleurs.background,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        _libelleStatut(statut),
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(
              color: couleurs.foreground,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  static _CouleursStatut _couleursStatut(
    BuildContext context,
    String statut,
  ) {
    final couleurs =
        Theme.of(context).colorScheme;

    switch (statut.toLowerCase()) {
      case 'publie':
        return _CouleursStatut(
          background:
              couleurs.primaryContainer,
          foreground:
              couleurs.onPrimaryContainer,
        );

      case 'brouillon':
        return _CouleursStatut(
          background:
              couleurs.secondaryContainer,
          foreground:
              couleurs.onSecondaryContainer,
        );

      case 'en_evaluation':
        return _CouleursStatut(
          background:
              couleurs.tertiaryContainer,
          foreground:
              couleurs.onTertiaryContainer,
        );

      case 'attribue':
        return _CouleursStatut(
          background:
              couleurs.primaryContainer,
          foreground:
              couleurs.onPrimaryContainer,
        );

      case 'infructueux':
      case 'annule':
        return _CouleursStatut(
          background:
              couleurs.errorContainer,
          foreground:
              couleurs.onErrorContainer,
        );

      default:
        return _CouleursStatut(
          background:
              couleurs.surfaceContainerHighest,
          foreground:
              couleurs.onSurfaceVariant,
        );
    }
  }
}

class _CouleursStatut {
  const _CouleursStatut({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}

String _libelleTypeMarche(String type) {
  switch (type.toLowerCase()) {
    case 'travaux':
      return 'Travaux';

    case 'fournitures':
      return 'Fournitures';

    case 'services':
      return 'Services';

    case 'equipements':
      return 'Équipements';

    case 'developpement':
      return 'Développement';

    case 'infrastructure':
      return 'Infrastructure';

    default:
      return type;
  }
}

String _libelleStatut(String statut) {
  switch (statut.toLowerCase()) {
    case 'brouillon':
      return 'Brouillon';

    case 'publie':
      return 'Publié';

    case 'cloture':
      return 'Clôturé';

    case 'en_evaluation':
      return 'En évaluation';

    case 'attribue':
      return 'Attribué';

    case 'infructueux':
      return 'Infructueux';

    case 'annule':
      return 'Annulé';

    default:
      return statut;
  }
}

String _formatDateHeure(DateTime date) {
  final dateLocale = date.toLocal();

  final jour =
      dateLocale.day.toString().padLeft(2, '0');

  final mois =
      dateLocale.month.toString().padLeft(2, '0');

  final heure =
      dateLocale.hour.toString().padLeft(2, '0');

  final minute =
      dateLocale.minute.toString().padLeft(2, '0');

  return '$jour/$mois/${dateLocale.year} à $heure:$minute';
}

String _formatMontant(double montant) {
  final valeur = montant.round().toString();
  final morceaux = <String>[];

  for (
    int position = valeur.length;
    position > 0;
    position -= 3
  ) {
    final debut =
        position - 3 < 0 ? 0 : position - 3;

    morceaux.insert(
      0,
      valeur.substring(debut, position),
    );
  }

  return '${morceaux.join(' ')} Ar';
}