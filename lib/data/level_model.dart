import 'dart:convert';
import '../logic/match_logic.dart';

enum GoalType { collectGem, clearJelly, destroyRock, score }

class LevelGoal {
  final GoalType type;
  final GemType? gemType;
  final int targetValue;

  LevelGoal({required this.type, this.gemType, required this.targetValue});

  Map<String, dynamic> toJson() => {
        'type': type.index,
        'gemType': gemType?.index ?? -1,
        'targetValue': targetValue,
      };

  factory LevelGoal.fromJson(Map<String, dynamic> json) => LevelGoal(
        type: GoalType.values[json['type'] as int],
        gemType: (json['gemType'] as int) == -1
            ? null
            : GemType.values[json['gemType'] as int],
        targetValue: json['targetValue'] as int,
      );
}

/// Represents a single level's configuration
class LevelModel {
  final int id;
  final List<List<bool>> grid; // grid[x][y] = true means active cell
  final List<List<int>> jellyGrid; // 0=none, 1=jelly, 2=double jelly
  final List<List<GemType?>>
      initialBoard; // For pre-placed rocks or specific gems
  final int moveLimit;
  final int star1Score;
  final int star2Score;
  final int star3Score;
  final String name;
  final List<LevelGoal> goals;

  const LevelModel({
    required this.id,
    required this.grid,
    this.jellyGrid = const [],
    this.initialBoard = const [],
    required this.moveLimit,
    required this.star1Score,
    required this.star2Score,
    required this.star3Score,
    required this.name,
    this.goals = const [],
  });

  bool isCellActive(int x, int y) {
    final int cols = grid.length;
    final int rows = grid.isNotEmpty ? grid[0].length : 0;

    if (x < 0 || x >= cols || y < 0 || y >= rows) return false;
    return grid[x][y];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'grid': grid.map((col) => col.map((v) => v ? 1 : 0).toList()).toList(),
        'jellyGrid': jellyGrid.isEmpty
            ? List.generate(
                grid.length,
                (_) => List.filled(grid.isNotEmpty ? grid[0].length : 0, 0),
              )
            : jellyGrid,
        'initialBoard': initialBoard.isEmpty
            ? List.generate(
                grid.length,
                (_) => List.filled(grid.isNotEmpty ? grid[0].length : 0, -1),
              )
            : initialBoard
                .map((col) => col.map((v) => v?.index ?? -1).toList())
                .toList(),
        'moveLimit': moveLimit,
        'star1Score': star1Score,
        'star2Score': star2Score,
        'star3Score': star3Score,
        'name': name,
        'goals': goals.map((g) => g.toJson()).toList(),
      };

  factory LevelModel.fromJson(Map<String, dynamic> json) => LevelModel(
        id: json['id'] as int,
        grid: (json['grid'] as List)
            .map((col) => (col as List).map((v) => v == 1).toList())
            .toList(),
        jellyGrid: (json['jellyGrid'] as List?)
                ?.map((col) => (col as List).map((v) => v as int).toList())
                .toList() ??
            List.generate(
              (json['grid'] as List).length,
              (x) => List.filled(
                ((json['grid'] as List)[x] as List).length,
                0,
              ),
            ),
        initialBoard: (json['initialBoard'] as List?)
                ?.map((col) => (col as List).map((v) {
                      final idx = v as int;
                      return idx == -1 ? null : GemType.values[idx];
                    }).toList())
                .toList() ??
            List.generate(
              (json['grid'] as List).length,
              (x) => List.filled(
                ((json['grid'] as List)[x] as List).length,
                null,
              ),
            ),
        moveLimit: json['moveLimit'] as int,
        star1Score: json['star1Score'] as int,
        star2Score: json['star2Score'] as int,
        star3Score: json['star3Score'] as int,
        name: json['name'] as String,
        goals: (json['goals'] as List?)
                ?.map((g) => LevelGoal.fromJson(g as Map<String, dynamic>))
                .toList() ??
            [],
      );

  String toJsonString() => jsonEncode(toJson());
  factory LevelModel.fromJsonString(String s) =>
      LevelModel.fromJson(jsonDecode(s));
}

/// Stores player progress for a single level
class LevelProgress {
  final int levelId;
  final int bestScore;
  final int starsEarned;
  final bool isUnlocked;

  const LevelProgress({
    required this.levelId,
    required this.bestScore,
    required this.starsEarned,
    required this.isUnlocked,
  });

  LevelProgress copyWith(
          {int? bestScore, int? starsEarned, bool? isUnlocked}) =>
      LevelProgress(
        levelId: levelId,
        bestScore: bestScore ?? this.bestScore,
        starsEarned: starsEarned ?? this.starsEarned,
        isUnlocked: isUnlocked ?? this.isUnlocked,
      );

  Map<String, dynamic> toJson() => {
        'levelId': levelId,
        'bestScore': bestScore,
        'starsEarned': starsEarned,
        'isUnlocked': isUnlocked,
      };

  factory LevelProgress.fromJson(Map<String, dynamic> json) => LevelProgress(
        levelId: json['levelId'] as int,
        bestScore: json['bestScore'] as int,
        starsEarned: json['starsEarned'] as int,
        isUnlocked: json['isUnlocked'] as bool,
      );

  String toJsonString() => jsonEncode(toJson());
  factory LevelProgress.fromJsonString(String s) =>
      LevelProgress.fromJson(jsonDecode(s));
}

class SavedGemState {
  final int typeIndex;
  final int modifierIndex;
  final int health;

  const SavedGemState({
    required this.typeIndex,
    required this.modifierIndex,
    required this.health,
  });

  factory SavedGemState.fromGemData(GemData gem) => SavedGemState(
        typeIndex: gem.type.index,
        modifierIndex: gem.modifier.index,
        health: gem.health,
      );

  GemData toGemData() => GemData(
        GemType.values[typeIndex],
        modifier: GemModifier.values[modifierIndex],
        health: health,
      );

  Map<String, dynamic> toJson() => {
        'typeIndex': typeIndex,
        'modifierIndex': modifierIndex,
        'health': health,
      };

  factory SavedGemState.fromJson(Map<String, dynamic> json) => SavedGemState(
        typeIndex: json['typeIndex'] as int,
        modifierIndex: json['modifierIndex'] as int,
        health: json['health'] as int,
      );
}

/// State of an in-progress game session
class SavedGameState {
  final LevelModel level;
  final int score;
  final int movesLeft;
  final bool isCampaignLevel;
  final List<List<SavedGemState?>> board;
  final List<List<int>> jellyGrid;
  final Map<int, int> goalStatus;

  const SavedGameState({
    required this.level,
    required this.score,
    required this.movesLeft,
    required this.isCampaignLevel,
    required this.board,
    required this.jellyGrid,
    required this.goalStatus,
  });

  int get levelId => level.id;

  Map<String, dynamic> toJson() => {
        'level': level.toJson(),
        'score': score,
        'movesLeft': movesLeft,
        'isCampaignLevel': isCampaignLevel,
        'board': board
            .map(
              (col) => col
                  .map((cell) => cell == null ? null : cell.toJson())
                  .toList(),
            )
            .toList(),
        'jellyGrid': jellyGrid,
        'goalStatus': goalStatus.map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      };

  factory SavedGameState.fromJson(Map<String, dynamic> json) => SavedGameState(
        level: LevelModel.fromJson(json['level'] as Map<String, dynamic>),
        score: json['score'] as int,
        movesLeft: json['movesLeft'] as int,
        isCampaignLevel: json['isCampaignLevel'] as bool,
        board: (json['board'] as List)
            .map(
              (col) => (col as List)
                  .map(
                    (cell) => cell == null
                        ? null
                        : SavedGemState.fromJson(
                            cell as Map<String, dynamic>,
                          ),
                  )
                  .toList(),
            )
            .toList(),
        jellyGrid: (json['jellyGrid'] as List)
            .map((col) => (col as List).map((cell) => cell as int).toList())
            .toList(),
        goalStatus: (json['goalStatus'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(int.parse(key), value as int),
        ),
      );

  String toJsonString() => jsonEncode(toJson());
  factory SavedGameState.fromJsonString(String s) =>
      SavedGameState.fromJson(jsonDecode(s));
}
