import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class BoardComponent extends PositionComponent {
  final int rows;
  final int cols;
  final double tileSize;
  final List<List<bool>>? grid;
  final List<List<int>>? jellyBoard;
  final Sprite? jellySprite;

  BoardComponent({
    required this.rows,
    required this.cols,
    required this.tileSize,
    this.grid,
    this.jellyBoard,
    this.jellySprite,
  }) : super(size: Vector2(cols * tileSize, rows * tileSize));

  bool _isActive(int x, int y) => grid == null || grid![x][y];

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final backdropRect = Rect.fromLTWH(
      -tileSize * 0.28,
      -tileSize * 0.28,
      size.x + tileSize * 0.56,
      size.y + tileSize * 0.56,
    );
    final backdropRadius = Radius.circular(tileSize * 0.75);
    final backdropRRect = RRect.fromRectAndRadius(backdropRect, backdropRadius);
    final blurGlowPaint = Paint()
      ..color = const Color(0xCC09101D)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    final backdropFillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xD61A2335),
          Color(0xE00C1526),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(backdropRect);
    final backdropMistPaint = Paint()
      ..color = const Color(0x18FFFFFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final paintLight = Paint()..color = const Color(0x22FFFFFF);
    final paintDark = Paint()..color = const Color(0x11FFFFFF);
    final borderPaint = Paint()
      ..color = const Color(0x55FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(backdropRRect, blurGlowPaint);
    canvas.drawRRect(backdropRRect, backdropFillPaint);
    canvas.drawRRect(backdropRRect.deflate(tileSize * 0.06), backdropMistPaint);

    for (int x = 0; x < cols; x++) {
      for (int y = 0; y < rows; y++) {
        final rect =
            Rect.fromLTWH(x * tileSize, y * tileSize, tileSize, tileSize);

        // Render Jelly Background
        if (jellyBoard != null &&
            jellyBoard![x][y] > 0 &&
            jellySprite != null) {
          jellySprite!.render(
            canvas,
            position: Vector2(x * tileSize, y * tileSize),
            size: Vector2.all(tileSize),
            overridePaint: jellyBoard![x][y] == 1
                ? (Paint()..color = Colors.white.withValues(alpha: 0.7))
                : null,
          );
        }

        if (_isActive(x, y)) {
          final paint = (x + y) % 2 == 0 ? paintLight : paintDark;
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(8)),
            paint,
          );
        } else {
          // Hole — ничего не рисуем (просто пустая клетка)
        }
      }
    }

    canvas.drawRRect(backdropRRect.deflate(1), borderPaint);
  }
}
