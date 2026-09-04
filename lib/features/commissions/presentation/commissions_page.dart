import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../utilisateurs/data/utilisateur_gestion.dart';
import '../../../shared/models/commission.dart';
import '../../../shared/widgets/circle_icon.dart';
import 'commission_controller.dart';

class CommissionsPage extends StatelessWidget {
  const CommissionsPage({
    required this.appelOffreId,
    this.appelOffreTitre,
    super.key,
  });

  final String appelOffreId;
  final String? appelOffreTitre;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CommissionController(
        appelOffreId: appelOffreId,
      )..charger(),
      child: _CommissionsView(
        appelOffreTitre: appelOffreTitre,
      ),
    );
  }
}

class _CommissionsView extends StatefulWidget {
  const _CommissionsView({
    required this.appelOffreTitre,
  });

  final String? appelOffreTitre;

  @override
  State<_CommissionsView> createState() =>
      _CommissionsViewState();
}

class _CommissionsViewState
    extends State<_CommissionsView> {
  bool get _peutGerer {
    final role = context
            .read<AuthController>()
            .utilisateur
            ?.role
            .trim()
            .toLowerCase() ??
        '';

    return role == 'admin_national' ||
        role == 'administration';
  }

  Future<void> _creerCommission() async {
    final controller =
        context.read<CommissionController>();

    final nom = await showDialog<String>(
      context: context,
      builder: (_) =>
          const _CreerCommissionDialog(),
    );

    if (nom == null || !mounted) {
      return;
    }

    final resultat =
        await controller.creerCommission(nom);

    if (!mounted) {
      return;
    }

    _afficherMessage(
      resultat?.message ??
          controller.errorMessage ??
          'Impossible de créer la commission.',
      estErreur: resultat == null,
    );
  }

  Future<void> _ajouterMembre(
    Commission commission,
  ) async {
    final controller =
        context.read<CommissionController>();

    final membresDisponibles =
        controller.membresNonAjoutes(
      commission.id,
    );

    if (controller.isLoadingMembers) {
      _afficherMessage(
        'Chargement des membres en cours.',
      );
      return;
    }

    if (controller.hasMembersError) {
      _afficherMessage(
        controller.membersErrorMessage ??
            'Impossible de charger les membres.',
        estErreur: true,
      );
      return;
    }

    if (membresDisponibles.isEmpty) {
      _afficherMessage(
        'Aucun membre disponible pour cette commission.',
      );
      return;
    }

    final donnees =
        await showDialog<_DonneesAjoutMembre>(
      context: context,
      builder: (_) => _AjouterMembreDialog(
        membres: membresDisponibles,
      ),
    );

    if (donnees == null || !mounted) {
      return;
    }

    final resultat =
        await controller.ajouterMembre(
      commissionId: commission.id,
      utilisateurId:
          donnees.utilisateurId,
      fonction: donnees.fonction,
    );

    if (!mounted) {
      return;
    }

    _afficherMessage(
      resultat?.message ??
          controller.errorMessage ??
          'Impossible d’ajouter le membre.',
      estErreur: resultat == null,
    );
  }

  Future<void> _retirerMembre(
    Commission commission,
    MembreCommission membre,
  ) async {
    final controller =
        context.read<CommissionController>();

    final nomMembre = controller.nomMembreParId(
      membre.utilisateurId,
    );

    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Retirer ce membre ?',
        ),
        content: Text(
          'Voulez-vous vraiment retirer $nomMembre de cette commission ?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Annuler'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            icon: const Icon(
              Icons.person_remove_outlined,
            ),
            label: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirme != true || !mounted) {
      return;
    }

    final resultat =
        await controller.retirerMembre(
      commissionId: commission.id,
      utilisateurId: membre.utilisateurId,
    );

    if (!mounted) {
      return;
    }

    _afficherMessage(
      resultat?.message ??
          controller.errorMessage ??
          'Impossible de retirer le membre.',
      estErreur: resultat == null,
    );
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
        context.watch<CommissionController>();

    final titreAppelOffre =
        widget.appelOffreTitre?.trim() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commissions'),
        actions: [
          if (_peutGerer)
            IconButton(
              tooltip:
                  'Créer une commission',
              onPressed: controller.isBusy
                  ? null
                  : _creerCommission,
              icon: const Icon(
                Icons.group_add_outlined,
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
                controller.isCreating ||
                controller.isAddingMember
            ? const PreferredSize(
                preferredSize:
                    Size.fromHeight(3),
                child:
                    LinearProgressIndicator(),
              )
            : null,
      ),
      floatingActionButton:
          _peutGerer &&
                  !controller.isLoading
              ? FloatingActionButton.extended(
                  onPressed:
                      controller.isBusy
                          ? null
                          : _creerCommission,
                  icon: const Icon(
                    Icons.group_add_outlined,
                  ),
                  label: const Text(
                    'Nouvelle commission',
                  ),
                )
              : null,
      body: SafeArea(
        child: Column(
          children: [
            _EnteteCommissions(
              titreAppelOffre:
                  titreAppelOffre,
              nombreCommissions:
                  controller.nombreCommissions,
              nombreMembres:
                  controller.nombreMembres,
            ),
            if (controller
                .hasMembersError)
              _AlerteMembres(
                message: controller
                        .membersErrorMessage ??
                    'Impossible de charger les membres.',
                onActualiser: controller
                    .actualiserMembres,
              ),
            Expanded(
              child: _buildContenu(
                controller,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenu(
    CommissionController controller,
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
      return _CommissionsVides(
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
        itemCount:
            controller.commissions.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final commission =
              controller.commissions[index];

          return _CommissionCard(
            commission: commission,
            peutGerer: _peutGerer,
            ajoutEnCours: controller
                .operationMembreEnCours(
              commission.id,
            ),
            nomMembreParId:
                controller.nomMembreParId,
            onAjouterMembre: () =>
                _ajouterMembre(commission),
            retraitMembreEnCours:
                (utilisateurId) =>
                    controller.retraitMembreEnCours(
              commission.id,
              utilisateurId,
            ),
            onRetirerMembre: (membre) =>
                _retirerMembre(
              commission,
              membre,
            ),
          );
        },
      ),
    );
  }
}

class _EnteteCommissions
    extends StatelessWidget {
  const _EnteteCommissions({
    required this.titreAppelOffre,
    required this.nombreCommissions,
    required this.nombreMembres,
  });

  final String titreAppelOffre;
  final int nombreCommissions;
  final int nombreMembres;

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
                          '$nombreCommissions commission'
                          '${nombreCommissions > 1 ? 's' : ''}',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                        ),
                        if (titreAppelOffre
                            .isNotEmpty) ...[
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            titreAppelOffre,
                            maxLines: 2,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(
                      Icons.groups_outlined,
                      size: 18,
                    ),
                    label: Text(
                      'Commissions : $nombreCommissions',
                    ),
                  ),
                  Chip(
                    avatar: const Icon(
                      Icons.person_outline,
                      size: 18,
                    ),
                    label: Text(
                      'Membres : $nombreMembres',
                    ),
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

class _AlerteMembres
    extends StatelessWidget {
  const _AlerteMembres({
    required this.message,
    required this.onActualiser,
  });

  final String message;
  final Future<void> Function()
      onActualiser;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        8,
      ),
      child: Material(
        color: Theme.of(context)
            .colorScheme
            .errorContainer,
        borderRadius:
            BorderRadius.circular(12),
        child: ListTile(
          leading: Icon(
            Icons.warning_amber_outlined,
            color: Theme.of(context)
                .colorScheme
                .onErrorContainer,
          ),
          title: Text(
            message,
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onErrorContainer,
            ),
          ),
          trailing: IconButton(
            tooltip:
                'Recharger les membres',
            onPressed: onActualiser,
            icon: const Icon(
              Icons.refresh_outlined,
            ),
          ),
        ),
      ),
    );
  }
}

class _CommissionCard
    extends StatelessWidget {
  const _CommissionCard({
    required this.commission,
    required this.peutGerer,
    required this.ajoutEnCours,
    required this.nomMembreParId,
    required this.onAjouterMembre,
    required this.retraitMembreEnCours,
    required this.onRetirerMembre,
  });

  final Commission commission;
  final bool peutGerer;
  final bool ajoutEnCours;

  final String Function(String)
      nomMembreParId;

  final VoidCallback onAjouterMembre;

  final bool Function(String)
      retraitMembreEnCours;

  final void Function(MembreCommission)
      onRetirerMembre;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const CircleAvatar(
          child: Icon(
            Icons.groups_outlined,
          ),
        ),
        title: Text(
          commission.nom,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${commission.nombreMembres} membre'
          '${commission.nombreMembres > 1 ? 's' : ''}',
        ),
        childrenPadding:
            const EdgeInsets.fromLTRB(
          18,
          0,
          18,
          18,
        ),
        children: [
          if (commission.dateCreation !=
              null)
            Align(
              alignment:
                  Alignment.centerLeft,
              child: Text(
                'Créée le ${_formaterDate(commission.dateCreation!)}',
              ),
            ),
          if (commission.dateCreation !=
              null)
            const SizedBox(height: 12),
          if (commission.membres.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 16,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_off_outlined,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Aucun membre dans cette commission.',
                    ),
                  ),
                ],
              ),
            )
          else
            ...commission.membres.map(
              (membre) =>
                  _MembreCommissionTile(
                membre: membre,
                nomMembre: nomMembreParId(
                  membre.utilisateurId,
                ),
                peutGerer: peutGerer,
                retraitEnCours:
                    retraitMembreEnCours(
                  membre.utilisateurId,
                ),
                onRetirer: () =>
                    onRetirerMembre(membre),
              ),
            ),
          if (peutGerer) ...[
            const Divider(height: 28),
            Align(
              alignment:
                  Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: ajoutEnCours
                    ? null
                    : onAjouterMembre,
                icon: ajoutEnCours
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons
                            .person_add_alt_outlined,
                      ),
                label: Text(
                  ajoutEnCours
                      ? 'Ajout en cours'
                      : 'Ajouter un membre',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MembreCommissionTile
    extends StatelessWidget {
  const _MembreCommissionTile({
    required this.membre,
    required this.nomMembre,
    required this.peutGerer,
    required this.retraitEnCours,
    required this.onRetirer,
  });

  final MembreCommission membre;
  final String nomMembre;
  final bool peutGerer;
  final bool retraitEnCours;
  final VoidCallback onRetirer;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        child: Icon(
          Icons.person_outline,
        ),
      ),
      title: Text(nomMembre),
      subtitle: Text(
        membre.fonctionAffichee,
      ),
      trailing: peutGerer
          ? IconButton(
              tooltip: 'Retirer le membre',
              onPressed: retraitEnCours
                  ? null
                  : onRetirer,
              icon: retraitEnCours
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons
                          .person_remove_outlined,
                    ),
            )
          : null,
    );
  }
}

class _CreerCommissionDialog
    extends StatefulWidget {
  const _CreerCommissionDialog();

  @override
  State<_CreerCommissionDialog>
      createState() =>
          _CreerCommissionDialogState();
}

class _CreerCommissionDialogState
    extends State<_CreerCommissionDialog> {
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
        width: 500,
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
            onFieldSubmitted: (_) =>
                _confirmer(),
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
          label: const Text('Créer'),
        ),
      ],
    );
  }
}

class _AjouterMembreDialog
    extends StatefulWidget {
  const _AjouterMembreDialog({
    required this.membres,
  });

  final List<UtilisateurGestion> membres;

  @override
  State<_AjouterMembreDialog>
      createState() =>
          _AjouterMembreDialogState();
}

class _AjouterMembreDialogState
    extends State<_AjouterMembreDialog> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController
      _fonctionController =
      TextEditingController();

  String? _utilisateurId;

  @override
  void dispose() {
    _fonctionController.dispose();
    super.dispose();
  }

  void _confirmer() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      _DonneesAjoutMembre(
        utilisateurId:
            _utilisateurId!,
        fonction:
            _fonctionController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final membres =
        List<UtilisateurGestion>.from(
      widget.membres,
    )..sort(
        (a, b) => a.nomComplet
            .toLowerCase()
            .compareTo(
              b.nomComplet.toLowerCase(),
            ),
      );

    return AlertDialog(
      title: const Text(
        'Ajouter un membre',
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
                  items: membres.map(
                    (utilisateur) {
                      return DropdownMenuItem(
                        value: utilisateur.id,
                        child: Text(
                          '${utilisateur.nomComplet} — ${utilisateur.roleFormate}',
                          overflow:
                              TextOverflow
                                  .ellipsis,
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
                        value.trim().isEmpty) {
                      return 'Sélectionnez un membre.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
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
                        'Exemple : Président, Rapporteur, Membre',
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
            Icons.person_add_alt_outlined,
          ),
          label: const Text('Ajouter'),
        ),
      ],
    );
  }
}

class _DonneesAjoutMembre {
  const _DonneesAjoutMembre({
    required this.utilisateurId,
    required this.fonction,
  });

  final String utilisateurId;
  final String fonction;
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
          mainAxisSize:
              MainAxisSize.min,
          children: [
            CircleIcon.erreur(context),
            const SizedBox(height: 20),
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

class _CommissionsVides
    extends StatelessWidget {
  const _CommissionsVides({
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
          const SizedBox(height: 80),
          CircleIcon.neutre(context, icon: Icons.groups_outlined),
          const SizedBox(height: 20),
          Text(
            'Aucune commission créée pour cet appel d’offres.',
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

String _formaterDate(
  DateTime date,
) {
  final locale = date.toLocal();

  final jour =
      locale.day.toString().padLeft(2, '0');

  final mois =
      locale.month.toString().padLeft(2, '0');

  return '$jour/$mois/${locale.year}';
}