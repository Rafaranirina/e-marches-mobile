import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/dashboard/presentation/dashboard_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthController(),
      child: const EMarchesApp(),
    ),
  );
}

class EMarchesApp extends StatelessWidget {
  const EMarchesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'e-Marchés Madagascar',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006B3C),
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
        ),
      ),
      home: Consumer<AuthController>(
        builder: (context, authController, child) {
          if (authController.isAuthenticated) {
            return const DashboardPage();
          }

          return const LoginPage();
        },
      ),
    );
  }
}