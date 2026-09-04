import 'package:e_marches_mobile/core/storage/secure_storage_service.dart';
import 'package:e_marches_mobile/features/auth/data/auth_repository.dart';
import 'package:e_marches_mobile/features/auth/presentation/auth_controller.dart';
import 'package:e_marches_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// N'accède jamais au plugin natif `flutter_secure_storage` (indisponible
/// dans un test widget) — simule simplement "aucun token stocké".
class _FakeSecureStorageService extends SecureStorageService {
  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<void> saveAccessToken(String token) async {}

  @override
  Future<void> deleteAccessToken() async {}

  @override
  Future<void> clearAll() async {}
}

void main() {
  testWidgets('Affiche l’écran de connexion', (tester) async {
    final authController = AuthController(
      repository: AuthRepository(storage: _FakeSecureStorageService()),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: authController,
        child: const EMarchesApp(),
      ),
    );

    // Premier frame : restaurerSession() n'a pas encore résolu, l'écran de
    // chargement (isRestoring == true par défaut) est affiché.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Le postFrameCallback + restaurerUtilisateurConnecte() (aucun token
    // stocké donc retour immédiat à null, sans appel réseau) résolvent.
    await tester.pump();
    await tester.pump();

    expect(find.text('Connexion'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });
}
