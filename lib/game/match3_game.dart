import 'dart:async';
import 'dart:math';

import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/game_repository.dart';
import '../data/level_model.dart';
import '../logic/match_logic.dart';
import 'board_component.dart';
import 'gem_component.dart';
import 'particle_manager.dart';

class Match3Game extends FlameGame {
  final LevelModel level;
  final Function(int) onScore;
  final VoidCallback? onGameOver;
  final Function(int score, int stars, int bonuses, int maxCombo)?
      onLevelComplete;
  final VoidCallback? onLoaded;

  late MatchLogic logic;
  late BoardComponent board;

  final Map<Point, GemComponent> _gems = {};
  final Map<GemType, Sprite> _gemSprites = {};
  final Map<int, Sprite> _rockSprites = {};
  late Sprite _jellySprite;
  Sprite? _rainbowSprite;
  Sprite? _bgSprite;
  Sprite? _bombSprite;
  Sprite? _lineHSprite;
  Sprite? _lineVSprite;

  double tileSize = 0;
  bool isAnimating = false;

  int _score = 0;
  int get score => _score;

  late int _movesLeft;
  int get movesLeft => _movesLeft;

  List<LevelGoal> get goals => logic.goals;
  Map<int, int> get goalStatus => logic.goalStatus;

  int _totalBonuses = 0;
  int _maxCombo = 0;
  int _currentCombo = 0;

  Match3Game({
    required this.level,
    required this.onScore,
    this.onGameOver,
    this.onLevelComplete,
    this.onLoaded,
  }) {
    final int rows = level.grid.isNotEmpty ? level.grid[0].length : 8;
    logic = MatchLogic(
      rows: rows,
      grid: level.grid,
      jelly: level.jellyGrid,
      initialBoard: level.initialBoard,
      levelGoals: level.goals,
    );
    _movesLeft = level.moveLimit;
  }

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final maxBoardWidth = size.x * 0.98;
    // Reserve some vertical space for HUD and safe area, then fit board into
    // the remaining height. Это позволяет уменьшать доску, если по высоте
    // она не влезает на экран.
    const reservedTopSpace = 150.0;
    const reservedBottomSpace = 32.0;
    final maxBoardHeight =
        max(0, size.y - reservedTopSpace - reservedBottomSpace);

    // TileSize должен помещаться и по ширине, и по высоте
    final double tileSizeByWidth = maxBoardWidth / MatchLogic.cols;
    final double tileSizeByHeight = maxBoardHeight / logic.rows;
    tileSize = min(tileSizeByWidth, tileSizeByHeight);

    final double calculatedWidth = tileSize * MatchLogic.cols;
    final double boardHeight = tileSize * logic.rows;

    await _loadSprites();

    board = BoardComponent(
      rows: logic.rows,
      cols: MatchLogic.cols,
      tileSize: tileSize,
      grid: level.grid,
      jellyBoard: logic.jellyBoard,
      jellySprite: _jellySprite,
    )..position = Vector2(
        (size.x - calculatedWidth) / 2,
        reservedTopSpace + max(0, (maxBoardHeight - boardHeight) / 2),
      );

    add(board);

    for (int x = 0; x < MatchLogic.cols; x++) {
      for (int y = 0; y < logic.rows; y++) {
        if (level.grid[x][y] && logic.board[x][y] != null) {
          _spawnGem(x, y, logic.board[x][y]!);
        }
      }
    }

    _autosave();

    onLoaded?.call();
  }

  void _autosave() {
    GameRepository.instance.saveCurrentGame(SavedGameState(
      level: level,
      score: _score,
      movesLeft: _movesLeft,
      isCampaignLevel: true,
      board: logic.exportBoardState(),
      jellyGrid: logic.exportJellyState(),
      goalStatus: logic.exportGoalStatus(),
    ));
  }

  void _spawnGem(int x, int y, GemData data,
      {bool dropIn = false, int? fromY}) {
    final gem = GemComponent(
      gridX: x,
      gridY: y,
      type: data.type,
      modifier: data.modifier,
      size: tileSize,
      onSwipe: _handleSwipe,
      sprite: _getGemSprite(data),
      health: data.health,
      bombSprite: _bombSprite,
      lineHSprite: _lineHSprite,
      lineVSprite: _lineVSprite,
    );

    if (dropIn) {
      final startY = (fromY != null) ? (fromY * tileSize) : (-tileSize * 2);
      gem.position = Vector2(x * tileSize, startY);
      gem.add(MoveEffect.to(
        Vector2(x * tileSize, y * tileSize),
        EffectController(duration: 0.3, curve: Curves.easeIn),
      ));
    } else {
      gem.position = Vector2(x * tileSize, y * tileSize);
    }

    _gems[Point(x, y)] = gem;
    board.add(gem);
  }

  void _handleSwipe(GemComponent gem, Vector2 delta) {
    if (isAnimating) return;
    if (_movesLeft <= 0) return;

    int dx = 0, dy = 0;
    if (delta.x.abs() > delta.y.abs()) {
      dx = delta.x > 0 ? 1 : -1;
    } else {
      dy = delta.y > 0 ? 1 : -1;
    }

    final targetX = gem.gridX + dx;
    final targetY = gem.gridY + dy;

    if (targetX < 0 ||
        targetX >= MatchLogic.cols ||
        targetY < 0 ||
        targetY >= logic.rows) {
      return;
    }
    if (!level.grid[targetX][targetY]) return;

    _attemptSwap(gem.gridX, gem.gridY, targetX, targetY);
  }

  Future<void> _attemptSwap(int x1, int y1, int x2, int y2) async {
    isAnimating = true;

    final gem1 = _gems[Point(x1, y1)];
    final gem2 = _gems[Point(x2, y2)];
    if (gem1 == null || gem2 == null) {
      isAnimating = false;
      return;
    }

    final p1 = gem1.position.clone();
    final p2 = gem2.position.clone();

    gem1.add(MoveEffect.to(
        p2, EffectController(duration: 0.2, curve: Curves.easeInOut)));
    gem2.add(MoveEffect.to(
        p1, EffectController(duration: 0.2, curve: Curves.easeInOut)));
    await Future.delayed(const Duration(milliseconds: 250));

    if (logic.isValidSwap(x1, y1, x2, y2)) {
      _gems[Point(x2, y2)] = gem1;
      _gems[Point(x1, y1)] = gem2;
      gem1.gridX = x2;
      gem1.gridY = y2;
      gem2.gridX = x1;
      gem2.gridY = y1;

      HapticFeedback.lightImpact();
      _movesLeft--;

      MatchResult result;
      if (logic.isBonusCombo(x1, y1, x2, y2)) {
        logic.executeSwap(x1, y1, x2, y2);
        result = logic.processBonusCombo(x1, y1, x2, y2);
        await _animateMatches(result);
      } else if (logic.isRainbowSwap(x1, y1, x2, y2)) {
        logic.executeSwap(x1, y1, x2, y2);
        result = logic.processRainbowSwap(x1, y1, x2, y2);
        await _animateMatches(result);
      } else {
        logic.executeSwap(x1, y1, x2, y2);
        await _resolveMatches(swapTarget: Point(x2, y2));
      }

      _autosave();

      if (logic.areGoalsComplete) {
        await _startWinSequence();
      } else if (_movesLeft <= 0) {
        _handleGameOver();
      }
    } else {
      gem1.add(MoveEffect.to(
          p1, EffectController(duration: 0.2, curve: Curves.easeInOut)));
      gem2.add(MoveEffect.to(
          p2, EffectController(duration: 0.2, curve: Curves.easeInOut)));
      await Future.delayed(const Duration(milliseconds: 250));
    }

    isAnimating = false;
  }

  Future<void> _resolveMatches({Point? swapTarget}) async {
    final result = logic.processMatches(swapTarget: swapTarget);
    if (result.removedGems.isEmpty) {
      _currentCombo = 0; // Reset combo if no matches
      await _checkStalemate();
      return;
    }
    await _animateMatches(result);
  }

  Future<void> _animateMatches(MatchResult result) async {
    HapticFeedback.mediumImpact();
    _score += result.score;
    onScore(_score);

    if (result.removedGems.isNotEmpty) {
      _currentCombo++;
      _maxCombo = max(_maxCombo, _currentCombo);
    }

    // Count bonuses in this result
    _totalBonuses += result.createdBonuses.length;
    // Also count if we triggered existing bonuses
    for (var p in result.removedGems) {
      if (logic.board[p.x][p.y]?.modifier != GemModifier.none) {
        _totalBonuses++;
      }
    }
    final List<Future> animations = [];
    for (final point in result.removedGems) {
      final gem = _gems.remove(point);
      if (gem != null) {
        board.add(
          ParticleManager.createExplosion(
            gem.position + Vector2.all(tileSize / 2),
            Colors.white,
          ),
        );
        gem.add(
            ScaleEffect.to(Vector2.zero(), EffectController(duration: 0.2)));
        animations.add(
          Future.delayed(
              const Duration(milliseconds: 200), () => gem.removeFromParent()),
        );
      }
    }
    await Future.wait(animations);

    result.createdBonuses.forEach((point, gemData) {
      _gems.remove(point)?.removeFromParent();
      _spawnGem(point.x, point.y, gemData);
    });

    // Update health/sprites for rocks
    for (int x = 0; x < MatchLogic.cols; x++) {
      for (int y = 0; y < logic.rows; y++) {
        final data = logic.board[x][y];
        final gem = _gems[Point(x, y)];
        if (data != null && gem != null && gem.health != data.health) {
          gem.health = data.health;
          gem.sprite = _getGemSprite(data);
          gem.add(
            MoveEffect.by(
              Vector2(4, 0),
              EffectController(duration: 0.05, alternate: true, repeatCount: 3),
            ),
          );
        }
      }
    }

    // Gravity
    final List<DropEvent> drops = logic.applyGravity();
    final List<Future> dropAnims = [];
    for (final drop in drops) {
      final gem = _gems.remove(Point(drop.x, drop.fromY));
      if (gem != null) {
        gem.gridX = drop.x;
        gem.gridY = drop.toY;
        _gems[Point(drop.x, drop.toY)] = gem;
        final dist = (drop.toY - drop.fromY).abs().clamp(1, 8);
        gem.add(
          MoveEffect.to(
            Vector2(drop.x * tileSize, drop.toY * tileSize),
            EffectController(duration: 0.08 * dist, curve: Curves.easeIn),
          ),
        );
        dropAnims
            .add(Future.delayed(Duration(milliseconds: (80 * dist).toInt())));
      }
    }
    await Future.wait(dropAnims);

    // Fill
    final List<DropEvent> newGems = logic.fillEmpty();
    final List<Future> newAnims = [];
    for (final drop in newGems) {
      _spawnGem(drop.x, drop.toY, drop.gem, dropIn: true, fromY: drop.fromY);
      newAnims.add(Future.delayed(const Duration(milliseconds: 300)));
    }
    await Future.wait(newAnims);

    await _resolveMatches();
  }

  Future<void> _startWinSequence() async {
    isAnimating = true;

    // 1. Convert remaining moves to bonuses
    while (_movesLeft > 0) {
      _movesLeft--;
      onScore(_score); // Trigger HUD update for moves count

      final converted = logic.convertRandomGemsToBonuses(1);
      if (converted.isNotEmpty) {
        for (var entry in converted.entries) {
          final p = entry.key;
          _gems[p]?.removeFromParent();
          _spawnGem(p.x, p.y, entry.value);
        }
        await Future.delayed(const Duration(milliseconds: 150));
      }
    }

    // 2. Explode all bonuses sequentially
    while (true) {
      final bonusPositions = logic.getBonusPositions();
      if (bonusPositions.isEmpty) break;

      // Take the first one and explode
      final p = bonusPositions.first;
      final result = logic.triggerBonusAt(p);
      await _animateMatches(
          result); // This will also handle gravity and cascading
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // 3. Finalize
    _handleGameOver();
  }

  void _handleGameOver() async {
    final existing = await GameRepository.instance.getLevelProgress(level.id);

    int stars = 0;
    if (_score >= level.star3Score) {
      stars = 3;
    } else if (_score >= level.star2Score) {
      stars = 2;
    } else if (_score >= level.star1Score) {
      stars = 1;
    }

    final progress = LevelProgress(
      levelId: level.id,
      bestScore: max(_score, existing.bestScore),
      starsEarned: max(stars, existing.starsEarned),
      isUnlocked: true,
    );

    await GameRepository.instance.saveLevelProgress(progress);
    await GameRepository.instance.clearCurrentGame();

    if (stars > 0) {
      onLevelComplete?.call(_score, stars, _totalBonuses, _maxCombo);
    } else {
      onGameOver?.call();
    }
  }

  Future<void> _checkStalemate() async {
    if (logic.hasPossibleMoves()) {
      isAnimating = false;
      return;
    }
    await _shuffleBoard();
  }

  Future<void> manualShuffle() async {
    if (isAnimating) return;
    isAnimating = true;
    await _shuffleBoard();
    isAnimating = false;
  }

  Future<void> _shuffleBoard() async {
    isAnimating = true;

    final center = Vector2(
      (MatchLogic.cols * tileSize) / 2,
      (logic.rows * tileSize) / 2,
    );

    final List<Future> gatherAnims = [];
    for (final gem in _gems.values) {
      final effect = MoveEffect.to(
          center, EffectController(duration: 0.4, curve: Curves.easeInQuad));
      gem.add(effect);
      gatherAnims.add(effect.completed);
    }
    await Future.wait(gatherAnims);

    logic.shuffleBoard();

    final oldGems = Map<Point, GemComponent>.from(_gems);
    _gems.clear();

    final availableGems = oldGems.values.toList();
    final List<Future> scatterAnims = [];

    int gemIdx = 0;
    for (int x = 0; x < MatchLogic.cols; x++) {
      for (int y = 0; y < logic.rows; y++) {
        if (level.grid[x][y] && logic.board[x][y] != null) {
          final data = logic.board[x][y]!;

          GemComponent gem;
          if (gemIdx < availableGems.length) {
            final oldGem = availableGems[gemIdx];
            if (oldGem.type == data.type && oldGem.modifier == data.modifier) {
              gem = oldGem;
            } else {
              oldGem.removeFromParent();
              gem = GemComponent(
                gridX: x,
                gridY: y,
                type: data.type,
                modifier: data.modifier,
                size: tileSize,
                onSwipe: _handleSwipe,
                sprite: _getGemSprite(data),
                health: data.health,
              );
              board.add(gem);
              gem.position = center.clone();
            }
            gemIdx++;
          } else {
            gem = GemComponent(
              gridX: x,
              gridY: y,
              type: data.type,
              modifier: data.modifier,
              size: tileSize,
              onSwipe: _handleSwipe,
              sprite: _getGemSprite(data),
              health: data.health,
            );
            gem.position = center.clone();
            board.add(gem);
          }

          gem.gridX = x;
          gem.gridY = y;
          _gems[Point(x, y)] = gem;

          scatterAnims.add(Future(() async {
            final effect = MoveEffect.to(
              Vector2(x * tileSize, y * tileSize),
              EffectController(duration: 0.4, curve: Curves.easeOutQuad),
            );
            gem.add(effect);
            await effect.completed;
          }));
        }
      }
    }

    for (int i = gemIdx; i < availableGems.length; i++) {
      availableGems[i].removeFromParent();
    }

    await Future.wait(scatterAnims);
    await _resolveMatches();
  }

  Sprite? _getGemSprite(GemData data) {
    if (data.modifier == GemModifier.rainbow) return _rainbowSprite;
    if (data.type == GemType.rock) {
      return _rockSprites[data.health.clamp(1, 3)];
    }
    return _gemSprites[data.type];
  }

  Future<void> _loadSprites() async {
    _bgSprite = await loadSprite('bg_game.png');
    _rainbowSprite = await loadSprite('gem_rainbow.png');
    _jellySprite = await loadSprite('jelly.png');

    _gemSprites[GemType.red] = await loadSprite('gem_red.png');
    _gemSprites[GemType.green] = await loadSprite('gem_green.png');
    _gemSprites[GemType.blue] = await loadSprite('gem_blue.png');
    _gemSprites[GemType.yellow] = await loadSprite('gem_yellow.png');
    _gemSprites[GemType.purple] = await loadSprite('gem_purple.png');
    _gemSprites[GemType.orange] = await loadSprite('gem_orange.png');

    _rockSprites[3] = await loadSprite('rock_full.png');
    _rockSprites[2] = await loadSprite('rock_cracked.png');
    _rockSprites[1] = await loadSprite('rock_broken.png');

    _bombSprite = await loadSprite('bomb.png');
    _lineHSprite = await loadSprite('line_h.png');
    _lineVSprite = await loadSprite('line_v.png');
  }

  @override
  void render(Canvas canvas) {
    if (_bgSprite != null) {
      _bgSprite!.render(canvas, position: Vector2.zero(), size: size);
    }
    super.render(canvas);
  }
}
