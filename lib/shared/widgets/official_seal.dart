import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Emblème de marque : un sceau/cachet officiel stylisé — clin d'œil au
/// tampon administratif apposé sur les marchés publics — plutôt qu'une
/// icône Material générique. Réutilisé sur l'écran de connexion et le
/// tableau de bord pour une identité reconnaissable.
class OfficialSeal extends StatelessWidget {
  const OfficialSeal({
    required this.diametre,
    required this.couleurAnneau,
    required this.couleurFond,
    required this.couleurMonogramme,
    this.monogramme = 'eM',
    super.key,
  });

  final double diametre;
  final Color couleurAnneau;
  final Color couleurFond;
  final Color couleurMonogramme;
  final String monogramme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: diametre,
      height: diametre,
      child: CustomPaint(
        painter: _SceauPainter(
          couleurAnneau: couleurAnneau,
          couleurFond: couleurFond,
        ),
        child: Center(
          child: Text(
            monogramme,
            style: GoogleFonts.manrope(
              fontSize: diametre * 0.34,
              fontWeight: FontWeight.w800,
              color: couleurMonogramme,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _SceauPainter extends CustomPainter {
  const _SceauPainter({
    required this.couleurAnneau,
    required this.couleurFond,
  });

  final Color couleurAnneau;
  final Color couleurFond;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final rayon = size.width / 2;

    final fond = Paint()..color = couleurFond;
    canvas.drawCircle(centre, rayon, fond);

    // Anneau extérieur perlé, comme la bordure gaufrée d'un cachet officiel.
    const nombrePerles = 28;
    final rayonPerles = rayon * 0.92;
    final taillePerle = rayon * 0.045;
    final perle = Paint()..color = couleurAnneau;

    for (var i = 0; i < nombrePerles; i++) {
      final angle = (2 * math.pi * i) / nombrePerles;
      final position = Offset(
        centre.dx + rayonPerles * math.cos(angle),
        centre.dy + rayonPerles * math.sin(angle),
      );
      canvas.drawCircle(position, taillePerle, perle);
    }

    // Deux anneaux fins concentriques.
    final trait = Paint()
      ..color = couleurAnneau
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, rayon * 0.02);

    canvas.drawCircle(centre, rayon * 0.78, trait);
    canvas.drawCircle(centre, rayon * 0.70, trait);
  }

  @override
  bool shouldRepaint(covariant _SceauPainter oldDelegate) {
    return oldDelegate.couleurAnneau != couleurAnneau ||
        oldDelegate.couleurFond != couleurFond;
  }
}
