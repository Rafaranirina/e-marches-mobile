import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Bandeau d'en-tête coloré à coins arrondis, avec une texture pointillée
/// discrète en arrière-plan (grille de points, non un dégradé flouté
/// générique) — utilisé sur l'écran de connexion et le tableau de bord
/// pour une identité de marque cohérente.
class HeroHeader extends StatelessWidget {
  const HeroHeader({
    required this.child,
    required this.color,
    this.backgroundImage,
    this.padding = const EdgeInsets.fromLTRB(24, 20, 24, 32),
    this.borderRadius = 32,
    super.key,
  });

  final Widget child;
  final Color color;

  /// Photo optionnelle affichée sous un voile dégradé de [color] (même
  /// principe que le bandeau de la page de connexion du site web : la
  /// couleur de marque reste dominante pour garder le texte lisible,
  /// la photo n'apparaît qu'en toile de fond.
  final ImageProvider? backgroundImage;
  final EdgeInsets padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(borderRadius),
        bottomRight: Radius.circular(borderRadius),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: color,
          image: backgroundImage == null
              ? null
              : DecorationImage(
                  image: backgroundImage!,
                  fit: BoxFit.cover,
                ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: backgroundImage == null
                ? null
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color.withValues(alpha: 0.55),
                      color.withValues(alpha: 0.88),
                    ],
                  ),
          ),
          child: CustomPaint(
            painter: _TextureGrillePoints(
              couleur: Colors.white.withValues(alpha: 0.10),
            ),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _TextureGrillePoints extends CustomPainter {
  const _TextureGrillePoints({required this.couleur});

  final Color couleur;

  static const double _pas = 18;
  static const double _rayon = 1.3;

  @override
  void paint(Canvas canvas, Size size) {
    final peinture = Paint()..color = couleur;

    for (double y = _pas / 2; y < size.height; y += _pas) {
      final decalage = ((y / _pas).round().isOdd) ? _pas / 2 : 0.0;

      for (double x = _pas / 2 + decalage; x < size.width; x += _pas) {
        canvas.drawCircle(Offset(x, y), _rayon, peinture);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TextureGrillePoints oldDelegate) {
    return oldDelegate.couleur != couleur;
  }
}

/// Petit repère de coin utilisé pour donner au bandeau une touche
/// "document officiel" (cf. taquets d'angle d'un formulaire administratif).
class CornerTicks extends StatelessWidget {
  const CornerTicks({required this.color, this.size = 18, super.key});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _TicksPainter(color: color),
    );
  }
}

class _TicksPainter extends CustomPainter {
  const _TicksPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final trait = Paint()
      ..color = color
      ..strokeWidth = math.max(1.4, size.width * 0.08)
      ..strokeCap = StrokeCap.round;

    canvas
      ..drawLine(Offset.zero, Offset(size.width, 0), trait)
      ..drawLine(Offset.zero, Offset(0, size.height), trait);
  }

  @override
  bool shouldRepaint(covariant _TicksPainter oldDelegate) =>
      oldDelegate.color != color;
}
