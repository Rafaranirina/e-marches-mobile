import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Identité visuelle de l'app : un bleu-sarcelle institutionnel (confiance,
/// service public) associé à un ocre bronze (cachet administratif) et une
/// terre cuite discrète — plutôt que le vert générique dérivé par défaut,
/// pour se distinguer et laisser le vert aux seuls statuts "actif/validé"
/// affichés via [StatutChip].
///
/// Typographie : Manrope (titres, affirmé) + Public Sans (texte courant —
/// la police conçue pour les services numériques publics, cohérente avec
/// le domaine du projet).
abstract final class AppTheme {
  static const _primaireClaire = Color(0xFF14586B);
  static const _secondaireClaire = Color(0xFF8A6A22);
  static const _surSecondaireContainerClaire = Color(0xFF4A3A0E);
  static const _secondaireContainerClaire = Color(0xFFF3E3BC);
  static const _tertiaireClaire = Color(0xFF8C3F32);
  static const _surTertiaireContainerClaire = Color(0xFF4A1D16);
  static const _tertiaireContainerClaire = Color(0xFFF5DCD5);

  static const _secondaireSombre = Color(0xFFD9B15B);
  static const _surSecondaireSombre = Color(0xFF3A2D08);
  static const _secondaireContainerSombre = Color(0xFF5A481A);
  static const _tertiaireSombre = Color(0xFFE08670);
  static const _surTertiaireSombre = Color(0xFF3C140D);
  static const _tertiaireContainerSombre = Color(0xFF6B2E23);

  static ThemeData get light => _construire(
        ColorScheme.fromSeed(
          seedColor: _primaireClaire,
          brightness: Brightness.light,
        ).copyWith(
          secondary: _secondaireClaire,
          onSecondary: Colors.white,
          secondaryContainer: _secondaireContainerClaire,
          onSecondaryContainer: _surSecondaireContainerClaire,
          tertiary: _tertiaireClaire,
          onTertiary: Colors.white,
          tertiaryContainer: _tertiaireContainerClaire,
          onTertiaryContainer: _surTertiaireContainerClaire,
        ),
      );

  static ThemeData get dark => _construire(
        ColorScheme.fromSeed(
          seedColor: _primaireClaire,
          brightness: Brightness.dark,
        ).copyWith(
          secondary: _secondaireSombre,
          onSecondary: _surSecondaireSombre,
          secondaryContainer: _secondaireContainerSombre,
          onSecondaryContainer: _secondaireContainerClaire,
          tertiary: _tertiaireSombre,
          onTertiary: _surTertiaireSombre,
          tertiaryContainer: _tertiaireContainerSombre,
          onTertiaryContainer: _tertiaireContainerClaire,
        ),
      );

  static ThemeData _construire(ColorScheme scheme) {
    // `GoogleFonts.publicSansTextTheme()` sans argument ignore la luminosité
    // du thème et renvoie des couleurs de texte quasi noires par défaut : en
    // thème sombre, tout texte n'ayant pas de couleur explicite (bodyMedium,
    // bodySmall, titleMedium...) devenait alors quasi invisible sur fond
    // sombre. On lui passe donc la palette de base correspondant à la
    // luminosité réelle du thème, pour que les couleurs par défaut restent
    // lisibles avant même toute surcharge explicite.
    final texteBase = GoogleFonts.publicSansTextTheme(
      ThemeData(brightness: scheme.brightness).textTheme.apply(
            bodyColor: scheme.onSurface,
            displayColor: scheme.onSurface,
          ),
    );

    final texte = texteBase.copyWith(
      displayLarge: GoogleFonts.manrope(
        textStyle: texteBase.displayLarge,
        fontWeight: FontWeight.w800,
      ),
      displayMedium: GoogleFonts.manrope(
        textStyle: texteBase.displayMedium,
        fontWeight: FontWeight.w800,
      ),
      headlineLarge: GoogleFonts.manrope(
        textStyle: texteBase.headlineLarge,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: GoogleFonts.manrope(
        textStyle: texteBase.headlineMedium,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: GoogleFonts.manrope(
        textStyle: texteBase.headlineSmall,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: GoogleFonts.manrope(
        textStyle: texteBase.titleLarge,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: GoogleFonts.manrope(
        textStyle: texteBase.titleMedium,
        fontWeight: FontWeight.w600,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: texte,
      scaffoldBackgroundColor: scheme.surface,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      chipTheme: ChipThemeData(
        labelStyle: GoogleFonts.publicSans(fontWeight: FontWeight.w600),
      ),
    );
  }
}
