import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reproduction exacte du logo du site web (`ProcurementLogo.tsx` /
/// `globals.css` dans `e-marches-memoire/frotend`) : un sceau institutionnel
/// (cercle vert, anneau or, pictogramme de bâtiment, badge de validation) et
/// le mot-symbole « e-marchés », pour une identité de marque identique entre
/// le web et le mobile.
class ProcurementLogo extends StatelessWidget {
  const ProcurementLogo({
    this.iconSize = 46,
    this.wordmarkFontSize = 23,
    this.showWordmark = true,
    this.showCaption = true,
    this.inverse = false,
    this.axis = Axis.horizontal,
    this.couleurTexteForcee,
    super.key,
  });

  final double iconSize;
  final double wordmarkFontSize;
  final bool showWordmark;
  final bool showCaption;
  final bool inverse;
  final Axis axis;

  /// Remplace la couleur habituelle du mot-symbole (blanc/menthe en mode
  /// inversé, vert de marque sinon) par une couleur unique imposée — utilisé
  /// sur l'écran de connexion où le texte doit rester lisible en bleu marine
  /// quel que soit le fond.
  final Color? couleurTexteForcee;

  static const _bordureClaire = Color(0x30073A48);
  static const _degradeClair = [
    Color(0xFF0B7C61),
    Color(0xFF087153),
    Color(0xFF07384C),
  ];

  @override
  Widget build(BuildContext context) {
    // En mode "inverse" (posé sur un fond déjà coloré, ex. l'en-tête teal
    // du HeroHeader), un dégradé sombre fixe risquait de se fondre dans le
    // fond au lieu de s'en détacher — quel que soit le fond, un chip
    // translucide clair (effet "verre dépoli") reste, lui, toujours
    // visible en contraste.
    final icone = Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(iconSize * (14 / 46)),
        gradient: inverse
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.22),
                  Colors.white.withValues(alpha: 0.06),
                ],
              )
            : const LinearGradient(
                begin: Alignment(-0.5, -1),
                end: Alignment(0.5, 1),
                colors: _degradeClair,
                stops: [0, 0.51, 1],
              ),
        border: Border.all(
          color: inverse
              ? Colors.white.withValues(alpha: 0.6)
              : _bordureClaire,
          width: inverse ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: iconSize * 0.32,
            offset: Offset(0, iconSize * 0.14),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size.square(iconSize),
        painter: const _SceauProcurementPainter(),
      ),
    );

    if (!showWordmark) {
      return icone;
    }

    final motSymbole = _ProcurementWordmark(
      fontSize: wordmarkFontSize,
      inverse: inverse,
      showCaption: showCaption,
      couleurForcee: couleurTexteForcee,
    );

    if (axis == Axis.vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icone,
          const SizedBox(height: 14),
          motSymbole,
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        icone,
        const SizedBox(width: 13),
        motSymbole,
      ],
    );
  }
}

/// Dessine, dans un repère 0–100 identique au `viewBox` SVG d'origine, le
/// sceau : cercle extérieur, disque intérieur cerclé d'or, pictogramme de
/// bâtiment institutionnel et badge de validation.
class _SceauProcurementPainter extends CustomPainter {
  const _SceauProcurementPainter();

  static const _vert = Color(0xFF08783E);
  static const _or = Color(0xFFF2C94C);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);

    final vertPlein = Paint()..color = _vert;
    final orPlein = Paint()..color = _or;
    final blancPlein = Paint()..color = Colors.white;

    final anneauOr = Paint()
      ..color = _or
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final traitCoche = Paint()
      ..color = _vert
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Cercle extérieur puis disque intérieur cerclé d'or.
    canvas.drawCircle(const Offset(50, 50), 47, vertPlein);
    canvas.drawCircle(const Offset(50, 50), 39, blancPlein);
    canvas.drawCircle(const Offset(50, 50), 39, anneauOr);

    // Bâtiment institutionnel : toit, fronton, trois colonnes, base.
    final toit = Path()
      ..moveTo(27, 43)
      ..lineTo(50, 28)
      ..lineTo(73, 43)
      ..close();
    canvas.drawPath(toit, vertPlein);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(29, 44, 42, 5),
        const Radius.circular(1),
      ),
      vertPlein,
    );

    for (final x in [33.0, 47.0, 61.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 51, 6, 21),
          const Radius.circular(1),
        ),
        vertPlein,
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(27, 74, 46, 6),
        const Radius.circular(2),
      ),
      vertPlein,
    );

    // Badge de validation numérique.
    canvas.drawCircle(const Offset(70, 69), 13, orPlein);

    final coche = Path()
      ..moveTo(63, 69)
      ..lineTo(68, 74)
      ..lineTo(77, 63);
    canvas.drawPath(coche, traitCoche);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SceauProcurementPainter oldDelegate) => false;
}

class _ProcurementWordmark extends StatelessWidget {
  const _ProcurementWordmark({
    required this.fontSize,
    required this.inverse,
    required this.showCaption,
    this.couleurForcee,
  });

  final double fontSize;
  final bool inverse;
  final bool showCaption;
  final Color? couleurForcee;

  static const _accentSombre = Color(0xFF75D7B2);

  @override
  Widget build(BuildContext context) {
    final force = couleurForcee;
    final scheme = Theme.of(context).colorScheme;

    // Sur fond clair (non "inverse"), sans couleur imposée, le mot-symbole
    // reprend les rôles du thème de l'app (teal/ochre) plutôt qu'un vert
    // fixe hérité de l'ancienne identité — pour rester cohérent si ce
    // widget est un jour posé sur une surface claire.
    final couleurE = force ?? (inverse ? Colors.white : scheme.onSurface);
    final couleurAccent =
        force ?? (inverse ? _accentSombre : scheme.primary);
    final couleurCaption = force != null
        ? force.withValues(alpha: 0.72)
        : (inverse
            ? Colors.white.withValues(alpha: 0.54)
            : scheme.onSurfaceVariant);

    final styleBase = GoogleFonts.sourceSerif4(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.4,
      height: 1,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            style: styleBase.copyWith(color: couleurE),
            children: [
              const TextSpan(text: 'e'),
              TextSpan(
                text: '-',
                style: styleBase.copyWith(
                  color: couleurAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: 'marchés',
                style: styleBase.copyWith(color: couleurAccent),
              ),
            ],
          ),
        ),
        if (showCaption) ...[
          SizedBox(height: fontSize * 0.22),
          Text(
            'PLATEFORME DES MARCHÉS PUBLICS',
            style: GoogleFonts.publicSans(
              fontSize: fontSize * 0.315,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.02,
              color: couleurCaption,
            ),
          ),
        ],
      ],
    );
  }
}
