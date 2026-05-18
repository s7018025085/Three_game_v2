import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'level_model.dart';

class GameRepository {
  static const String _progressPrefix = 'level_progress_';
  static const String _savedGameKey = 'saved_game';
  static const String _campaignLevelsKey = 'campaign_levels_v1';
  static const String _customLevelsKey = 'custom_levels_v1';

  static GameRepository? _instance;
  static GameRepository get instance => _instance ??= GameRepository._();
  GameRepository._();

  // ──────────────────────────────────── Level Progress ────────────────────

  Future<LevelProgress> getLevelProgress(int levelId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_progressPrefix$levelId');
    if (raw == null) {
      return LevelProgress(
        levelId: levelId,
        bestScore: 0,
        starsEarned: 0,
        isUnlocked: levelId == 1,
      );
    }
    return LevelProgress.fromJsonString(raw);
  }

  Future<Map<int, LevelProgress>> getAllProgress(int totalLevels) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<int, LevelProgress> result = {};
    for (int i = 1; i <= totalLevels; i++) {
      final raw = prefs.getString('$_progressPrefix$i');
      if (raw != null) {
        result[i] = LevelProgress.fromJsonString(raw);
      } else {
        result[i] = LevelProgress(
          levelId: i,
          bestScore: 0,
          starsEarned: 0,
          isUnlocked: i == 1,
        );
      }
    }
    return result;
  }

  Future<Map<int, LevelProgress>> getProgressForLevelIds(
    Iterable<int> levelIds, {
    bool unlockedByDefault = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<int, LevelProgress> result = {};
    for (final levelId in levelIds.toSet()) {
      final raw = prefs.getString('$_progressPrefix$levelId');
      if (raw != null) {
        result[levelId] = LevelProgress.fromJsonString(raw);
      } else {
        result[levelId] = LevelProgress(
          levelId: levelId,
          bestScore: 0,
          starsEarned: 0,
          isUnlocked: unlockedByDefault || levelId == 1,
        );
      }
    }
    return result;
  }

  Future<Map<int, LevelProgress>> loadStoredProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<int, LevelProgress> result = {};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_progressPrefix)) {
        continue;
      }
      final raw = prefs.getString(key);
      if (raw == null) {
        continue;
      }
      final progress = LevelProgress.fromJsonString(raw);
      result[progress.levelId] = progress;
    }
    return result;
  }

  Future<void> saveLevelProgress(
    LevelProgress progress, {
    bool unlockNextLevel = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_progressPrefix${progress.levelId}',
      progress.toJsonString(),
    );

    // Unlock next level if not already unlocked
    if (unlockNextLevel && progress.starsEarned > 0) {
      final nextId = progress.levelId + 1;
      final nextRaw = prefs.getString('$_progressPrefix$nextId');
      if (nextRaw == null) {
        final unlocked = LevelProgress(
          levelId: nextId,
          bestScore: 0,
          starsEarned: 0,
          isUnlocked: true,
        );
        await prefs.setString(
            '$_progressPrefix$nextId', unlocked.toJsonString());
      } else {
        final existing = LevelProgress.fromJsonString(nextRaw);
        if (!existing.isUnlocked) {
          await prefs.setString(
            '$_progressPrefix$nextId',
            existing.copyWith(isUnlocked: true).toJsonString(),
          );
        }
      }
    }
  }

  // ──────────────────────────────────── Save/Load Current Game ─────────────

  Future<SavedGameState?> loadCurrentGame() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedGameKey);
    if (raw == null) return null;
    try {
      return SavedGameState.fromJsonString(raw);
    } catch (_) {
      await prefs.remove(_savedGameKey);
      return null;
    }
  }

  Future<void> saveCurrentGame(SavedGameState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedGameKey, state.toJsonString());
  }

  Future<void> clearCurrentGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedGameKey);
  }

  // ──────────────────────────────────── Custom Levels ──────────────────────

  Future<List<LevelModel>> loadCampaignLevels() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_campaignLevelsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => LevelModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading campaign levels: $e');
      return [];
    }
  }

  Future<List<LevelModel>> loadCustomLevels() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customLevelsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => LevelModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveCustomLevel(LevelModel level) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadCustomLevels();
    final idx = existing.indexWhere((l) => l.id == level.id);
    if (idx >= 0) {
      existing[idx] = level;
    } else {
      existing.add(level);
    }
    await prefs.setString(
      _customLevelsKey,
      jsonEncode(existing.map((l) => l.toJson()).toList()),
    );
  }

  Future<void> saveCampaignLevel(LevelModel level) async {
    final existing = await loadCampaignLevels();
    final idx = existing.indexWhere((l) => l.id == level.id);
    if (idx >= 0) {
      existing[idx] = level;
    } else {
      existing.add(level);
    }
    await saveCampaign(existing);
  }

  Future<void> saveCampaign(List<LevelModel> levels) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _campaignLevelsKey,
      jsonEncode(levels.map((l) => l.toJson()).toList()),
    );
  }

  Future<void> deleteCustomLevel(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadCustomLevels();
    existing.removeWhere((l) => l.id == id);
    await prefs.setString(
      _customLevelsKey,
      jsonEncode(existing.map((l) => l.toJson()).toList()),
    );
  }

  // ──────────────────────────────────── Lock / Unlock All ──────────────────

  Future<void> unlockAllLevels(int totalLevels) async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 1; i <= totalLevels; i++) {
      final raw = prefs.getString('$_progressPrefix$i');
      LevelProgress p;
      if (raw != null) {
        p = LevelProgress.fromJsonString(raw).copyWith(isUnlocked: true);
      } else {
        p = LevelProgress(
            levelId: i, bestScore: 0, starsEarned: 0, isUnlocked: true);
      }
      await prefs.setString('$_progressPrefix$i', p.toJsonString());
    }
  }

  Future<void> lockAllLevels(int totalLevels) async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 1; i <= totalLevels; i++) {
      final raw = prefs.getString('$_progressPrefix$i');
      LevelProgress p;
      if (raw != null) {
        p = LevelProgress.fromJsonString(raw).copyWith(isUnlocked: i == 1);
      } else {
        p = LevelProgress(
            levelId: i, bestScore: 0, starsEarned: 0, isUnlocked: i == 1);
      }
      await prefs.setString('$_progressPrefix$i', p.toJsonString());
    }
  }
}
