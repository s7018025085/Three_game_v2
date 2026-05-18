import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../logic/procedural_level_generator.dart';
import '../data/level_model.dart';
import '../data/game_repository.dart';
import 'game_screen.dart';
import 'level_editor_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  List<LevelModel> _levels = [];
  Map<int, LevelProgress> _progress = {};
  bool _loading = true;
  bool _allUnlocked = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    var campaign = await GameRepository.instance.loadCampaignLevels();
    if (campaign.isEmpty) {
      print('Database is empty. Generating initial campaign...');
      campaign = ProceduralLevelGenerator.generateCampaign(300);
      await GameRepository.instance.saveCampaign(campaign);
    } else {
      print('Loaded ${campaign.length} levels from local database.');
    }
    _levels = campaign;

    final progress =
        await GameRepository.instance.getAllProgress(_levels.length);
    final allUnlocked = progress.values.isNotEmpty &&
        progress.values.every((p) => p.isUnlocked);
    if (mounted) {
      setState(() {
        _progress = progress;
        _loading = false;
        _allUnlocked = allUnlocked;
      });
    }
  }

  Future<void> _regenerateCampaign() async {
    setState(() => _loading = true);
    final levels = ProceduralLevelGenerator.generateCampaign(300);
    await GameRepository.instance.saveCampaign(levels);
    await GameRepository.instance.lockAllLevels(300); // Reset progress locks
    await _loadProgress();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Campaign regenerated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _toggleLock() async {
    if (_allUnlocked) {
      await GameRepository.instance.lockAllLevels(_levels.length);
    } else {
      await GameRepository.instance.unlockAllLevels(_levels.length);
    }
    _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_menu.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Choose Level',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.bungee(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _regenerateCampaign,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome,
                                  color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text('Regen 300',
                                  style: GoogleFonts.rubik(
                                      color: Colors.amber,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _toggleLock,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: _allUnlocked
                                ? Colors.amber.withValues(alpha: 0.15)
                                : Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  _allUnlocked ? Colors.amber : Colors.white24,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _allUnlocked
                                    ? Icons.lock_open_rounded
                                    : Icons.lock_rounded,
                                color: _allUnlocked
                                    ? Colors.amber
                                    : Colors.white60,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _allUnlocked ? 'Lock all' : 'Unlock all',
                                style: GoogleFonts.rubik(
                                  color: _allUnlocked
                                      ? Colors.amber
                                      : Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => Navigator.of(context)
                            .push(MaterialPageRoute(
                                builder: (_) => const LevelEditorScreen()))
                            .then((_) => _loadProgress()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text('Editor',
                                  style: GoogleFonts.rubik(
                                      color: Colors.white, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white))
                      : _levels.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.auto_awesome,
                                      color: Colors.white24, size: 64),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No levels generated yet',
                                    style: GoogleFonts.bungee(
                                        color: Colors.white54, fontSize: 18),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Click "Regen 300" to create campaign',
                                    style: GoogleFonts.rubik(
                                        color: Colors.white30, fontSize: 14),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                childAspectRatio: 0.85,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: _levels.length,
                              itemBuilder: (_, i) {
                                final level = _levels[i];
                                final prog = _progress[level.id] ??
                                    LevelProgress(
                                      levelId: level.id,
                                      bestScore: 0,
                                      starsEarned: 0,
                                      isUnlocked: level.id == 1,
                                    );
                                return _LevelCell(
                                  level: level,
                                  progress: prog,
                                  onTap: prog.isUnlocked
                                      ? () => Navigator.of(context)
                                          .push(MaterialPageRoute(
                                              builder: (_) =>
                                                  GameScreen(level: level)))
                                          .then((_) => _loadProgress())
                                      : null,
                                  onEdit: _allUnlocked
                                      ? () => Navigator.of(context)
                                          .push(MaterialPageRoute(
                                            builder: (_) => LevelEditorScreen(
                                              editLevel: level,
                                              isCampaignLevel: true,
                                            ),
                                          ))
                                          .then((_) => _loadProgress())
                                      : null,
                                );
                              },
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

class _LevelCell extends StatelessWidget {
  final LevelModel level;
  final LevelProgress progress;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;

  const _LevelCell({
    required this.level,
    required this.progress,
    this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final locked = !progress.isUnlocked;
    final stars = progress.starsEarned;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            constraints: const BoxConstraints(minHeight: 140),
            decoration: BoxDecoration(
              gradient: locked
                  ? const LinearGradient(
                      colors: [Color(0xFF1E1E2E), Color(0xFF1A1A24)])
                  : LinearGradient(
                      colors: stars == 3
                          ? [const Color(0xFF7C3AED), const Color(0xFF4F46E5)]
                          : stars >= 1
                              ? [
                                  const Color(0xFF1D4ED8),
                                  const Color(0xFF1E40AF)
                                ]
                              : [
                                  const Color(0xFF374151),
                                  const Color(0xFF1F2937)
                                ],
                    ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: locked ? Colors.white10 : Colors.white24,
                width: 1,
              ),
              boxShadow: locked
                  ? []
                  : [
                      BoxShadow(
                        color: (stars == 3 ? Colors.purple : Colors.blue)
                            .withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (locked)
                  const SizedBox(
                    height: 80,
                    child: Center(
                      child: Icon(Icons.lock, color: Colors.white30, size: 22),
                    ),
                  )
                else ...[
                  _LevelPreview(levelId: level.id),
                  const SizedBox(height: 6),
                  Text(
                    '${level.id}',
                    style:
                        GoogleFonts.bungee(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (i) => Icon(
                        i < stars
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onEdit != null)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onEdit,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit, size: 16, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LevelPreview extends StatelessWidget {
  final int levelId;

  const _LevelPreview({required this.levelId});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: CustomPaint(
        painter: _LevelPreviewPainter(seed: levelId),
      ),
    );
  }
}

class _LevelPreviewPainter extends CustomPainter {
  final int seed;

  _LevelPreviewPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final int gridN = 4;
    final double pad = 6;
    final double cell = (size.width - pad * 2) / gridN;

    final border = Paint()
      ..color = const Color(0x66FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final bg = Paint()..color = const Color(0x22000000);
    final outlineRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );
    canvas.drawRRect(outlineRRect, bg);
    canvas.drawRRect(outlineRRect, border);

    for (int x = 0; x < gridN; x++) {
      for (int y = 0; y < gridN; y++) {
        final int h = (seed + x * 17 + y * 31) % 7;
        final bool active = h != 0;

        final rect = Rect.fromLTWH(
          pad + x * cell,
          pad + y * cell,
          cell,
          cell,
        );

        if (active) {
          final fill = Paint()
            ..color = ((x + y) % 2 == 0)
                ? const Color(0x22000000)
                : const Color(0x11000000);
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect.deflate(1.5), const Radius.circular(6)),
            fill,
          );
        } else {
          final holePaint = Paint()
            ..color = const Color(0x44000000)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2;
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect.deflate(1.5), const Radius.circular(6)),
            holePaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
