import 'package:e_marches_mobile/features/auth/presentation/auth_controller.dart';
import 'package:e_marches_mobile/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Affiche l’écran de connexion', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthController(),
        child: const EMarchesApp(),
      ),
    );

    expect(find.text('e-Marchés Madagascar'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });
}