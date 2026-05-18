import 'dart:math';
import '../data/level_model.dart';
import 'match_logic.dart';

class ProceduralLevelGenerator {
  static final Random _random = Random();

  static List<LevelModel> generateCampaign(int count) {
    return List.generate(count, (index) {
      final levelId = index + 1;
      final difficulty = index / (count - 1); // 0.0 to 1.0

      const int cols = 8;
      // rows выбираем из {9,10,11,12} рандомно, чтобы при генерации работала "симметрия обе" (x и y)
      final int rows = [9, 10, 11, 12][_random.nextInt(4)];

      // 1. Grid Generation (Symmetrical Holes/Islands)
      List<List<bool>> grid =
          List.generate(cols, (_) => List.filled(rows, true));
      // Choose symmetry type: 0: Vertical, 1: Horizontal, 2: Both
      int symmetryType = _random.nextInt(3);

      if (difficulty > 0.1 || levelId > 15) {
        int holeClusters = (difficulty * 5 + 1).toInt();
        for (int i = 0; i < holeClusters; i++) {
          // генерим в одной половине по X, и во всём диапазоне по Y — зеркалим потом
          int hx = _random.nextInt(cols ~/ 2); // 0..3
          int hy = _random.nextInt(rows);

          void removeCell(int x, int y) {
            if (x < 0 || x >= cols || y < 0 || y >= rows) return;
            grid[x][y] = false;
          }

          removeCell(hx, hy);

          // Vertical mirror (left-right in cols=8)
          if (symmetryType == 0 || symmetryType == 2) {
            removeCell(cols - 1 - hx, hy);
          }

          // Horizontal mirror (top-bottom in rows=9..12)
          if (symmetryType == 1 || symmetryType == 2) {
            removeCell(hx, rows - 1 - hy);
          }

          // Both
          if (symmetryType == 2) {
            removeCell(cols - 1 - hx, rows - 1 - hy);
          }
        }
      }

      // 2. Jelly and Rocks (Symmetrical)
      List<List<int>> jelly = List.generate(cols, (_) => List.filled(rows, 0));
      List<List<GemType?>> initialBoard =
          List.generate(cols, (_) => List.filled(rows, null));

      int jellyTotal = 0;
      int rockTotal = 0;

      if (difficulty > 0.03 || levelId > 10) {
        int patternComplexity = (difficulty * 10 + 2).toInt();
        for (int i = 0; i < patternComplexity; i++) {
          int rx =
              _random.nextInt(cols ~/ 2); // Only generate in one quadrant/half
          int ry = _random.nextInt(rows);

          void placeObstacle(int x, int y) {
            if (x < 0 || x >= cols || y < 0 || y >= rows) return;
            if (!grid[x][y]) return;

            // Decide between Jelly or Rock
            if (_random.nextDouble() < 0.7) {
              if (jelly[x][y] == 0) {
                jelly[x][y] = 1;
                jellyTotal++;
              }
            } else {
              if (initialBoard[x][y] == null) {
                initialBoard[x][y] = GemType.rock;
                rockTotal++;
              }
            }
          }

          // Apply symmetry
          placeObstacle(rx, ry);

          if (symmetryType == 0 || symmetryType == 2) {
            placeObstacle(cols - 1 - rx, ry); // Vertical mirror
          }
          if (symmetryType == 1 || symmetryType == 2) {
            placeObstacle(rx, rows - 1 - ry); // Horizontal mirror
          }
          if (symmetryType == 2) {
            placeObstacle(cols - 1 - rx, rows - 1 - ry); // Both
          }
        }
      } // 3. Balancing and Goals
      int moveLimit = (40 - (difficulty * 20)).toInt().clamp(15, 45);
      int baseScore = (800 + (difficulty * 6000)).toInt();

      List<LevelGoal> goals = [];

      // Always add Score Goal
      goals.add(LevelGoal(type: GoalType.score, targetValue: baseScore));

      // Obstacle Goals
      if (jellyTotal > 0) {
        goals
            .add(LevelGoal(type: GoalType.clearJelly, targetValue: jellyTotal));
      }
      if (rockTotal > 0) {
        goals
            .add(LevelGoal(type: GoalType.destroyRock, targetValue: rockTotal));
      }

      // Sequential Gem Goals
      if (levelId > 5) {
        // One gem goal, type changes every 5 levels
        int gemIdx = (levelId ~/ 5) % 6;
        goals.add(LevelGoal(
          type: GoalType.collectGem,
          gemType: GemType.values[gemIdx],
          targetValue: (20 + difficulty * 40).toInt(),
        ));
      }

      if (difficulty > 0.6) {
        // Add a second gem goal for high difficulty
        int gemIdx2 = (levelId ~/ 5 + 1) % 6;
        goals.add(LevelGoal(
          type: GoalType.collectGem,
          gemType: GemType.values[gemIdx2],
          targetValue: (15 + difficulty * 30).toInt(),
        ));
      }

      return LevelModel(
        id: levelId,
        name: 'Level $levelId',
        grid: grid,
        jellyGrid: jelly,
        initialBoard: initialBoard,
        moveLimit: moveLimit,
        star1Score: baseScore,
        star2Score: (baseScore * 1.5).toInt(),
        star3Score: baseScore * 2,
        goals: goals,
      );
    });
  }

  static void _fillRandom(List<List<int>> target, List<List<bool>> grid,
      int count, int Function(int, int) value) {
    int placed = 0;
    int attempts = 0;
    while (placed < count && attempts < 100) {
      int x = _random.nextInt(8);
      int y = _random.nextInt(8);
      if (grid[x][y] && target[x][y] == 0) {
        target[x][y] = value(x, y);
        placed++;
      }
      attempts++;
    }
  }

  static void _fillRandomBoard(List<List<GemType?>> target,
      List<List<bool>> grid, int count, GemType type) {
    int placed = 0;
    int attempts = 0;
    while (placed < count && attempts < 100) {
      int x = _random.nextInt(8);
      int y = _random.nextInt(8);
      if (grid[x][y] && target[x][y] == null) {
        target[x][y] = type;
        placed++;
      }
      attempts++;
    }
  }
}
