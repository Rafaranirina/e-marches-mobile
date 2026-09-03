import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/soumission.dart';

class RecepisseDialog extends StatelessWidget {
  const RecepisseDialog({
    required this.recepisse,
    super.key,
  });

  final RecepisseTransmission recepisse;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(
        Icons.verified_outlined,
        color: Theme.of(context).colorScheme.primary,
        size: 40,
      ),
      title: const Text('Soumission transmise'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Votre soumission a été transmise définitivement. '
              'Conservez ce récépissé comme preuve de dépôt.',
            ),
            const SizedBox(height: 20),
            _LigneRecepisse(
              label: 'Référence',
              valeur: recepisse.reference,
            ),
            const SizedBox(height: 12),
            _LigneRecepisse(
              label: 'Horodatage du dépôt',
              valeur: _formatDate(
                recepisse.horodatageDepot,
              ),
            ),
            const SizedBox(height: 12),
            _LigneRecepisse(
              label: 'Nombre de documents',
              valeur: recepisse.nombreDocuments.toString(),
            ),
            const SizedBox(height: 12),
            Text(
              'Empreinte numérique',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SelectableText(
                    recepisse.empreinteDepot,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copier l’empreinte',
                  icon: const Icon(
                    Icons.copy_outlined,
                    size: 18,
                  ),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text: recepisse.empreinteDepot,
                      ),
                    );

                    if (!context.mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Empreinte copiée dans le presse-papiers.',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Non renseigné';
    }

    final dateLocale = date.toLocal();

    final jour = dateLocale.day.toString().padLeft(2, '0');
    final mois = dateLocale.month.toString().padLeft(2, '0');
    final heure = dateLocale.hour.toString().padLeft(2, '0');
    final minute = dateLocale.minute.toString().padLeft(2, '0');

    return '$jour/$mois/${dateLocale.year} à $heure:$minute';
  }
}

class _LigneRecepisse extends StatelessWidget {
  const _LigneRecepisse({
    required this.label,
    required this.valeur,
  });

  final String label;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 2),
        Text(valeur),
      ],
    );
  }
}
