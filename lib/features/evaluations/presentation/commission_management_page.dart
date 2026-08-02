import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/commission_option.dart';
import '../data/membre_commission_option.dart';
import 'commission_management_controller.dart';

class CommissionManagementPage
    extends StatelessWidget {
  const CommissionManagementPage({
    required this.appelOffreId,
    required this.appelOffreReference,
    super.key,
  });

  final String appelOffreId;
  final String appelOffreReference;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          CommissionManagementController(
        appelOffreId: appelOffreId,
      )..charger(),
      child: _CommissionManagementView(
        appelOffreReference:
            appelOffreReference,
      ),
    );
  }
}

class _CommissionManagementView
    extends StatelessWidget {
  const _CommissionManagementView({
    required this.appelOffreReference,
  });

  final String appelOffreReference;

  Future<void> _creerCommission(
    BuildContext context,
  ) async {
    final nom = await showDialog<String>(
      context: context,
      builder: (_) =>
          const _CreationCommissionDialog(),
    );

    if (nom == null ||
        nom.trim().isEmpty ||
        !context.mounted) {
      return;
    }

    final controller = context
        .read<CommissionManagementController>();

    final resultat =
        await controller.creerCommission(
      nom: nom,
    );

    if (!context.mounted) {
      return;
    }

    _afficherMessage(
      context,
      resultat?.message ??
          controller.errorMessage ??
          'Impossible de créer la commission.',
      estErreur: resultat == null,
    );
  }

  Future<void> _ajouterMembre(
    BuildContext context,
    CommissionOption commission,
  ) async {
    final controller = context
        .read<CommissionManagementController>();

    final membresDisponibles =
        controller.membresNonAjoutes(
      commission,
    );

    if (membresDisponibles.isEmpty) {
      _afficherMessage(
        context,
        'Aucun membre disponible ne peut être ajouté à cette commission.',
        estErreur: true,
      );
      return;
    }

    final donnees =
        await showDialog<_AjoutMembreData>(
      context: context,
      builder: (_) => _AjoutMembreDialog(
        commission: commission,
        membresDisponibles:
            membresDisponibles,
      ),
    );

    if (donnees == null ||
        !context.mounted) {
      return;
    }

    final resultat =
        await controller.ajouterMembre(
      commissionId: commission.id,
      utilisateurId:
          donnees.utilisateurId,
      fonction: donnees.fonction,
    );

    if (!context.mounted) {
      return;
    }

    _afficherMessage(
      context,
      resultat?.message ??
          controller.errorMessage ??
          'Impossible d’ajouter le membre.',
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
    final controller = context.watch<
        CommissionManagementController>();

    final reference =
        appelOffreReference.trim().isEmpty
            ? 'Appel d’offres'
            : appelOffreReference.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestion des commissions',
        ),
        actions: [
          IconButton(
            tooltip:
                'Créer une commission',
            onPressed:
                controller.isSubmitting
                    ? null
                    : () {
                        _creerCommission(
                          context,
                        );
                      },
            icon: const Icon(
              Icons.add_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Actualiser',
            onPressed:
                controller.isLoading ||
                        controller
                            .isSubmitting
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
          controller.isLoading
              ? null
              : FloatingActionButton.extended(
                  onPressed:
                      controller.isSubmitting
                          ? null
                          : () {
                              _creerCommission(
                                context,
                              );
                            },
                  icon: const Icon(
                    Icons.add_outlined,
                  ),
                  label: const Text(
                    'Nouvelle commission',
                  ),
                ),
      body: SafeArea(
        child: Column(
          children: [
            _EnteteCommissions(
              reference: reference,
              nombreCommissions:
                  controller
                      .nombreCommissions,
              nombreMembresDisponibles:
                  controller
                      .nombreMembresDisponibles,
            ),
            Expanded(
              child: _buildContenu(
                context,
                controller,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenu(
    BuildContext context,
    CommissionManagementController
        controller,
  ) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (controller.hasError &&
        controller.commissions.isEmpty) {
      return _ErreurCommissions(
        message: controller.errorMessage ??
            'Impossible de charger les commissions.',
        onRetry: controller.charger,
      );
    }

    if (controller.commissions.isEmpty) {
      return _ListeCommissionsVide(
        onCreer: () {
          _creerCommission(context);
        },
        onActualiser:
            controller.actualiser,
      );
    }

    final membresParId =
        <String, MembreCommissionOption>{
      for (final membre
          in controller.membresDisponibles)
        membre.id: membre,
    };

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
        itemCount:
            controller.commissions.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final commission =
              controller.commissions[index];

          return _CommissionCard(
            commission: commission,
            membresParId: membresParId,
            isSubmitting:
                controller.isSubmitting,
            onAjouterMembre: () {
              _ajouterMembre(
                context,
                commission,
              );
            },
          );
        },
      ),
    );
  }
}

class _EnteteCommissions
    extends StatelessWidget {
  const _EnteteCommissions({
    required this.reference,
    required this.nombreCommissions,
    required this.nombreMembresDisponibles,
  });

  final String reference;
  final int nombreCommissions;
  final int nombreMembresDisponibles;

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
          child: Row(
            children: [
              const CircleAvatar(
                radius: 26,
                child: Icon(
                  Icons.groups_outlined,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      reference,
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
                      '$nombreCommissions commission'
                      '${nombreCommissions > 1 ? 's' : ''}'
                      ' • '
                      '$nombreMembresDisponibles membre'
                      '${nombreMembresDisponibles > 1 ? 's' : ''}'
                      ' disponible'
                      '${nombreMembresDisponibles > 1 ? 's' : ''}',
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

class _CommissionCard extends StatelessWidget {
  const _CommissionCard({
    required this.commission,
    required this.membresParId,
    required this.isSubmitting,
    required this.onAjouterMembre,
  });

  final CommissionOption commission;
  final Map<String, MembreCommissionOption>
      membresParId;
  final bool isSubmitting;
  final VoidCallback onAjouterMembre;

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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  child: Icon(
                    Icons.groups_2_outlined,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        commission.nom,
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
                        _formatDate(
                          commission
                              .dateCreation,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    '${commission.membres.length} membre'
                    '${commission.membres.length > 1 ? 's' : ''}',
                  ),
                  avatar: const Icon(
                    Icons.person_outline,
                    size: 18,
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            Text(
              'Membres de la commission',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(
                    fontWeight:
                        FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            if (commission.membres.isEmpty)
              const Padding(
                padding:
                    EdgeInsets.symmetric(
                  vertical: 10,
                ),
                child: Text(
                  'Aucun membre n’a encore été ajouté.',
                ),
              )
            else
              ...commission.membres.map(
                (membre) {
                  final utilisateur =
                      membresParId[
                          membre
                              .utilisateurId];

                  final nom = utilisateur
                          ?.nomComplet ??
                      'Membre de la commission';

                  final email =
                      utilisateur?.email ?? '';

                  final fonction =
                      membre.fonction
                              ?.trim() ??
                          '';

                  return ListTile(
                    contentPadding:
                        EdgeInsets.zero,
                    leading:
                        const CircleAvatar(
                      child: Icon(
                        Icons.person_outline,
                      ),
                    ),
                    title: Text(nom),
                    subtitle: Text(
                      [
                        if (email.isNotEmpty)
                          email,
                        if (fonction.isNotEmpty)
                          fonction,
                      ].join(' • '),
                    ),
                  );
                },
              ),
            const Divider(height: 28),
            Align(
              alignment:
                  Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: isSubmitting
                    ? null
                    : onAjouterMembre,
                icon: const Icon(
                  Icons.person_add_outlined,
                ),
                label: const Text(
                  'Ajouter un membre',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(
    DateTime? date,
  ) {
    if (date == null) {
      return 'Date de création non renseignée';
    }

    return 'Créée le ${DateFormat(
      'dd/MM/yyyy à HH:mm',
      'fr_FR',
    ).format(date.toLocal())}';
  }
}

class _CreationCommissionDialog
    extends StatefulWidget {
  const _CreationCommissionDialog();

  @override
  State<_CreationCommissionDialog>
      createState() =>
          _CreationCommissionDialogState();
}

class _CreationCommissionDialogState
    extends State<_CreationCommissionDialog> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController
      _nomController =
      TextEditingController();

  @override
  void dispose() {
    _nomController.dispose();
    super.dispose();
  }

  void _confirmer() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      _nomController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Créer une commission',
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          autovalidateMode:
              AutovalidateMode
                  .onUserInteraction,
          child: TextFormField(
            controller: _nomController,
            autofocus: true,
            textCapitalization:
                TextCapitalization.words,
            decoration:
                const InputDecoration(
              labelText:
                  'Nom de la commission *',
              hintText:
                  'Exemple : Commission d’évaluation',
              prefixIcon: Icon(
                Icons.groups_outlined,
              ),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Le nom de la commission est obligatoire.';
              }

              if (value.trim().length < 3) {
                return 'Le nom doit contenir au moins 3 caractères.';
              }

              return null;
            },
            onFieldSubmitted: (_) {
              _confirmer();
            },
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
            Icons.add_outlined,
          ),
          label: const Text(
            'Créer',
          ),
        ),
      ],
    );
  }
}

class _AjoutMembreDialog
    extends StatefulWidget {
  const _AjoutMembreDialog({
    required this.commission,
    required this.membresDisponibles,
  });

  final CommissionOption commission;
  final List<MembreCommissionOption>
      membresDisponibles;

  @override
  State<_AjoutMembreDialog> createState() =>
      _AjoutMembreDialogState();
}

class _AjoutMembreDialogState
    extends State<_AjoutMembreDialog> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController
      _fonctionController =
      TextEditingController();

  String? _utilisateurId;

  @override
  void initState() {
    super.initState();

    if (widget.membresDisponibles.length ==
        1) {
      _utilisateurId =
          widget.membresDisponibles.first.id;
    }
  }

  @override
  void dispose() {
    _fonctionController.dispose();
    super.dispose();
  }

  void _confirmer() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final utilisateurId =
        _utilisateurId;

    if (utilisateurId == null ||
        utilisateurId.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      _AjoutMembreData(
        utilisateurId: utilisateurId,
        fonction:
            _fonctionController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Ajouter un membre',
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode:
                AutovalidateMode
                    .onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.commission.nom,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium,
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue:
                      _utilisateurId,
                  isExpanded: true,
                  decoration:
                      const InputDecoration(
                    labelText: 'Membre *',
                    prefixIcon: Icon(
                      Icons.person_outline,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                  items: widget
                      .membresDisponibles
                      .map(
                    (membre) {
                      return DropdownMenuItem<
                          String>(
                        value: membre.id,
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              membre.nomComplet,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                            ),
                            Text(
                              membre.email,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                            ),
                          ],
                        ),
                      );
                    },
                  ).toList(),
                  onChanged: (value) {
                    setState(() {
                      _utilisateurId =
                          value;
                    });
                  },
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return 'Sélectionnez un membre.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller:
                      _fonctionController,
                  textCapitalization:
                      TextCapitalization.words,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Fonction dans la commission',
                    hintText:
                        'Exemple : Président, rapporteur, membre',
                    prefixIcon: Icon(
                      Icons.badge_outlined,
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
            Icons.person_add_outlined,
          ),
          label: const Text(
            'Ajouter',
          ),
        ),
      ],
    );
  }
}

class _ErreurCommissions
    extends StatelessWidget {
  const _ErreurCommissions({
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

class _ListeCommissionsVide
    extends StatelessWidget {
  const _ListeCommissionsVide({
    required this.onCreer,
    required this.onActualiser,
  });

  final VoidCallback onCreer;
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
          const SizedBox(height: 70),
          const Icon(
            Icons.groups_outlined,
            size: 72,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune commission n’est encore associée à cet appel d’offres.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium,
          ),
          const SizedBox(height: 24),
          Center(
            child: FilledButton.icon(
              onPressed: onCreer,
              icon: const Icon(
                Icons.add_outlined,
              ),
              label: const Text(
                'Créer une commission',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AjoutMembreData {
  const _AjoutMembreData({
    required this.utilisateurId,
    required this.fonction,
  });

  final String utilisateurId;
  final String fonction;
}