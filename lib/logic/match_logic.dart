import 'dart:math';
import '../data/level_model.dart';

enum GemType { red, green, blue, yellow, purple, orange, rock }

enum GemModifier { none, bomb, rainbow, horizontalLine, verticalLine }

class GemData {
  final GemType type;
  final GemModifier modifier;
  int health; // Used for rocks, default 1

  GemData(this.type, {this.modifier = GemModifier.none, this.health = 1});

  GemData copyWith({GemType? type, GemModifier? modifier, int? health}) {
    return GemData(
      type ?? this.type,
      modifier: modifier ?? this.modifier,
      health: health ?? this.health,
    );
  }
}

class Point {
  final int x, y;
  Point(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() => 'Point($x, $y)';
}

class DropEvent {
  final int x;
  final int fromY;
  final int toY;
  final GemData gem;
  DropEvent(this.x, this.fromY, this.toY, this.gem);
}

class MatchResult {
  final Set<Point> removedGems;
  final Map<Point, GemData> createdBonuses;
  final int score;

  MatchResult(this.removedGems, this.createdBonuses, this.score);
}

class MatchLogic {
  static const int cols = 8;

  final int rows;
  final Random _random = Random();

  late final List<List<GemData?>> board;
  late final List<List<int>> jellyBoard;
  late final List<List<bool>> grid;

  final List<LevelGoal> goals = [];
  final Map<int, int> goalStatus = {}; // Remaining / Collected

  MatchLogic({
    required this.rows,
    List<List<bool>>? grid,
    List<List<int>>? jelly,
    List<List<GemType?>>? initialBoard,
    List<LevelGoal>? levelGoals,
    List<List<GemData?>>? savedBoard,
    Map<int, int>? savedGoalStatus,
  })  : board = List.generate(cols, (_) => List.filled(rows, null)),
        jellyBoard = List.generate(cols, (_) => List.filled(rows, 0)),
        grid = List.generate(cols, (_) => List.filled(rows, true)) {
    if (grid != null) {
      for (int x = 0; x < cols; x++) {
        for (int y = 0; y < rows; y++) {
          this.grid[x][y] = grid[x][y];
        }
      }
    }
    if (jelly != null) {
      for (int x = 0; x < cols; x++) {
        for (int y = 0; y < rows; y++) {
          this.jellyBoard[x][y] = jelly[x][y];
        }
      }
    }

    if (levelGoals != null) {
      goals.addAll(levelGoals);
      for (int i = 0; i < goals.length; i++) {
        goalStatus[i] = goals[i].targetValue;
      }
    }

    if (savedGoalStatus != null) {
      goalStatus
        ..clear()
        ..addAll(savedGoalStatus);
    }

    if (savedBoard != null) {
      _restoreBoard(savedBoard);
    } else {
      _initializeBoard(initialBoard);
    }
  }

  bool get hasGoals => goals.isNotEmpty;
  bool get areGoalsComplete =>
      goals.isNotEmpty &&
      goalStatus.values.every((remaining) => remaining <= 0);

  List<Point> getBonusPositions() {
    List<Point> positions = [];
    for (int x = 0; x < cols; x++) {
      for (int y = 0; y < rows; y++) {
        if (_isActive(x, y) &&
            board[x][y] != null &&
            board[x][y]!.modifier != GemModifier.none) {
          positions.add(Point(x, y));
        }
      }
    }
    return positions;
  }

  Map<Point, GemData> convertRandomGemsToBonuses(int count) {
    Map<Point, GemData> converted = {};
    List<Point> candidates = [];
    for (int x = 0; x < cols; x++) {
      for (int y = 0; y < rows; y++) {
        if (_isActive(x, y) &&
            board[x][y] != null &&
            board[x][y]!.type != GemType.rock &&
            board[x][y]!.modifier == GemModifier.none) {
          candidates.add(Point(x, y));
        }
      }
    }

    candidates.shuffle(_random);
    int toConvert = min(count, candidates.length);
    for (int i = 0; i < toConvert; i++) {
      Point p = candidates[i];
      GemType type = board[p.x][p.y]!.type;
      GemModifier mod = _random.nextBool()
          ? GemModifier.bomb
          : (_random.nextBool()
              ? GemModifier.horizontalLine
              : GemModifier.verticalLine);
      board[p.x][p.y] = GemData(type, modifier: mod);
      converted[p] = board[p.x][p.y]!;
    }
    return converted;
  }

  MatchResult triggerBonusAt(Point p) {
    if (board[p.x][p.y] == null ||
        board[p.x][p.y]!.modifier == GemModifier.none) {
      return MatchResult({}, {}, 0);
    }
    Set<Point> toRemove = _processExplosions({p});
    _handleSideEffects(toRemove);
    int score = toRemove.length * 15;
    for (var pt in toRemove) _removeGem(pt.x, pt.y);
    _updateGoal(GoalType.score, score);
    return MatchResult(toRemove, {}, score);
  }

  bool _isActive(int x, int y) {
    if (x < 0 || x >= cols || y < 0 || y >= rows) return false;
    return grid[x][y];
  }

  void _initializeBoard(List<List<GemType?>>? initialBoard) {
    int attempts = 0;
    bool hasMoves = false;

    while (attempts < 10 && !hasMoves) {
      for (int x = 0; x < cols; x++) {
        for (int y = 0; y < rows; y++) {
          if (_isActive(x, y)) {
            if (initialBoard != null && initialBoard[x][y] != null) {
              final type = initialBoard[x][y]!;
              board[x][y] = GemData(type, health: type == GemType.rock ? 3 : 1);
            } else {
              board[x][y] = GemData(_getRandomGemType(x, y));
            }
          }
        }
      }

      // If no pre-placed rocks/initial board, check for moves.
      // If there's an initial board, we assume the designer knew what they were doing or it's an obstacle-heavy level.
      if (initialBoard == null) {
        hasMoves = hasPossibleMoves();
      } else {
        hasMoves = true; // Don't override designer's initial board
      }
      attempts++;
    }
  }

  void _restoreBoard(List<List<GemData?>> savedBoard) {
    for (int x = 0; x < cols; x++) {
      for (int y = 0; y < rows; y++) {
        final gem = savedBoard[x][y];
        board[x][y] = gem == null
            ? null
            : GemData(
                gem.type,
                modifier: gem.modifier,
                health: gem.health,
              );
      }
    }
  }

  GemType _getRandomGemType([int? x, int? y]) {
    GemType gem;
    do {
      // Exclude rock from random generation (only index 0..5)
      gem = GemType.values[_random.nextInt(GemType.values.length - 1)];
    } while (x != null && y != null && _causesInitialMatch(x, y, gem));
    return gem;
  }

  bool _causesInitialMatch(int x, int y, GemType type) {
    if (type == GemType.rock) return false;
    if (x >= 2 &&
        _isActive(x - 1, y) &&
        _isActive(x - 2, y) &&
        board[x - 1][y]?.type == type &&
        board[x - 2][y]?.type == type) {
      return true;
    }
    if (y >= 2 &&
        _isActive(x, y - 1) &&
        _isActive(x, y - 2) &&
        board[x][y - 1]?.type == type &&
        board[x][y - 2]?.type == type) {
      return true;
    }
    return false;
  }

  bool isBonusCombo(int x1, int y1, int x2, int y2) {
    GemData? g1 = board[x1][y1];
    GemData? g2 = board[x2][y2];
    if (g1 == null || g2 == null) return false;
    return g1.modifier != GemModifier.none && g2.modifier != GemModifier.none;
  }

  bool isRainbowSwap(int x1, int y1, int x2, int y2) {
    if (isBonusCombo(x1, y1, x2, y2)) return false;
    if (board[x1][y1]?.modifier == GemModifier.rainbow ||
        board[x2][y2]?.modifier == GemModifier.rainbow) {
      return true;
    }
    return false;
  }

  bool isValidSwap(int x1, int y1, int x2, int y2) {
    if (!_isActive(x1, y1) || !_isActive(x2, y2)) return false;
    if (board[x1][y1]?.type == GemType.rock ||
        board[x2][y2]?.type == GemType.rock) return false;

    int dx = (x1 - x2).abs();
    int dy = (y1 - y2).abs();
    if (dx + dy != 1) return false;

    if (isBonusCombo(x1, y1, x2, y2)) return true;
    if (isRainbowSwap(x1, y1, x2, y2)) return true;

    _swap(x1, y1, x2, y2);
    bool hasMatch = _findBasicMatches().isNotEmpty;
    _swap(x1, y1, x2, y2);

    return hasMatch;
  }

  void _swap(int x1, int y1, int x2, int y2) {
    GemData? temp = board[x1][y1];
    board[x1][y1] = board[x2][y2];
    board[x2][y2] = temp;
  }

  void executeSwap(int x1, int y1, int x2, int y2) {
    _swap(x1, y1, x2, y2);
  }

  Set<Set<Point>> _findBasicMatches() {
    Set<Set<Point>> allMatches = {};

    // Horizontal
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols - 2; x++) {
        if (!_isActive(x, y)) continue;
        GemType? type = board[x][y]?.type;
        if (type == null || type == GemType.rock) continue;
        if (_isActive(x + 1, y) &&
            board[x + 1][y]?.type == type &&
            _isActive(x + 2, y) &&
            board[x + 2][y]?.type == type) {
          Set<Point> match = {Point(x, y), Point(x + 1, y), Point(x + 2, y)};
          int nx = x + 3;
          while (nx < cols && _isActive(nx, y) && board[nx][y]?.type == type) {
            match.add(Point(nx, y));
            nx++;
          }
          allMatches.add(match);
          x = nx - 1;
        }
      }
    }

    // Vertical
    for (int x = 0; x < cols; x++) {
      for (int y = 0; y < rows - 2; y++) {
        if (!_isActive(x, y)) continue;
        GemType? type = board[x][y]?.type;
        if (type == null || type == GemType.rock)
          continue; // Rocks are not matchable
        if (_isActive(x, y + 1) &&
            board[x][y + 1]?.type == type &&
            _isActive(x, y + 2) &&
            board[x][y + 2]?.type == type) {
          Set<Point> match = {Point(x, y), Point(x, y + 1), Point(x, y + 2)};
          int ny = y + 3;
          while (ny < rows && _isActive(x, ny) && board[x][ny]?.type == type) {
            match.add(Point(x, ny));
            ny++;
          }
          allMatches.add(match);
          y = ny - 1;
        }
      }
    }

    return _mergeIntersectingMatches(allMatches);
  }

  Set<Set<Point>> _mergeIntersectingMatches(Set<Set<Point>> matches) {
    List<Set<Point>> merged = [];
    for (var match in matches) {
      bool found = false;
      for (var existing in merged) {
        if (existing.intersection(match).isNotEmpty) {
          existing.addAll(match);
          found = true;
          break;
        }
      }
      if (!found) merged.add(Set.from(match));
    }
    return merged.toSet();
  }

  bool _isStraightMatch(Set<Point> match) {
    final sameRow = match.every((point) => point.y == match.first.y);
    final sameColumn = match.every((point) => point.x == match.first.x);
    return sameRow || sameColumn;
  }

  MatchResult processMatches({Point? swapTarget}) {
    Set<Set<Point>> matches = _findBasicMatches();
    Set<Point> toRemove = {};
    Map<Point, GemData> newBonuses = {};
    int score = 0;

    for (var match in matches) {
      toRemove.addAll(match);

      Point bonusPos = match.first;
      if (swapTarget != null && match.contains(swapTarget)) {
        bonusPos = swapTarget;
      } else {
        List<Point> pts = match.toList();
        bonusPos = pts[pts.length ~/ 2];
      }

      GemType matchType = board[match.first.x][match.first.y]!.type;

      if (match.length >= 5) {
        newBonuses[bonusPos] = GemData(
          matchType,
          modifier:
              _isStraightMatch(match) ? GemModifier.rainbow : GemModifier.bomb,
        );
      } else if (match.length == 4) {
        // Detect if horizontal or vertical to decide line bonus type
        int minX = match.map((p) => p.x).reduce(min);
        int maxX = match.map((p) => p.x).reduce(max);
        int minY = match.map((p) => p.y).reduce(min);
        int maxY = match.map((p) => p.y).reduce(max);

        if (maxX - minX > maxY - minY) {
          // Horizontal match creates horizontal line bonus (clears row)
          newBonuses[bonusPos] =
              GemData(matchType, modifier: GemModifier.horizontalLine);
        } else {
          // Vertical match creates vertical line bonus (clears column)
          newBonuses[bonusPos] =
              GemData(matchType, modifier: GemModifier.verticalLine);
        }
      }
    }

    Set<Point> finalRemove = _processExplosions(toRemove);

    // Clear Jelly and Damage adjacent Rocks
    _handleSideEffects(finalRemove);

    score += finalRemove.length * 10;

    for (var p in finalRemove) {
      _removeGem(p.x, p.y);
    }

    // Also update score goals
    _updateGoal(GoalType.score, score);

    newBonuses.forEach((p, gem) {
      board[p.x][p.y] = gem;
      finalRemove.remove(p);
    });

    return MatchResult(finalRemove, newBonuses, score);
  }

  MatchResult processRainbowSwap(int x1, int y1, int x2, int y2) {
    GemData? gem1 = board[x1][y1];
    GemData? gem2 = board[x2][y2];

    GemType targetType = GemType.red;
    Point rainbowPos = Point(x1, y1);

    if (gem1?.modifier == GemModifier.rainbow && gem2 != null) {
      targetType = gem2.type;
      rainbowPos = Point(x1, y1);
    } else if (gem2?.modifier == GemModifier.rainbow && gem1 != null) {
      targetType = gem1.type;
      rainbowPos = Point(x2, y2);
    }

    Set<Point> toRemove = {rainbowPos};
    for (int x = 0; x < cols; x++) {
      for (int y = 0; y < rows; y++) {
        if (_isActive(x, y) && board[x][y]?.type == targetType) {
          toRemove.add(Point(x, y));
        }
      }
    }

    Set<Point> finalRemove = _processExplosions(toRemove);
    _handleSideEffects(finalRemove);

    for (var p in finalRemove) {
      final gem = board[p.x][p.y];
      final isRainbowCrystal =
          p == rainbowPos && gem?.modifier == GemModifier.rainbow;
      _removeGem(
        p.x,
        p.y,
        collectAsType: isRainbowCrystal ? targetType : null,
      );
    }

    _updateGoal(GoalType.score, finalRemove.length * 10);

    return MatchResult(finalRemove, {}, finalRemove.length * 10);
  }

  void _removeGem(int x, int y, {GemType? collectAsType}) {
    final gem = board[x][y];
    if (gem == null) return;

    if (gem.type == GemType.rock) {
      gem.health--;
      if (gem.health <= 0) {
        board[x][y] = null;
        _updateGoal(GoalType.destroyRock, 1);
      }
    } else {
      _updateGoal(
        GoalType.collectGem,
        1,
        gemType: collectAsType ?? gem.type,
      );
      board[x][y] = null;
    }
  }

  MatchResult processBonusCombo(int x1, int y1, int x2, int y2) {
    GemData? g1 = board[x1][y1];
    GemData? g2 = board[x2][y2];

    // TEMP DEBUG: чтобы понять, какие модификаторы реально срабатывают при "двух ракетах"
    // (важно, т.к. UI-движок может попадать в другой кейс, чем ожидается)
    // ignore: avoid_print
    print(
      'processBonusCombo at ($x1,$y1)=${g1?.modifier} + ($x2,$y2)=${g2?.modifier}',
    );

    Set<Point> toRemove = {Point(x1, y1), Point(x2, y2)};
    int score = 0;

    if (g1?.modifier == GemModifier.rainbow &&
        g2?.modifier == GemModifier.rainbow) {
      // Rainbow + Rainbow: clear everything
      for (int x = 0; x < cols; x++) {
        for (int y = 0; y < rows; y++) {
          if (_isActive(x, y) && board[x][y] != null) toRemove.add(Point(x, y));
        }
      }
      score += toRemove.length * 20;
    } else if (g1?.modifier == GemModifier.bomb &&
        g2?.modifier == GemModifier.bomb) {
      // Bomb + Bomb: 5x5 explosion
      int cx = (x1 + x2) ~/ 2;
      int cy = (y1 + y2) ~/ 2;
      for (int dx = -2; dx <= 2; dx++) {
        for (int dy = -2; dy <= 2; dy++) {
          int nx = cx + dx, ny = cy + dy;
          if (_isActive(nx, ny) && board[nx][ny] != null)
            toRemove.add(Point(nx, ny));
        }
      }
      toRemove.addAll(_processExplosions(toRemove));
      _handleSideEffects(toRemove);
      score += toRemove.length * 15;
    } else if ((g1?.modifier == GemModifier.horizontalLine &&
            g2?.modifier == GemModifier.verticalLine) ||
        (g1?.modifier == GemModifier.verticalLine &&
            g2?.modifier == GemModifier.horizontalLine)) {
      // Horizontal line + Vertical line: cross clear (row + column, including intersection)
      final int rowY = g1?.modifier == GemModifier.horizontalLine ? y1 : y2;
      final int colX = g1?.modifier == GemModifier.verticalLine ? x1 : x2;

      for (int x = 0; x < cols; x++) {
        if (_isActive(x, rowY) && board[x][rowY] != null) {
          toRemove.add(Point(x, rowY));
        }
      }
      for (int y = 0; y < rows; y++) {
        if (_isActive(colX, y) && board[colX][y] != null) {
          toRemove.add(Point(colX, y));
        }
      }

      _handleSideEffects(toRemove);
      score += toRemove.length * 15;
    } else if (g1?.modifier == GemModifier.horizontalLine &&
        g2?.modifier == GemModifier.horizontalLine) {
      // Two horizontals: treat as cross clear => row(y1) + col(x2)
      for (int x = 0; x < cols; x++) {
        if (_isActive(x, y1) && board[x][y1] != null) {
          toRemove.add(Point(x, y1));
        }
      }
      for (int y = 0; y < rows; y++) {
        if (_isActive(x2, y) && board[x2][y] != null) {
          toRemove.add(Point(x2, y));
        }
      }
      _handleSideEffects(toRemove);
      score += toRemove.length * 15;
    } else if (g1?.modifier == GemModifier.verticalLine &&
        g2?.modifier == GemModifier.verticalLine) {
      // Two verticals: treat as cross clear => col(x1) + row(y2)
      for (int y = 0; y < rows; y++) {
        if (_isActive(x1, y) && board[x1][y] != null) {
          toRemove.add(Point(x1, y));
        }
      }
      for (int x = 0; x < cols; x++) {
        if (_isActive(x, y2) && board[x][y2] != null) {
          toRemove.add(Point(x, y2));
        }
      }
      _handleSideEffects(toRemove);
      score += toRemove.length * 15;
    } else if ((g1?.modifier == GemModifier.bomb &&
            g2?.modifier == GemModifier.horizontalLine) ||
        (g1?.modifier == GemModifier.horizontalLine &&
            g2?.modifier == GemModifier.bomb)) {
      // Bomb + Horizontal line: clear whole row + bomb explosion (merged)
      final int rowY = g1?.modifier == GemModifier.horizontalLine ? y1 : y2;
      final Point bombPos =
          g1?.modifier == GemModifier.bomb ? Point(x1, y1) : Point(x2, y2);

      for (int x = 0; x < cols; x++) {
        if (_isActive(x, rowY) && board[x][rowY] != null) {
          toRemove.add(Point(x, rowY));
        }
      }

      // Include bomb explosion area as well
      toRemove.addAll(_processExplosions({bombPos}));
      _handleSideEffects(toRemove);
      score += toRemove.length * 15;
    } else if ((g1?.modifier == GemModifier.bomb &&
            g2?.modifier == GemModifier.verticalLine) ||
        (g1?.modifier == GemModifier.verticalLine &&
            g2?.modifier == GemModifier.bomb)) {
      // Bomb + Vertical line: clear whole column + bomb explosion (merged)
      final int colX = g1?.modifier == GemModifier.verticalLine ? x1 : x2;
      final Point bombPos =
          g1?.modifier == GemModifier.bomb ? Point(x1, y1) : Point(x2, y2);

      for (int y = 0; y < rows; y++) {
        if (_isActive(colX, y) && board[colX][y] != null) {
          toRemove.add(Point(colX, y));
        }
      }

      toRemove.addAll(_processExplosions({bombPos}));
      _handleSideEffects(toRemove);
      score += toRemove.length * 15;
    } else if ((g1?.modifier == GemModifier.rainbow &&
            (g2?.modifier == GemModifier.horizontalLine ||
                g2?.modifier == GemModifier.verticalLine)) ||
        (g2?.modifier == GemModifier.rainbow &&
            (g1?.modifier == GemModifier.horizontalLine ||
                g1?.modifier == GemModifier.verticalLine))) {
      // Rainbow + line: clear all gems of line-type gem's color + clear the line
      // Find which is rainbow and which is line
      final GemData? lineGem = (g1?.modifier == GemModifier.rainbow) ? g2 : g1;
      final GemModifier? lineMod = lineGem?.modifier;
      final GemType targetType = lineGem!.type;

      // 1) Rainbow clears all gems of targetType
      for (int x = 0; x < cols; x++) {
        for (int y = 0; y < rows; y++) {
          if (_isActive(x, y) && board[x][y]?.type == targetType) {
            toRemove.add(Point(x, y));
          }
        }
      }

      // 2) Also clear the whole line (row/col) indicated by the line modifier
      if (lineMod == GemModifier.horizontalLine) {
        final int rowY = (g1?.modifier == GemModifier.rainbow) ? y2 : y1;
        for (int x = 0; x < cols; x++) {
          if (_isActive(x, rowY) && board[x][rowY] != null) {
            toRemove.add(Point(x, rowY));
          }
        }
      } else if (lineMod == GemModifier.verticalLine) {
        final int colX = (g1?.modifier == GemModifier.rainbow) ? x2 : x1;
        for (int y = 0; y < rows; y++) {
          if (_isActive(colX, y) && board[colX][y] != null) {
            toRemove.add(Point(colX, y));
          }
        }
      }

      _handleSideEffects(toRemove);
      score += toRemove.length * 15;
    } else {
      // Rainbow + Bomb: convert all of bomb's color to bombs, then explode
      GemType targetType =
          (g1?.modifier == GemModifier.rainbow) ? g2!.type : g1!.type;
      for (int x = 0; x < cols; x++) {
        for (int y = 0; y < rows; y++) {
          if (_isActive(x, y) && board[x][y]?.type == targetType) {
            board[x][y] = GemData(targetType, modifier: GemModifier.bomb);
            toRemove.add(Point(x, y));
          }
        }
      }
      toRemove.addAll(_processExplosions(toRemove));
      _handleSideEffects(toRemove);
      score += toRemove.length * 15;
    }

    for (var p in toRemove) _removeGem(p.x, p.y);

    _updateGoal(GoalType.score, score);

    return MatchResult(toRemove, {}, score);
  }

  void _handleSideEffects(Set<Point> clearedPoints) {
    Set<Point> rocksToDamage = {};
    for (var p in clearedPoints) {
      // Clear jelly
      if (jellyBoard[p.x][p.y] > 0) {
        jellyBoard[p.x][p.y]--;
        _updateGoal(GoalType.clearJelly, 1);
      }
      // Find adjacent rocks
      for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
          if ((dx == 0) == (dy == 0)) continue; // Only cardinal directions
          int nx = p.x + dx, ny = p.y + dy;
          if (_isActive(nx, ny) && board[nx][ny]?.type == GemType.rock) {
            rocksToDamage.add(Point(nx, ny));
          }
        }
      }
    }

    // Apply damage to rocks
    for (var p in rocksToDamage) {
      final rock = board[p.x][p.y];
      if (rock != null) {
        rock.health--;
        if (rock.health <= 0) {
          board[p.x][p.y] = null;
          clearedPoints.add(p); // Add to cleared for scoring/effects
          _updateGoal(GoalType.destroyRock, 1);
        }
      }
    }
  }

  void _updateGoal(GoalType type, int amount, {GemType? gemType}) {
    for (int i = 0; i < goals.length; i++) {
      final g = goals[i];
      if (g.type == type && (gemType == null || g.gemType == gemType)) {
        goalStatus[i] = (goalStatus[i]! - amount).clamp(0, 999999);
      }
    }
  }

  Set<Point> _processExplosions(Set<Point> initial) {
    Set<Point> processed = {};
    List<Point> queue = initial.toList();

    while (queue.isNotEmpty) {
      Point p = queue.removeAt(0);
      if (processed.contains(p)) continue;
      processed.add(p);

      GemData? gem = board[p.x][p.y];
      if (gem?.modifier == GemModifier.bomb) {
        for (int dx = -1; dx <= 1; dx++) {
          for (int dy = -1; dy <= 1; dy++) {
            int nx = p.x + dx, ny = p.y + dy;
            if (_isActive(nx, ny)) {
              Point np = Point(nx, ny);
              if (!processed.contains(np) &&
                  !queue.contains(np) &&
                  board[nx][ny] != null) {
                queue.add(np);
              }
            }
          }
        }
      } else if (gem?.modifier == GemModifier.horizontalLine) {
        // Clear entire row
        for (int x = 0; x < cols; x++) {
          if (_isActive(x, p.y)) {
            Point np = Point(x, p.y);
            if (!processed.contains(np) &&
                !queue.contains(np) &&
                board[x][p.y] != null) {
              queue.add(np);
            }
          }
        }
      } else if (gem?.modifier == GemModifier.verticalLine) {
        // Clear entire column
        for (int y = 0; y < rows; y++) {
          if (_isActive(p.x, y)) {
            Point np = Point(p.x, y);
            if (!processed.contains(np) &&
                !queue.contains(np) &&
                board[p.x][y] != null) {
              queue.add(np);
            }
          }
        }
      }
    }
    return processed;
  }

  /// Applies gravity per contiguous column segment (holes act as walls).
  List<DropEvent> applyGravity() {
    final List<DropEvent> drops = [];

    for (int x = 0; x < cols; x++) {
      // Process column from bottom to top, tracking the lowest empty slot.
      // Reset fill position when a hole is encountered.
      int fillY = -1; // -1 means "not looking for empty slot yet"

      for (int y = rows - 1; y >= 0; y--) {
        if (!_isActive(x, y)) {
          // Hole — stop the current segment
          fillY = -1;
          continue;
        }

        if (board[x][y] == null) {
          // Empty active cell — record it as the fill target if we haven't yet
          if (fillY == -1) fillY = y;
        } else {
          // Gem exists — if there is an empty slot below it, fall there
          if (fillY != -1 && fillY > y) {
            drops.add(DropEvent(x, y, fillY, board[x][y]!));
            board[x][fillY] = board[x][y];
            board[x][y] = null;
            // After moving a gem to fillY, the slot at fillY is now full.
            // The next available empty slot in this segment is fillY - 1.
            fillY--;
          }
          // If fillY == -1 or fillY <= y, gem is already at the bottom — don't move
        }
      }
    }

    return drops;
  }

  /// Fills empty active cells with new random gems, spawning from above.
  List<DropEvent> fillEmpty() {
    final List<DropEvent> newGems = [];

    for (int x = 0; x < cols; x++) {
      // Iterate top-to-bottom, counting empty slots per segment
      // so gems spawn sequentially above the board.
      int spawnOffset = 0;
      int prevHoleY =
          -1; // y of the last hole (top boundary of current segment)

      for (int y = 0; y < rows; y++) {
        if (!_isActive(x, y)) {
          // Hit a hole — reset spawn offset for next segment
          spawnOffset = 0;
          prevHoleY = y;
          continue;
        }

        if (board[x][y] == null) {
          final newGem = GemData(_getRandomGemType());
          board[x][y] = newGem;
          // fromY: spawn above the current segment (above prevHoleY or above 0)
          final segmentTop = prevHoleY + 1; // first active row in segment
          final fromY =
              segmentTop - 1 - spawnOffset; // goes further above board
          newGems.add(DropEvent(x, fromY, y, newGem));
          spawnOffset++;
        }
      }
    }

    return newGems;
  }

  /// Checks if any valid moves exist on the board.
  bool hasPossibleMoves() {
    for (int x = 0; x < cols; x++) {
      for (int y = 0; y < rows; y++) {
        if (!_isActive(x, y) || board[x][y] == null) continue;

        // Rainbows can always be swapped
        if (board[x][y]!.modifier == GemModifier.rainbow) return true;

        // Try swapping right
        if (x < cols - 1 && _isActive(x + 1, y) && board[x + 1][y] != null) {
          if (_checkPotentialMatch(x, y, x + 1, y)) return true;
        }

        // Try swapping down
        if (y < rows - 1 && _isActive(x, y + 1) && board[x][y + 1] != null) {
          if (_checkPotentialMatch(x, y, x, y + 1)) return true;
        }
      }
    }
    return false;
  }

  bool _checkPotentialMatch(int x1, int y1, int x2, int y2) {
    // Temporary swap
    final g1 = board[x1][y1];
    final g2 = board[x2][y2];

    if (g1?.modifier != GemModifier.none && g2?.modifier != GemModifier.none) {
      return true;
    }
    // If either is a rainbow, it's a move
    if (g1?.modifier == GemModifier.rainbow ||
        g2?.modifier == GemModifier.rainbow) return true;
    // If both are bombs, it's a move
    if (g1?.modifier == GemModifier.bomb && g2?.modifier == GemModifier.bomb)
      return true;

    board[x1][y1] = g2;
    board[x2][y2] = g1;

    bool match = _hasMatchAt(x1, y1) || _hasMatchAt(x2, y2);

    // Swap back
    board[x1][y1] = g1;
    board[x2][y2] = g2;

    return match;
  }

  bool _hasMatchAt(int x, int y) {
    final type = board[x][y]?.type;
    if (type == null) return false;

    // Horizontal
    int hCount = 1;
    // Right
    for (int i = x + 1;
        i < cols && _isActive(i, y) && board[i][y]?.type == type;
        i++) hCount++;
    // Left
    for (int i = x - 1;
        i >= 0 && _isActive(i, y) && board[i][y]?.type == type;
        i--) hCount++;
    if (hCount >= 3) return true;

    // Vertical
    int vCount = 1;
    // Down
    for (int i = y + 1;
        i < rows && _isActive(x, i) && board[x][i]?.type == type;
        i++) vCount++;
    // Up
    for (int i = y - 1;
        i >= 0 && _isActive(x, i) && board[x][i]?.type == type;
        i--) vCount++;
    if (vCount >= 3) return true;

    return false;
  }

  /// Shuffles the board until at least one move is possible and no matches exist.
  void shuffleBoard() {
    final List<GemData> allGems = [];
    for (int x = 0; x < cols; x++) {
      for (int y = 0; y < rows; y++) {
        if (_isActive(x, y) && board[x][y] != null) {
          allGems.add(board[x][y]!);
        }
      }
    }

    allGems.shuffle(_random);

    int attempts = 0;
    while (attempts < 100) {
      final List<GemData> workingSet = List.from(allGems)..shuffle(_random);
      int gemIdx = 0;

      // Clear board
      for (int x = 0; x < cols; x++) {
        for (int y = 0; y < rows; y++) {
          if (_isActive(x, y)) board[x][y] = null;
        }
      }

      // Try filling without creating matches
      bool failed = false;
      for (int y = 0; y < rows; y++) {
        for (int x = 0; x < cols; x++) {
          if (_isActive(x, y)) {
            // We need to find a gem that doesn't create a match here
            bool found = false;
            for (int i = gemIdx; i < workingSet.length; i++) {
              if (!_causesInitialMatch(x, y, workingSet[i].type)) {
                // Swap it to the current position
                final temp = workingSet[gemIdx];
                workingSet[gemIdx] = workingSet[i];
                workingSet[i] = temp;

                board[x][y] = workingSet[gemIdx];
                gemIdx++;
                found = true;
                break;
              }
            }
            if (!found) {
              failed = true;
              break;
            }
          }
        }
        if (failed) break;
      }

      if (!failed && hasPossibleMoves()) {
        return; // Success
      }
      attempts++;
    }

    // If we can't find a no-match shuffle with moves, just force a random shuffle as fallback
    _initializeBoard(null);
  }

  List<List<SavedGemState?>> exportBoardState() {
    return List.generate(
      cols,
      (x) => List.generate(
        rows,
        (y) {
          final gem = board[x][y];
          return gem == null ? null : SavedGemState.fromGemData(gem);
        },
      ),
    );
  }

  List<List<int>> exportJellyState() {
    return jellyBoard.map((column) => List<int>.from(column)).toList();
  }

  Map<int, int> exportGoalStatus() => Map<int, int>.from(goalStatus);
}
