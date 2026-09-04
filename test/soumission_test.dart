import 'package:e_marches_mobile/features/soumissions/data/soumission.dart';
import 'package:flutter_test/flutter_test.dart';

// Vérifie le contrat JSON exact attendu par le backend
// (soumission.controller.js) — notamment les champs ajoutés lors de la
// correction du workflow de transmission (empreinte_depot, nombre_documents,
// les références de l'appel d'offres joint par GET /mes-soumissions).
void main() {
  group('Soumission.fromJson', () {
    test('lit tous les champs réels renvoyés par le backend', () {
      final soumission = Soumission.fromJson({
        'id': 'sou-1',
        'reference': 'SOU-2026-abc123',
        'statut': 'soumise',
        'montant_propose': '15000000.50',
        'delai_execution': '90 jours',
        'horodatage_depot': '2026-01-15T10:30:00.000Z',
        'entreprise': 'ACME SARL',
        'appel_offre_id': 'ao-1',
        'appel_offre_reference': 'AO-2026-001',
        'appel_offre_titre': 'Construction d’un pont',
        'nombre_documents': 3,
        'empreinte_depot':
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        'date_creation': '2026-01-10T08:00:00.000Z',
        'date_maj': '2026-01-15T10:30:00.000Z',
      });

      expect(soumission.id, 'sou-1');
      expect(soumission.reference, 'SOU-2026-abc123');
      expect(soumission.statut, 'soumise');
      // Les montants Postgres arrivent en chaîne (numeric), pas en double.
      expect(soumission.montantPropose, 15000000.50);
      expect(soumission.delaiExecution, '90 jours');
      expect(soumission.entreprise, 'ACME SARL');
      expect(soumission.appelOffreReference, 'AO-2026-001');
      expect(soumission.appelOffreTitre, 'Construction d’un pont');
      expect(soumission.nombreDocuments, 3);
      expect(soumission.empreinteDepot, isNotNull);
      expect(soumission.horodatageDepot, isNotNull);
    });

    test('accepte une réponse minimale (soumission tout juste créée)', () {
      final soumission = Soumission.fromJson({
        'id': 'sou-2',
        'reference': 'SOU-2026-def456',
        'statut': 'brouillon',
      });

      expect(soumission.estBrouillon, isTrue);
      expect(soumission.montantPropose, isNull);
      expect(soumission.empreinteDepot, isNull);
      expect(soumission.nombreDocuments, isNull);
    });

    test('estBrouillon est insensible à la casse et aux espaces', () {
      final soumission = Soumission.fromJson({
        'id': 'sou-3',
        'reference': 'REF',
        'statut': '  BROUILLON  ',
      });

      expect(soumission.estBrouillon, isTrue);
    });
  });

  group('RecepisseTransmission.fromJson', () {
    test('lit le récépissé renvoyé par PATCH /transmettre', () {
      final recepisse = RecepisseTransmission.fromJson({
        'reference': 'SOU-2026-abc123',
        'horodatage_depot': '2026-01-15T10:30:00.000Z',
        'empreinte_depot': 'abcdef0123456789',
        'nombre_documents': 2,
      });

      expect(recepisse.reference, 'SOU-2026-abc123');
      expect(recepisse.empreinteDepot, 'abcdef0123456789');
      expect(recepisse.nombreDocuments, 2);
      expect(recepisse.horodatageDepot, isNotNull);
    });
  });
}
