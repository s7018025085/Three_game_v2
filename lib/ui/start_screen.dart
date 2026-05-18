import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/game_repository.dart';
import '../data/level_model.dart';
import '../localization/translations.dart';
import 'game_screen.dart';
import 'level_select_screen.dart';
import 'level_editor_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int _highScore = 0;
  SavedGameState? _savedGame;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    final savedGame = await GameRepository.instance.loadCurrentGame();
    final allProgress = await GameRepository.instance.loadStoredProgress();
    int best = 0;
    for (final p in allProgress.values) {
      if (p.bestScore > best) best = p.bestScore;
    }
    if (mounted) {
      setState(() {
        _savedGame = savedGame;
        _highScore = best;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continueSavedGame() {
    if (_savedGame == null) return;
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => GameScreen(
              level: _savedGame!.level,
              savedGame: _savedGame,
              isCampaignLevel: _savedGame!.isCampaignLevel,
            ),
          ),
        )
        .then((_) => _loadData());
  }

  Widget _buildSecondaryButton(
      IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.rubik(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_menu.png',
              fit: BoxFit.cover,
            ),
          ),
          // Dark Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Title
                  Text(
                    AppStrings.startTitle(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.bungee(
                      fontSize: 64,
                      height: 1.1,
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: [Color(0xFFFF4081), Color(0xFFFF9100)],
                        ).createShader(
                            const Rect.fromLTWH(0.0, 0.0, 200.0, 100.0)),
                      shadows: [
                        const Shadow(
                            color: Color(0x66FF4081),
                            blurRadius: 20,
                            offset: Offset(0, 4))
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // High score
                  if (!_loading)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${AppStrings.startHighScore()}$_highScore',
                        style: GoogleFonts.rubik(
                            fontSize: 16,
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5),
                      ),
                    ),

                  const Spacer(flex: 2),

                  // Continue button (if saved game)
                  if (_savedGame != null) ...[
                    GestureDetector(
                      onTap: _continueSavedGame,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 48, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B35), Color(0xFFFF4081)]),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0xFFFF4081)
                                    .withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6))
                          ],
                        ),
                        child: Text(
                          '${AppStrings.startContinueButton()}  ${_savedGame!.level.name}',
                          style: GoogleFonts.rubik(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Play button
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) => Transform.scale(
                        scale: _scaleAnimation.value, child: child),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context)
                          .push(
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) =>
                                  const LevelSelectScreen(),
                              transitionsBuilder: (_, anim, __, child) =>
                                  FadeTransition(opacity: anim, child: child),
                              transitionDuration:
                                  const Duration(milliseconds: 600),
                            ),
                          )
                          .then((_) => _loadData()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 64, vertical: 20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF00E676), Color(0xFF1DB954)]),
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0xFF00E676)
                                    .withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6))
                          ],
                        ),
                        child: Text(
                          AppStrings.startPlayButton(),
                          style: GoogleFonts.rubik(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 3.0),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Secondary buttons
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildSecondaryButton(
                          Icons.map_rounded, AppStrings.levelSelectTitle(), () {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                  builder: (_) => const LevelSelectScreen()),
                            )
                            .then((_) => _loadData());
                      }),
                      _buildSecondaryButton(
                          Icons.edit, AppStrings.startEditor(), () {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                  builder: (_) => const LevelEditorScreen()),
                            )
                            .then((_) => _loadData());
                      }),
                      _buildSecondaryButton(Icons.settings_rounded, 'Настройки',
                          () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Settings coming soon!')),
                        );
                      }),
                    ],
                  ),

                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
