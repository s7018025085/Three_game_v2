import 'level_model.dart';

/// Generates 100 predefined levels with symmetric grid shapes.
class LevelGenerator {
  static const int _cols = 8;
  static const int _rows = 8;

  static List<LevelModel> generate() {
    final levels = <LevelModel>[];

    // Group 1: Full grid (levels 1–10) — no holes
    for (int i = 1; i <= 10; i++) {
      levels.add(_make(i, _full(), 25 + i * 2, 'Level $i', moves: 25));
    }

    // Group 2: Simple symmetric holes (levels 11–30)
    levels.add(_make(11, _corners4(), 30, 'Corners'));
    levels.add(_make(12, _ring(), 32, 'Ring', moves: 28));
    levels.add(_make(13, _cross(), 34, 'Cross', moves: 28));
    levels.add(_make(14, _hLines(), 36, 'H-Lines', moves: 28));
    levels.add(_make(15, _vLines(), 36, 'V-Lines', moves: 28));
    levels.add(_make(16, _xShape(), 38, 'X-Shape', moves: 27));
    levels.add(_make(17, _cornerCuts(), 38, 'Corner Cuts', moves: 27));
    levels.add(_make(18, _diagonalStrips(), 40, 'Diagonals', moves: 26));
    levels.add(_make(19, _checkerBig(), 40, 'Big Checker', moves: 26));
    levels.add(_make(20, _tShape(), 42, 'T-Shape', moves: 25));
    levels.add(_make(21, _lShape(), 42, 'L-Shape', moves: 25));
    levels.add(_make(22, _uShape(), 44, 'U-Shape', moves: 25));
    levels.add(_make(23, _hBridges(), 44, 'Bridges', moves: 24));
    levels.add(_make(24, _oval(), 46, 'Oval', moves: 24));
    levels.add(_make(25, _arrow(), 46, 'Arrow', moves: 24));
    levels.add(_make(26, _zigzag(), 48, 'Zigzag', moves: 23));
    levels.add(_make(27, _staircase(), 48, 'Staircase', moves: 23));
    levels.add(_make(28, _hourglass(), 50, 'Hourglass', moves: 22));
    levels.add(_make(29, _windmill(), 50, 'Windmill', moves: 22));
    levels.add(_make(30, _heart(), 52, 'Heart', moves: 22));

    // Group 3: Islands — disconnected clusters (levels 31–60)
    levels.add(_make(31, _twoIslands(), 54, 'Two Islands', moves: 22));
    levels.add(_make(32, _fourIslands(), 54, 'Four Islands', moves: 22));
    levels.add(_make(33, _cornerIslands(), 56, 'Corner Islands', moves: 21));
    levels.add(_make(34, _stripIslands(), 56, 'Strip Islands', moves: 21));
    levels.add(_make(35, _centerHole(), 58, 'Center Void', moves: 21));
    levels.add(_make(36, _pillarHoles(), 58, 'Pillars', moves: 21));
    levels.add(_make(37, _checkerSmall(), 60, 'Small Checker', moves: 20));
    levels.add(_make(38, _rowGaps(), 60, 'Row Gaps', moves: 20));
    levels.add(_make(39, _colGaps(), 62, 'Column Gaps', moves: 20));
    levels.add(_make(40, _lattice(), 62, 'Lattice', moves: 20));
    for (int i = 41; i <= 60; i++) {
      levels.add(_make(i, _randomSymmetric(i), 64 + (i - 41) * 2, 'Level $i',
          moves: 19));
    }

    // Group 4: Complex shapes (levels 61–100)
    levels.add(_make(61, _diamond(), 80, 'Diamond', moves: 18));
    levels.add(_make(62, _star(), 82, 'Star', moves: 18));
    levels.add(_make(63, _skull(), 84, 'Skull', moves: 17));
    levels.add(_make(64, _crown(), 86, 'Crown', moves: 17));
    levels.add(_make(65, _lightning(), 88, 'Lightning', moves: 17));
    for (int i = 66; i <= 100; i++) {
      levels.add(_make(
          i, _randomSymmetric(i * 7), 90 + (i - 66) * 3, 'Level $i',
          moves: 16));
    }

    return levels;
  }

  static LevelModel _make(int id, List<List<bool>> grid, int star3, String name,
      {int moves = 25}) {
    return LevelModel(
      id: id,
      grid: grid,
      moveLimit: moves,
      star1Score: (star3 * 10).toInt(),
      star2Score: (star3 * 20).toInt(),
      star3Score: (star3 * 35).toInt(),
      name: name,
    );
  }

  // ─── Grid factory helpers ───────────────────────────────────────────────

  /// All cells active
  static List<List<bool>> _full() =>
      List.generate(_cols, (_) => List.filled(_rows, true));

  /// Empty base grid
  static List<List<bool>> _empty() =>
      List.generate(_cols, (_) => List.filled(_rows, false));

  /// Apply vertical symmetry: copy left half to right
  static List<List<bool>> _sym(List<List<bool>> g) {
    for (int x = 0; x < _cols ~/ 2; x++) {
      for (int y = 0; y < _rows; y++) {
        g[_cols - 1 - x][y] = g[x][y];
      }
    }
    return g;
  }

  static List<List<bool>> _corners4() {
    final g = _full();
    for (int d = 0; d < 2; d++) {
      for (int e = 0; e < 2; e++) {
        g[d][e] = false;
        g[_cols - 1 - d][e] = false;
        g[d][_rows - 1 - e] = false;
        g[_cols - 1 - d][_rows - 1 - e] = false;
      }
    }
    return g;
  }

  static List<List<bool>> _ring() {
    final g = _full();
    for (int x = 2; x <= 5; x++) {
      for (int y = 2; y <= 5; y++) {
        g[x][y] = false;
      }
    }
    return g;
  }

  static List<List<bool>> _cross() {
    final g = _empty();
    for (int x = 0; x < _cols; x++) {
      g[x][3] = true;
      g[x][4] = true;
    }
    for (int y = 0; y < _rows; y++) {
      g[3][y] = true;
      g[4][y] = true;
    }
    return g;
  }

  static List<List<bool>> _hLines() {
    final g = _empty();
    for (int x = 0; x < _cols; x++) {
      g[x][1] = true;
      g[x][2] = true;
      g[x][5] = true;
      g[x][6] = true;
    }
    return g;
  }

  static List<List<bool>> _vLines() {
    final g = _empty();
    for (int y = 0; y < _rows; y++) {
      g[1][y] = true;
      g[2][y] = true;
      g[5][y] = true;
      g[6][y] = true;
    }
    return g;
  }

  static List<List<bool>> _xShape() {
    final g = _empty();
    for (int i = 0; i < _rows; i++) {
      if (i < _cols) g[i][i] = true;
      if (i < _cols) g[_cols - 1 - i][i] = true;
    }
    return g;
  }

  static List<List<bool>> _cornerCuts() {
    final g = _full();
    g[0][0] = g[1][0] = g[0][1] = false;
    g[6][0] = g[7][0] = g[7][1] = false;
    g[0][6] = g[0][7] = g[1][7] = false;
    g[6][7] = g[7][6] = g[7][7] = false;
    return g;
  }

  static List<List<bool>> _diagonalStrips() {
    final g = _empty();
    for (int x = 0; x < _cols; x++) {
      for (int y = 0; y < _rows; y++) {
        if ((x + y) % 3 != 0) g[x][y] = true;
      }
    }
    return _sym(g);
  }

  static List<List<bool>> _checkerBig() {
    final g = _empty();
    for (int x = 0; x < _cols; x++) {
      for (int y = 0; y < _rows; y++) {
        if ((x ~/ 2 + y ~/ 2) % 2 == 0) g[x][y] = true;
      }
    }
    return g;
  }

  static List<List<bool>> _tShape() {
    final g = _empty();
    for (int x = 0; x < _cols; x++) g[x][0] = g[x][1] = true;
    for (int y = 0; y < _rows; y++) g[3][y] = g[4][y] = true;
    return g;
  }

  static List<List<bool>> _lShape() {
    final g = _empty();
    for (int y = 0; y < _rows; y++) g[0][y] = g[1][y] = true;
    for (int x = 0; x < _cols; x++) g[x][6] = g[x][7] = true;
    return _sym(g);
  }

  static List<List<bool>> _uShape() {
    final g = _empty();
    for (int y = 0; y < _rows; y++) {
      g[0][y] = g[1][y] = true;
      g[6][y] = g[7][y] = true;
    }
    for (int x = 0; x < _cols; x++) g[x][6] = g[x][7] = true;
    return g;
  }

  static List<List<bool>> _hBridges() {
    final g = _full();
    for (int x = 2; x <= 5; x++) {
      g[x][2] = g[x][3] = g[x][4] = g[x][5] = false;
    }
    return g;
  }

  static List<List<bool>> _oval() {
    final g = _empty();
    final cx = 3.5, cy = 3.5, rx = 3.2, ry = 3.2;
    for (int x = 0; x < _cols; x++) {
      for (int y = 0; y < _rows; y++) {
        double dx = (x - cx) / rx;
        double dy = (y - cy) / ry;
        if (dx * dx + dy * dy <= 1.0) g[x][y] = true;
      }
    }
    return g;
  }

  static List<List<bool>> _arrow() {
    final g = _empty();
    for (int x = 0; x < _cols; x++) g[x][3] = g[x][4] = true;
    for (int d = 0; d < 4; d++) {
      g[3 - d][d] = g[3 - d][7 - d] = true;
      g[4 + d < _cols ? 4 + d : 7][d] =
          g[4 + d < _cols ? 4 + d : 7][7 - d] = true;
    }
    return _sym(g);
  }

  static List<List<bool>> _zigzag() {
    final g = _empty();
    for (int x = 0; x < _cols; x++) {
      int base = (x % 4 < 2) ? 2 : 4;
      for (int y = base; y < base + 2; y++) g[x][y] = true;
      g[x][0] = g[x][1] = true;
      g[x][6] = g[x][7] = true;
    }
    return g;
  }

  static List<List<bool>> _staircase() {
    final g = _empty();
    for (int x = 0; x < _cols; x++) {
      for (int y = x; y < _rows; y++) g[x][y] = true;
    }
    return _sym(g);
  }

  static List<List<bool>> _hourglass() {
    final g = _empty();
    for (int y = 0; y < _rows; y++) {
      int half = (y < 4) ? y : 7 - y;
      for (int x = half; x < _cols - half; x++) g[x][y] = true;
    }
    return g;
  }

  static List<List<bool>> _windmill() {
    final g = _full();
    g[0][0] = g[1][0] = g[0][1] = false;
    g[7][0] = g[6][0] = g[7][1] = false;
    g[0][7] = g[1][7] = g[0][6] = false;
    g[7][7] = g[6][7] = g[7][6] = false;
    g[3][3] = g[4][3] = g[3][4] = g[4][4] = false;
    return g;
  }

  static List<List<bool>> _heart() {
    final g = _empty();
    // Approximate heart shape
    const heart = [
      [0, 0, 1, 1, 0, 1, 1, 0],
      [0, 1, 1, 1, 1, 1, 1, 0],
      [1, 1, 1, 1, 1, 1, 1, 1],
      [1, 1, 1, 1, 1, 1, 1, 1],
      [0, 1, 1, 1, 1, 1, 1, 0],
      [0, 0, 1, 1, 1, 1, 0, 0],
      [0, 0, 0, 1, 1, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0],
    ];
    for (int x = 0; x < _cols; x++) {
      for (int y = 0; y < _rows; y++) {
        g[x][y] = heart[y][x] == 1;
      }
    }
    return g;
  }

  static List<List<bool>> _twoIslands() {
    final g = _empty();
    for (int x = 0; x < 3; x++) for (int y = 1; y < 7; y++) g[x][y] = true;
    for (int x = 5; x < 8; x++) for (int y = 1; y < 7; y++) g[x][y] = true;
    return g;
  }

  static List<List<bool>> _fourIslands() {
    final g = _empty();
    for (int x = 0; x < 3; x++) for (int y = 0; y < 3; y++) g[x][y] = true;
    for (int x = 5; x < 8; x++) for (int y = 0; y < 3; y++) g[x][y] = true;
    for (int x = 0; x < 3; x++) for (int y = 5; y < 8; y++) g[x][y] = true;
    for (int x = 5; x < 8; x++) for (int y = 5; y < 8; y++) g[x][y] = true;
    return g;
  }

  static List<List<bool>> _cornerIslands() {
    final g = _full();
    for (int x = 2; x <= 5; x++) g[x][0] = g[x][1] = g[x][6] = g[x][7] = false;
    for (int y = 2; y <= 5; y++) g[0][y] = g[1][y] = g[6][y] = g[7][y] = false;
    return g;
  }

  static List<List<bool>> _stripIslands() {
    final g = _empty();
    for (int y = 0; y < _rows; y++) {
      for (int x = 0; x < 2; x++) g[x][y] = true;
      for (int x = 3; x < 5; x++) g[x][y] = true;
      for (int x = 6; x < 8; x++) g[x][y] = true;
    }
    return g;
  }

  static List<List<bool>> _centerHole() {
    final g = _full();
    for (int x = 2; x <= 5; x++) for (int y = 2; y <= 5; y++) g[x][y] = false;
    return g;
  }

  static List<List<bool>> _pillarHoles() {
    final g = _full();
    for (int y = 2; y <= 5; y++) {
      g[2][y] = false;
      g[5][y] = false;
    }
    return g;
  }

  static List<List<bool>> _checkerSmall() {
    final g = _empty();
    for (int x = 0; x < _cols; x++) {
      for (int y = 0; y < _rows; y++) {
        if ((x + y) % 2 == 0) g[x][y] = true;
      }
    }
    return g;
  }

  static List<List<bool>> _rowGaps() {
    final g = _empty();
    for (int x = 0; x < _cols; x++) {
      for (int y = 0; y < _rows; y++) {
        if (y % 2 == 0) g[x][y] = true;
      }
    }
    return g;
  }

  static List<List<bool>> _colGaps() {
    final g = _empty();
    for (int x = 0; x < _cols; x++) {
      for (int y = 0; y < _rows; y++) {
        if (x % 2 == 0) g[x][y] = true;
      }
    }
    return g;
  }

  static List<List<bool>> _lattice() {
    final g = _empty();
    for (int x = 0; x < _cols; x++) {
      for (int y = 0; y < _rows; y++) {
        if (x % 2 == 0 || y % 2 == 0) g[x][y] = true;
      }
    }
    return g;
  }

  static List<List<bool>> _diamond() {
    final g = _empty();
    for (int x = 0; x < _cols; x++) {
      for (int y = 0; y < _rows; y++) {
        if ((x - 3.5).abs() + (y - 3.5).abs() <= 3.5) g[x][y] = true;
      }
    }
    return g;
  }

  static List<List<bool>> _star() {
    final g = _cross();
    for (int d = 0; d < _cols; d++) {
      if (d < _cols) g[d][d] = g[_cols - 1 - d][d] = true;
    }
    return g;
  }

  static List<List<bool>> _skull() {
    final g = _oval();
    g[2][5] = g[3][5] = g[4][5] = g[5][5] = true;
    g[2][6] = g[5][6] = true;
    g[2][4] = g[5][4] = false;
    return g;
  }

  static List<List<bool>> _crown() {
    final g = _empty();
    for (int x = 0; x < _cols; x++) for (int y = 3; y < 8; y++) g[x][y] = true;
    g[0][0] = g[0][1] = g[0][2] = true;
    g[3][0] = g[3][1] = g[4][0] = g[4][1] = true;
    g[7][0] = g[7][1] = g[7][2] = true;
    return g;
  }

  static List<List<bool>> _lightning() {
    final g = _empty();
    for (int y = 0; y < 4; y++) {
      for (int x = 4 - y; x < 8; x++) g[x][y] = true;
    }
    for (int y = 4; y < 8; y++) {
      for (int x = 0; x < 8 - (y - 4); x++) g[x][y] = true;
    }
    return _sym(g);
  }

  /// Pseudo-random symmetric grid seeded by [seed]
  static List<List<bool>> _randomSymmetric(int seed) {
    final g = _empty();
    int r = seed;
    for (int x = 0; x < _cols ~/ 2; x++) {
      for (int y = 0; y < _rows; y++) {
        r = (r * 1664525 + 1013904223) & 0xFFFFFFFF;
        g[x][y] = (r % 3) != 0; // ~67% active
        g[_cols - 1 - x][y] = g[x][y];
      }
    }
    // Ensure at least 20 cells are active
    int activeCount = 0;
    for (int x = 0; x < _cols; x++)
      for (int y = 0; y < _rows; y++) if (g[x][y]) activeCount++;
    if (activeCount < 20) return _full();
    return g;
  }
}
