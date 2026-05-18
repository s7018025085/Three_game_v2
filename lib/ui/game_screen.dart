import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/level_model.dart';
import '../data/game_repository.dart';
import '../game/match3_game.dart';
import 'game_asset_paths.dart';
import '../localization/translations.dart';
import 'level_select_screen.dart';

class GameScreen extends StatefulWidget {
  final LevelModel level;
  final SavedGameState? savedGame;
  final bool isCampaignLevel;

  const GameScreen({
    super.key,
    required this.level,
    this.savedGame,
    this.isCampaignLevel = true,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _score = 0;
  late Match3Game _game;
  SavedGameState? _pendingResumeState;
  bool _showResult = false;
  bool _wonLevel = false;
  int _finalStars = 0;
  int _finalBonuses = 0;
  int _finalMaxCombo = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pendingResumeState = widget.savedGame;
    _initGame();
  }

  int _calculateStars({required bool won}) {
    int stars = 0;
    if (_score >= widget.level.star3Score) {
      stars = 3;
    } else if (_score >= widget.level.star2Score) {
      stars = 2;
    } else if (_score >= widget.level.star1Score) {
      stars = 1;
    }

    if (won && stars == 0) {
      return 1;
    }
    return stars;
  }

  void _finishGame({
    required bool won,
    int bonuses = 0,
    int maxCombo = 0,
  }) {
    setState(() {
      _showResult = true;
      _wonLevel = won;
      _finalStars = _calculateStars(won: won);
      _finalBonuses = bonuses;
      _finalMaxCombo = maxCombo;
    });
  }

  void _restartGame() {
    setState(() {
      _initGame();
    });
  }

  void _initGame() {
    final resumeState = _pendingResumeState;
    _pendingResumeState = null;
    _score = resumeState?.score ?? 0;
    _showResult = false;
    _wonLevel = false;
    _finalStars = 0;
    _finalBonuses = 0;
    _finalMaxCombo = 0;
    _isLoading = true;
    if (mounted) setState(() {});
    _game = Match3Game(
      level: widget.level,
      onScore: (score) {
        if (!mounted) {
          return;
        }
        setState(() => _score = score);
      },
      // onStateChanged removed: Match3Game currently has no state-callback parameter

      onGameOver: () => _finishGame(won: false),
      onLevelComplete: (score, stars, bonuses, maxCombo) => _finishGame(
        won: true,
        bonuses: bonuses,
        maxCombo: maxCombo,
      ),
      onLoaded: () {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  void _startNextLevel() async {
    final levels = await GameRepository.instance.loadCampaignLevels();
    final currentIndex = levels.indexWhere((l) => l.id == widget.level.id);

    if (currentIndex != -1 && currentIndex < levels.length - 1) {
      final nextLevel = levels[currentIndex + 1];
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => GameScreen(level: nextLevel),
          ),
        );
      }
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A24),
      body: Stack(
        children: [
          GameWidget(game: _game),
          AnimatedOpacity(
            opacity: _isLoading ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: IgnorePointer(
              ignoring: !_isLoading,
              child: Container(
                color: Colors.black.withValues(alpha: 0.75),
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10131D).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Подготовка уровня...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Пожалуйста, подождите',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 4,
                  left: 12,
                  right: 12,
                  child: _TopHudCard(
                    level: widget.level,
                    score: _score,
                    movesLeft: _game.movesLeft,
                    goals: _game.goals,
                    goalStatus: _game.goalStatus,
                    onBack: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const LevelSelectScreen(),
                      ),
                    ),
                    onShuffle: () => _game.manualShuffle(),
                  ),
                ),
                if (_showResult)
                  _GameOverOverlay(
                    won: _wonLevel,
                    score: _score,
                    stars: _finalStars,
                    bonuses: _finalBonuses,
                    maxCombo: _finalMaxCombo,
                    level: widget.level,
                    onRestart: _restartGame,
                    onNext: _startNextLevel,
                    onMenu: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const LevelSelectScreen(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopHudCard extends StatelessWidget {
  final LevelModel level;
  final int score;
  final int movesLeft;
  final List<LevelGoal> goals;
  final Map<int, int> goalStatus;
  final VoidCallback onBack;
  final VoidCallback onShuffle;

  const _TopHudCard({
    required this.level,
    required this.score,
    required this.movesLeft,
    required this.goals,
    required this.goalStatus,
    required this.onBack,
    required this.onShuffle,
  });

  @override
  Widget build(BuildContext context) {
    final nextTarget = movesLeft <= 5 ? Colors.redAccent : Colors.amber;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF111827).withValues(alpha: 0.94),
            const Color(0xFF1B2435).withValues(alpha: 0.88),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _HudButton(
                icon: Icons.arrow_back_ios_new,
                onTap: onBack,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.name,
                      style: GoogleFonts.bungee(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '${AppStrings.gameScore()}$score',
                      style: GoogleFonts.rubik(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _InfoChip(
                icon: Icons.swap_horiz,
                value: '$movesLeft',
                color: nextTarget,
              ),
              const SizedBox(width: 8),
              _HudButton(
                icon: Icons.refresh_rounded,
                onTap: onShuffle,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _GoalsWrap(
                  goals: goals,
                  goalStatus: goalStatus,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ScoreProgressBar(
            score: score,
            level: level,
          ),
        ],
      ),
    );
  }
}

class _HudButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HudButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.rubik(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalsWrap extends StatelessWidget {
  final List<LevelGoal> goals;
  final Map<int, int> goalStatus;

  const _GoalsWrap({
    required this.goals,
    required this.goalStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(goals.length, (index) {
        final goal = goals[index];
        final remaining = goalStatus[index] ?? goal.targetValue;
        return _GoalMiniBadge(goal: goal, remaining: remaining);
      }),
    );
  }
}

class _GoalMiniBadge extends StatelessWidget {
  final LevelGoal goal;
  final int remaining;

  const _GoalMiniBadge({
    required this.goal,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: remaining <= 0 ? Colors.greenAccent : Colors.white12,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.all(2),
            child: Image.asset(
              goalAssetPath(goal),
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$remaining',
            style: GoogleFonts.rubik(
              color: remaining <= 0 ? Colors.greenAccent : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreProgressBar extends StatelessWidget {
  final int score;
  final LevelModel level;

  const _ScoreProgressBar({
    required this.score,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final maxScore = math.max(level.star3Score, 1);
    final progress = (score / maxScore).clamp(0.0, 1.0);
    final thresholds = [
      level.star1Score,
      level.star2Score,
      level.star3Score,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 16,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  // Background track
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: Colors.white12),
                    ),
                  ),
                  // Progress fill
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFC857), Color(0xFFFF8A3D)],
                        ),
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Stars
                  for (var i = 0; i < thresholds.length; i++)
                    Positioned(
                      left: ((thresholds[i] / maxScore) * width - 10)
                          .clamp(0.0, width - 20),
                      top: -5,
                      child: Icon(
                        i == 2 ? Icons.star_rounded : Icons.star_half_rounded,
                        color: score >= thresholds[i]
                            ? Colors.amber
                            : Colors.white24,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GameOverOverlay extends StatefulWidget {
  final bool won;
  final int score;
  final int stars;
  final int bonuses;
  final int maxCombo;
  final LevelModel level;
  final VoidCallback onRestart;
  final VoidCallback onNext;
  final VoidCallback onMenu;

  const _GameOverOverlay({
    required this.won,
    required this.score,
    required this.stars,
    required this.bonuses,
    required this.maxCombo,
    required this.level,
    required this.onRestart,
    required this.onNext,
    required this.onMenu,
  });

  @override
  State<_GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<_GameOverOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut)
        .drive(Tween(begin: 0.7, end: 1.0));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.won
        ? AppStrings.gameLevelComplete()
        : AppStrings.gameOutOfMoves();
    final titleColor = widget.won ? Colors.white : Colors.redAccent;
    final gradientColors = widget.won
        ? [const Color(0xFF2C2C40), const Color(0xFF1A1A2E)]
        : [const Color(0xFF3D1A1A), const Color(0xFF1A0A0A)];

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        color: Colors.black87,
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: widget.won
                      ? Colors.white12
                      : Colors.red.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.won
                        ? Colors.black54
                        : Colors.red.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.won
                        ? Icons.emoji_events_rounded
                        : Icons.sentiment_dissatisfied_rounded,
                    color: widget.won ? Colors.amber : Colors.redAccent,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: GoogleFonts.bungee(
                      color: titleColor,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.won) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (index) => TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: 0.0,
                            end: index < widget.stars ? 1.0 : 0.0,
                          ),
                          duration: Duration(milliseconds: 300 + index * 150),
                          curve: Curves.elasticOut,
                          builder: (_, value, __) => Transform.scale(
                            scale: 0.6 + value * 0.4,
                            child: Icon(
                              index < widget.stars
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: Colors.amber,
                              size: 44,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    '${AppStrings.gameScore()}${widget.score}',
                    style: GoogleFonts.rubik(
                      color: widget.won ? Colors.amber : Colors.white70,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.won) ...[
                    _StatRow(
                        label: AppStrings.gameBonus(),
                        value: '${widget.bonuses}',
                        color: Colors.orangeAccent),
                    _StatRow(
                        label: AppStrings.gameMaxCombo(),
                        value: '${widget.maxCombo}',
                        color: Colors.lightBlueAccent),
                    const SizedBox(height: 20),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${AppStrings.gameTarget()}: ${widget.level.star1Score} / ${widget.level.star2Score} / ${widget.level.star3Score}',
                    style: GoogleFonts.rubik(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                  if (!widget.won) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${AppStrings.gameNeedMore(math.max(0, widget.level.star1Score - widget.score))}',
                      style: GoogleFonts.rubik(
                        color: Colors.redAccent.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  if (widget.won) ...[
                    _OverlayButton(
                      label: AppStrings.gameNextLevel(),
                      icon: Icons.arrow_forward_rounded,
                      onTap: widget.onNext,
                      isPrimary: true,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: _OverlayButton(
                          label: AppStrings.gameMenu(),
                          icon: Icons.home,
                          onTap: widget.onMenu,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _OverlayButton(
                          label: AppStrings.gameRetry(),
                          icon: Icons.replay,
                          onTap: widget.onRestart,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _OverlayButton(
                          label: AppStrings.gameShop(),
                          icon: Icons.shopping_bag_rounded,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppStrings.gameShopComingSoon()),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _OverlayButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isPrimary ? 16 : 14),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFFFFC857) : Colors.white10,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 2)
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.black87 : Colors.white,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.bungee(
                color: isPrimary ? Colors.black87 : Colors.white,
                fontSize: isPrimary ? 18 : 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.rubik(color: Colors.white60, fontSize: 14),
          ),
          Text(
            value,
            style: GoogleFonts.rubik(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
