import '../data/level_model.dart';
import '../logic/match_logic.dart';

const String jellyTileAssetPath = 'assets/images/jelly.png';
const String rockTileAssetPath = 'assets/images/rock_full.png';
const String rainbowGemAssetPath = 'assets/images/gem_rainbow.png';

String gemAssetPath(GemType type) {
  switch (type) {
    case GemType.red:
      return 'assets/images/gem_red.png';
    case GemType.green:
      return 'assets/images/gem_green.png';
    case GemType.blue:
      return 'assets/images/gem_blue.png';
    case GemType.yellow:
      return 'assets/images/gem_yellow.png';
    case GemType.purple:
      return 'assets/images/gem_purple.png';
    case GemType.orange:
      return 'assets/images/gem_orange.png';
    case GemType.rock:
      return rockTileAssetPath;
  }
}

String goalAssetPath(LevelGoal goal) {
  switch (goal.type) {
    case GoalType.collectGem:
      return goal.gemType == null
          ? rainbowGemAssetPath
          : gemAssetPath(goal.gemType!);
    case GoalType.clearJelly:
      return jellyTileAssetPath;
    case GoalType.destroyRock:
      return rockTileAssetPath;
    case GoalType.score:
      return 'assets/images/gem_yellow.png';
  }
}
