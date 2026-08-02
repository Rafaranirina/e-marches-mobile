import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/categorie_marche.dart';
import 'categorie_controller.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CategorieController()
        ..charger(),
      child: const _CategoriesView(),
    );
  }
}

class _CategoriesView extends StatefulWidget {
  const _CategoriesView();

  @override
  State<_CategoriesView> createState() =>
      _CategoriesViewState();
}

class _CategoriesViewState
    extends State<_CategoriesView> {
  final TextEditingController
      _rechercheController =
      TextEditingController();

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  Future<void> _creerCategorie() async {
    final controller =
        context.read<CategorieController>();

    final donnees =
        await showDialog<DonneesCategorie>(
      context: context,
      builder: (_) => _CategorieFormDialog(
        categoriesPrincipales:
            controller.categoriesPrincipales,
      ),
    );

    if (donnees == null || !mounted) {
      return;
    }

    final resultat =
        await controller.creerCategorie(
      donnees,
    );

    if (!mounted) {
      return;
    }

    _afficherMessage(
      resultat?.message ??
          controller.errorMessage ??
          'Impossible de créer la catégorie.',
      estErreur: resultat == null,
    );
  }

  void _reinitialiserFiltres() {
    _rechercheController.clear();

    context
        .read<CategorieController>()
        .reinitialiserFiltres();
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
        context.watch<CategorieController>();

    final utilisateur = context
        .watch<AuthController>()
        .utilisateur;

    final estAdministrateurNational =
        utilisateur?.role
                .trim()
                .toLowerCase() ==
            'admin_national';

    final categories =
        controller.categoriesFiltrees;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Catégories',
        ),
        actions: [
          if (estAdministrateurNational)
            IconButton(
              tooltip:
                  'Créer une catégorie',
              onPressed: controller.isBusy
                  ? null
                  : _creerCategorie,
              icon: const Icon(
                Icons.create_new_folder_outlined,
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
        bottom: controller.isRefreshing ||
                controller.isCreating
            ? const PreferredSize(
                preferredSize:
                    Size.fromHeight(3),
                child:
                    LinearProgressIndicator(),
              )
            : null,
      ),
      floatingActionButton:
          estAdministrateurNational &&
                  !controller.isLoading
              ? FloatingActionButton.extended(
                  onPressed:
                      controller.isBusy
                          ? null
                          : _creerCategorie,
                  icon: const Icon(
                    Icons
                        .create_new_folder_outlined,
                  ),
                  label: const Text(
                    'Nouvelle catégorie',
                  ),
                )
              : null,
      body: SafeArea(
        child: Column(
          children: [
            _EnteteCategories(
              nombreTotal:
                  controller.nombreTotal,
              nombrePrincipales:
                  controller
                      .nombrePrincipales,
              nombreSousCategories:
                  controller
                      .nombreSousCategories,
            ),
            _FiltresCategories(
              rechercheController:
                  _rechercheController,
              typeSelectionne:
                  controller.filtreType,
              onRecherche:
                  controller.rechercher,
              onType:
                  controller.filtrerParType,
              onReinitialiser:
                  _reinitialiserFiltres,
            ),
            Expanded(
              child: _buildContenu(
                controller,
                categories,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenu(
    CategorieController controller,
    List<CategorieMarche> categories,
  ) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (controller.hasError &&
        controller.categories.isEmpty) {
      return _ErreurCategories(
        message: controller.errorMessage ??
            'Impossible de charger les catégories.',
        onRetry: controller.charger,
      );
    }

    if (controller.categories.isEmpty) {
      return _CategoriesVides(
        filtreActif: false,
        onActualiser:
            controller.actualiser,
      );
    }

    if (categories.isEmpty) {
      return _CategoriesVides(
        filtreActif: true,
        onActualiser:
            controller.actualiser,
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
          110,
        ),
        itemCount: categories.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final categorie =
              categories[index];

          return _CategorieCard(
            categorie: categorie,
            nomCategorieParente:
                controller
                    .nomCategorieParId(
              categorie.categorieParentId,
            ),
          );
        },
      ),
    );
  }
}

class _EnteteCategories
    extends StatelessWidget {
  const _EnteteCategories({
    required this.nombreTotal,
    required this.nombrePrincipales,
    required this.nombreSousCategories,
  });

  final int nombreTotal;
  final int nombrePrincipales;
  final int nombreSousCategories;

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    child: Icon(
                      Icons.category_outlined,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      '$nombreTotal catégorie'
                      '${nombreTotal > 1 ? 's' : ''}',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontWeight:
                                FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CompteurChip(
                    icon:
                        Icons.folder_outlined,
                    label: 'Principales',
                    valeur:
                        nombrePrincipales,
                  ),
                  _CompteurChip(
                    icon:
                        Icons.subdirectory_arrow_right_outlined,
                    label:
                        'Sous-catégories',
                    valeur:
                        nombreSousCategories,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompteurChip extends StatelessWidget {
  const _CompteurChip({
    required this.icon,
    required this.label,
    required this.valeur,
  });

  final IconData icon;
  final String label;
  final int valeur;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        icon,
        size: 18,
      ),
      label: Text(
        '$label : $valeur',
      ),
    );
  }
}

class _FiltresCategories
    extends StatelessWidget {
  const _FiltresCategories({
    required this.rechercheController,
    required this.typeSelectionne,
    required this.onRecherche,
    required this.onType,
    required this.onReinitialiser,
  });

  final TextEditingController
      rechercheController;

  final String typeSelectionne;

  final ValueChanged<String> onRecherche;
  final ValueChanged<String> onType;
  final VoidCallback onReinitialiser;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        8,
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller:
                    rechercheController,
                onChanged: onRecherche,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Rechercher une catégorie',
                  hintText:
                      'Nom ou description',
                  prefixIcon: Icon(
                    Icons.search_outlined,
                  ),
                  border:
                      OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue:
                    typeSelectionne,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Type de catégorie',
                  prefixIcon: Icon(
                    Icons.filter_list_outlined,
                  ),
                  border:
                      OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'toutes',
                    child: Text(
                      'Toutes les catégories',
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'principales',
                    child: Text(
                      'Catégories principales',
                    ),
                  ),
                  DropdownMenuItem(
                    value:
                        'sous_categories',
                    child: Text(
                      'Sous-catégories',
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onType(value);
                  }
                },
              ),
              const SizedBox(height: 10),
              Align(
                alignment:
                    Alignment.centerRight,
                child: TextButton.icon(
                  onPressed:
                      onReinitialiser,
                  icon: const Icon(
                    Icons
                        .filter_alt_off_outlined,
                  ),
                  label: const Text(
                    'Réinitialiser les filtres',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorieCard extends StatelessWidget {
  const _CategorieCard({
    required this.categorie,
    required this.nomCategorieParente,
  });

  final CategorieMarche categorie;
  final String nomCategorieParente;

  @override
  Widget build(BuildContext context) {
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
                    categorie
                            .estCategoriePrincipale
                        ? Icons.folder_outlined
                        : Icons
                            .subdirectory_arrow_right_outlined,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        categorie.nom,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        categorie
                            .descriptionAffichee,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: Icon(
                    categorie
                            .estCategoriePrincipale
                        ? Icons
                            .account_tree_outlined
                        : Icons
                            .subdirectory_arrow_right_outlined,
                    size: 17,
                  ),
                  label: Text(
                    categorie
                            .estCategoriePrincipale
                        ? 'Catégorie principale'
                        : 'Sous-catégorie',
                  ),
                ),
              ],
            ),
            if (categorie
                .estSousCategorie) ...[
              const Divider(height: 28),
              _DetailCategorie(
                icon:
                    Icons.folder_copy_outlined,
                label:
                    'Catégorie parente',
                valeur:
                    nomCategorieParente,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailCategorie
    extends StatelessWidget {
  const _DetailCategorie({
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
          size: 19,
          color: Theme.of(context)
              .colorScheme
              .primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$label : $valeur',
          ),
        ),
      ],
    );
  }
}

class _CategorieFormDialog
    extends StatefulWidget {
  const _CategorieFormDialog({
    required this.categoriesPrincipales,
  });

  final List<CategorieMarche>
      categoriesPrincipales;

  @override
  State<_CategorieFormDialog>
      createState() =>
          _CategorieFormDialogState();
}

class _CategorieFormDialogState
    extends State<_CategorieFormDialog> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController
      _nomController =
      TextEditingController();

  final TextEditingController
      _descriptionController =
      TextEditingController();

  String? _categorieParentId;

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _confirmer() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      DonneesCategorie(
        nom: _nomController.text.trim(),
        description:
            _descriptionController
                .text
                .trim(),
        categorieParentId:
            _categorieParentId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesPrincipales =
        List<CategorieMarche>.from(
      widget.categoriesPrincipales,
    )..sort(
        (a, b) => a.nom
            .toLowerCase()
            .compareTo(
              b.nom.toLowerCase(),
            ),
      );

    return AlertDialog(
      title: const Text(
        'Créer une catégorie',
      ),
      content: SizedBox(
        width: 540,
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
                      _nomController,
                  textCapitalization:
                      TextCapitalization.words,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Nom de la catégorie *',
                    prefixIcon: Icon(
                      Icons.category_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Le nom est obligatoire.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller:
                      _descriptionController,
                  textCapitalization:
                      TextCapitalization.sentences,
                  maxLines: 4,
                  decoration:
                      const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(
                      Icons
                          .description_outlined,
                    ),
                    alignLabelWithHint: true,
                    border:
                        OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue:
                      _categorieParentId ??
                          '',
                  isExpanded: true,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Catégorie parente',
                    helperText:
                        'Laissez vide pour créer une catégorie principale.',
                    prefixIcon: Icon(
                      Icons
                          .account_tree_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text(
                        'Aucune — catégorie principale',
                      ),
                    ),
                    ...categoriesPrincipales.map(
                      (categorie) =>
                          DropdownMenuItem(
                        value: categorie.id,
                        child: Text(
                          categorie.nom,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      final id =
                          value?.trim() ?? '';

                      _categorieParentId =
                          id.isEmpty
                              ? null
                              : id;
                    });
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
            Icons
                .create_new_folder_outlined,
          ),
          label: const Text(
            'Créer',
          ),
        ),
      ],
    );
  }
}

class _ErreurCategories
    extends StatelessWidget {
  const _ErreurCategories({
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
              size: 66,
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

class _CategoriesVides
    extends StatelessWidget {
  const _CategoriesVides({
    required this.filtreActif,
    required this.onActualiser,
  });

  final bool filtreActif;
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
          const SizedBox(height: 80),
          Icon(
            filtreActif
                ? Icons
                    .search_off_outlined
                : Icons.category_outlined,
            size: 72,
          ),
          const SizedBox(height: 16),
          Text(
            filtreActif
                ? 'Aucune catégorie ne correspond aux filtres.'
                : 'Aucune catégorie disponible.',
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