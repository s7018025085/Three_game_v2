import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart'; // Add for RadialGradient and Alignment
import '../logic/match_logic.dart';

class GemComponent extends PositionComponent with DragCallbacks {
  int gridX;
  int gridY;
  final GemType type;
  final GemModifier modifier;
  final double gemSize; // Renamed from size
  Sprite? sprite;
  final Function(GemComponent, Vector2) onSwipe;
  int health;
  Sprite? bombSprite;
  Sprite? lineHSprite;
  Sprite? lineVSprite;

  bool _isDragging = false;
  Vector2 _dragTotal = Vector2.zero();
  double _pulseTime = 0;

  GemComponent({
    required this.gridX,
    required this.gridY,
    required this.type,
    this.modifier = GemModifier.none,
    required double size,
    required this.onSwipe,
    this.sprite,
    this.health = 1,
    this.bombSprite,
    this.lineHSprite,
    this.lineVSprite,
  })  : gemSize = size,
        super(
          size: Vector2(size, size),
          position: Vector2(gridX * size, gridY * size),
          anchor: Anchor.topLeft,
        );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = Offset(gemSize / 2, gemSize / 2);
    final radius = (gemSize / 2) - 4;

    if (modifier == GemModifier.rainbow) {
      final pulse = (sin(_pulseTime * 5) + 1) / 2;
      final scale = 1.0 + (pulse * 0.05);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(scale);
      canvas.translate(-center.dx, -center.dy);
    }

    // Premium styling with gradients and shadow
    final shadowPaint = Paint()
      ..color = const Color(0x66000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    canvas.drawCircle(center + const Offset(0, 4), radius, shadowPaint);

    if (sprite != null) {
      sprite!.render(
        canvas,
        position: Vector2(4, 4),
        size: Vector2(gemSize - 8, gemSize - 8),
      );
    } else {
      _renderProcedural(canvas, center, radius);
    }

    _renderModifiers(canvas, center, radius);

    if (modifier == GemModifier.rainbow) {
      canvas.restore();
    }
  }

  void _renderProcedural(Canvas canvas, Offset center, double radius) {
    Color color1;
    Color color2;
    switch (type) {
      case GemType.red:
        color1 = const Color(0xFFFF5252);
        color2 = const Color(0xFFD50000);
        break;
      case GemType.green:
        color1 = const Color(0xFF69F0AE);
        color2 = const Color(0xFF00C853);
        break;
      case GemType.blue:
        color1 = const Color(0xFF448AFF);
        color2 = const Color(0xFF2962FF);
        break;
      case GemType.yellow:
        color1 = const Color(0xFFFFE57F);
        color2 = const Color(0xFFFFD600);
        break;
      case GemType.purple:
        color1 = const Color(0xFFE040FB);
        color2 = const Color(0xFFAA00FF);
        break;
      case GemType.orange:
        color1 = const Color(0xFFFFAB40);
        color2 = const Color(0xFFFF6D00);
        break;
      case GemType.rock:
        color1 = const Color(0xFF9E9E9E);
        color2 = const Color(0xFF424242);
        break;
    }

    final paint = Paint();
    if (modifier == GemModifier.rainbow) {
      final rainbowGradient = RadialGradient(
        colors: [
          Colors.red,
          Colors.orange,
          Colors.yellow,
          Colors.green,
          Colors.blue,
          Colors.purple,
        ],
        center: Alignment.center,
        radius: 0.8,
      );
      paint.shader = rainbowGradient
          .createShader(Rect.fromCircle(center: center, radius: radius));
    } else {
      final gradient = RadialGradient(
        colors: [color1, color2],
        center: const Alignment(-0.3, -0.3),
        radius: 0.8,
      );
      paint.shader = gradient
          .createShader(Rect.fromCircle(center: center, radius: radius));
    }

    // Outer glow
    final glowPaint = Paint()
      ..color = (modifier == GemModifier.rainbow ? Colors.white : color1)
          .withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8.0);

    canvas.drawCircle(center, radius, glowPaint);

    // The gem
    if (type == GemType.red || type == GemType.blue || type == GemType.purple) {
      // Draw diamond shape for some
      final path = Path()
        ..moveTo(center.dx, 4)
        ..lineTo(gemSize - 4, center.dy)
        ..lineTo(center.dx, gemSize - 4)
        ..lineTo(4, center.dy)
        ..close();
      canvas.drawPath(path, paint);
      // Highlight
      final highlightPaint = Paint()
        ..color = const Color(0x66FFFFFF)
        ..style = PaintingStyle.fill;
      final highlightPath = Path()
        ..moveTo(center.dx, 6)
        ..lineTo(gemSize - 10, center.dy)
        ..lineTo(center.dx, center.dy)
        ..close();
      canvas.drawPath(highlightPath, highlightPaint);
    } else {
      // Draw rounded rect/circle
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCircle(center: center, radius: radius),
              Radius.circular(radius * 0.4)),
          paint);
      // Highlight
      final highlightPaint = Paint()
        ..color = const Color(0x44FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 3), 3.14,
          1.57, false, highlightPaint);
    }
  }

  void _renderModifiers(Canvas canvas, Offset center, double radius) {
    if (modifier == GemModifier.none) return;

    final pulse = (sin(_pulseTime * 6) + 1) / 2; // Pulsation 0..1
    final bonusScale = 0.6 + (pulse * 0.15); // Scale from 60% to 75%
    final bonusSize = gemSize * bonusScale;
    final bonusOffset = (gemSize - bonusSize) / 2;

    // Draw glowing aura behind the bonus
    final auraPaint = Paint()
      ..color = Colors.white.withOpacity(0.2 + pulse * 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, radius * bonusScale * 0.9, auraPaint);

    if (modifier == GemModifier.bomb && bombSprite != null) {
      bombSprite!.render(
        canvas,
        position: Vector2(bonusOffset, bonusOffset),
        size: Vector2.all(bonusSize),
      );
    } else if (modifier == GemModifier.horizontalLine && lineHSprite != null) {
      lineHSprite!.render(
        canvas,
        position: Vector2(bonusOffset, bonusOffset),
        size: Vector2.all(bonusSize),
      );
    } else if (modifier == GemModifier.verticalLine && lineVSprite != null) {
      lineVSprite!.render(
        canvas,
        position: Vector2(bonusOffset, bonusOffset),
        size: Vector2.all(bonusSize),
      );
    } else {
      // Fallback to procedural if sprite missing
      if (modifier == GemModifier.bomb) {
        final bombCore = Paint()..color = Colors.black87;
        canvas.drawCircle(center, radius * 0.4 * bonusScale, bombCore);
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset center, Offset direction, Paint paint) {
    final end = center + direction;
    canvas.drawLine(center, end, paint);

    final tipSize = gemSize * 0.15;
    final angle = direction.direction;
    final tip1 = end + Offset.fromDirection(angle + 2.4, tipSize);
    final tip2 = end + Offset.fromDirection(angle - 2.4, tipSize);
    canvas.drawLine(end, tip1, paint);
    canvas.drawLine(end, tip2, paint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (modifier != GemModifier.none) {
      _pulseTime += dt;
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _isDragging = true;
    _dragTotal = Vector2.zero();
    scale = Vector2.all(1.1); // Small pop effect
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!_isDragging) return;

    _dragTotal += event.localDelta;
    final swipeThreshold = gemSize / 2;

    if (_dragTotal.length > swipeThreshold) {
      _isDragging = false; // Trigger once
      scale = Vector2.all(1.0);
      onSwipe(this, _dragTotal);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _isDragging = false;
    _dragTotal = Vector2.zero();
    scale = Vector2.all(1.0);
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _isDragging = false;
    _dragTotal = Vector2.zero();
    scale = Vector2.all(1.0);
  }
}
