import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

class ParticleManager {
  static final Random _rnd = Random();

  static ParticleSystemComponent createExplosion(
      Vector2 position, Color color) {
    return ParticleSystemComponent(
      position: position,
      particle: Particle.generate(
        count: 15,
        lifespan: 0.6,
        generator: (i) {
          return AcceleratedParticle(
            acceleration: Vector2(0, 200), // Gravity
            speed: Vector2(
              (_rnd.nextDouble() - 0.5) * 300,
              (_rnd.nextDouble() - 0.5) * 300,
            ),
            position: Vector2.zero(),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final paint = Paint()
                  ..color = color.withValues(alpha: 1.0 - particle.progress)
                  ..style = PaintingStyle.fill
                  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

                canvas.drawCircle(
                  Offset.zero,
                  3.0 * (1.0 - particle.progress),
                  paint,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
