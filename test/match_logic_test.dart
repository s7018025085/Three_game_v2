import 'package:flutter_test/flutter_test.dart';

import 'package:three_game/data/level_model.dart';
import 'package:three_game/logic/match_logic.dart';

List<List<GemData?>> _buildBoard(int rows) {
  return List.generate(
    MatchLogic.cols,
    (x) => List.generate(
      rows,
      (y) => GemData(GemType.values[(x + y * 2) % 6]),
    ),
  );
}

void main() {
  test('creates a bomb for a T-shaped match', () {
    final board = _buildBoard(8);
    board[3][2] = GemData(GemType.red);
    board[3][3] = GemData(GemType.red);
    board[3][4] = GemData(GemType.red);
    board[2][3] = GemData(GemType.red);
    board[4][3] = GemData(GemType.red);

    final logic = MatchLogic(
      rows: board[0].length,
      savedBoard: board,
    );

    final result = logic.processMatches();

    expect(result.createdBonuses.values.single.modifier, GemModifier.bomb);
  });

  test('restores saved board and goal status', () {
    final board = _buildBoard(8);
    board[1][1] = GemData(
      GemType.purple,
      modifier: GemModifier.horizontalLine,
      health: 2,
    );

    final logic = MatchLogic(
      rows: board[0].length,
      savedBoard: board,
      levelGoals: [
        LevelGoal(type: GoalType.clearJelly, targetValue: 3),
      ],
      savedGoalStatus: const {0: 0},
    );

    expect(logic.board[1][1]!.modifier, GemModifier.horizontalLine);
    expect(logic.board[1][1]!.health, 2);
    expect(logic.areGoalsComplete, isTrue);
  });

  test('horizontal line + vertical line clears cross (row + column)', () {
    final board = _buildBoard(8);

    board[2][3] = GemData(GemType.red, modifier: GemModifier.horizontalLine);
    board[2][4] = GemData(GemType.green, modifier: GemModifier.verticalLine);

    final logic = MatchLogic(rows: board[0].length, savedBoard: board);

    final result = logic.processBonusCombo(2, 3, 2, 4);

    // cross => clears row y=3 and col x=2 (including intersection at (2,3))
    expect(logic.board[2][3], isNull);
    // Pick a cell that is not in row=3 and not in col=2
    expect(logic.board[3][4], isNotNull);
    expect(result.removedGems.contains(Point(2, 3)), isTrue);
  });

  test('bomb + horizontal line clears the whole row and bomb area', () {
    final board = _buildBoard(8);

    // Use a stable row
    const rowY = 3;

    final bombPos = Point(3, rowY);
    board[bombPos.x][bombPos.y] =
        GemData(GemType.red, modifier: GemModifier.bomb);

    // Horizontal line gem elsewhere on same row
    board[1][rowY] =
        GemData(GemType.green, modifier: GemModifier.horizontalLine);

    final logic = MatchLogic(rows: board[0].length, savedBoard: board);

    final result = logic.processBonusCombo(3, rowY, 1, rowY);

    // Whole row must be cleared (rowY)
    for (int x = 0; x < MatchLogic.cols; x++) {
      expect(logic.board[x][rowY], isNull,
          reason: 'Expected cell ($x,$rowY) to be cleared');
    }

    // And bomb area cells around bombPos (subset guaranteed to be within row too,
    // but we verify at least the center is cleared)
    expect(logic.board[bombPos.x][bombPos.y], isNull);
    expect(result.removedGems.contains(bombPos), isTrue);
  });

  test(
      'rainbow + horizontal line clears all targetType gems and the whole line',
      () {
    final board = _buildBoard(8);

    const rowY = 2;

    // Rainbow gem at (0,rowY) (rainbow target type decided by the other gem's type)
    board[0][rowY] = GemData(GemType.red, modifier: GemModifier.rainbow);

    // Horizontal line gem at (4,rowY) with type = green -> targetType should be green
    board[4][rowY] =
        GemData(GemType.green, modifier: GemModifier.horizontalLine);

    // Ensure there are some green gems somewhere else
    board[6][1] = GemData(GemType.green);
    board[2][7] = GemData(GemType.green);

    final logic = MatchLogic(rows: board[0].length, savedBoard: board);

    final result = logic.processBonusCombo(0, rowY, 4, rowY);

    // Whole line must be cleared
    for (int x = 0; x < MatchLogic.cols; x++) {
      expect(logic.board[x][rowY], isNull);
    }

    // TargetType greens must be cleared
    expect(logic.board[6][1], isNull);
    expect(logic.board[2][7], isNull);

    // rainbow cell should be cleared too (since line cleared)
    expect(result.removedGems.isNotEmpty, isTrue);
  });
}
