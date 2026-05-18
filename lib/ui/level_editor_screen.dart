import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/game_repository.dart';
import '../data/level_model.dart';
import '../logic/match_logic.dart';
import 'game_asset_paths.dart';
import 'game_screen.dart';

enum EditorTool { cell, jelly, rock }

class LevelEditorScreen extends StatefulWidget {
  final LevelModel? editLevel;
  final bool isCampaignLevel;

  const LevelEditorScreen(
      {super.key, this.editLevel, this.isCampaignLevel = false});

  @override
  State<LevelEditorScreen> createState() => _LevelEditorScreenState();
}

class _LevelEditorScreenState extends State<LevelEditorScreen> {
  int _cols = 8;
  int _rows = 8;

  late List<List<bool>> _grid;
  late List<List<int>> _jelly;
  late List<List<GemType?>> _initialBoard;
  EditorTool _tool = EditorTool.cell;

  final _nameCon = TextEditingController(text: 'Custom Level');
  final _movesCon = TextEditingController(text: '25');
  final _star1Con = TextEditingController(text: '200');
  final _star2Con = TextEditingController(text: '400');
  final _star3Con = TextEditingController(text: '700');

  @override
  void initState() {
    super.initState();
    if (widget.editLevel != null) {
      _grid =
          widget.editLevel!.grid.map((col) => List<bool>.from(col)).toList();
      _jelly = widget.editLevel!.jellyGrid
          .map((col) => List<int>.from(col))
          .toList();
      _initialBoard = widget.editLevel!.initialBoard
          .map((col) => List<GemType?>.from(col))
          .toList();
      _cols = _grid.length;
      _rows = _grid.isNotEmpty ? _grid[0].length : 8;
      _nameCon.text = widget.editLevel!.name;
      _movesCon.text = widget.editLevel!.moveLimit.toString();
      _star1Con.text = widget.editLevel!.star1Score.toString();
      _star2Con.text = widget.editLevel!.star2Score.toString();
      _star3Con.text = widget.editLevel!.star3Score.toString();
    } else {
      _grid = List.generate(_cols, (_) => List.filled(_rows, true));
      _jelly = List.generate(_cols, (_) => List.filled(_rows, 0));
      _initialBoard = List.generate(_cols, (_) => List.filled(_rows, null));
    }
  }

  @override
  void dispose() {
    _nameCon.dispose();
    _movesCon.dispose();
    _star1Con.dispose();
    _star2Con.dispose();
    _star3Con.dispose();
    super.dispose();
  }

  void _onCellClick(int x, int y) {
    setState(() {
      switch (_tool) {
        case EditorTool.cell:
          _grid[x][y] = !_grid[x][y];
          if (!_grid[x][y]) {
            _jelly[x][y] = 0;
            _initialBoard[x][y] = null;
          }
          break;
        case EditorTool.jelly:
          if (!_grid[x][y]) {
            return;
          }
          _jelly[x][y] = (_jelly[x][y] + 1) % 3;
          break;
        case EditorTool.rock:
          if (!_grid[x][y]) {
            return;
          }
          _initialBoard[x][y] =
              _initialBoard[x][y] == GemType.rock ? null : GemType.rock;
          break;
      }
    });
  }

  void _symmetrize() {
    setState(() {
      for (int x = 0; x < _cols ~/ 2; x++) {
        for (int y = 0; y < _rows; y++) {
          _grid[_cols - 1 - x][y] = _grid[x][y];
          _jelly[_cols - 1 - x][y] = _jelly[x][y];
          _initialBoard[_cols - 1 - x][y] = _initialBoard[x][y];
        }
      }
    });
  }

  void _fill() => setState(() {
        _grid = List.generate(_cols, (_) => List.filled(_rows, true));
      });

  void _clear() => setState(() {
        _grid = List.generate(_cols, (_) => List.filled(_rows, false));
        _jelly = List.generate(_cols, (_) => List.filled(_rows, 0));
        _initialBoard = List.generate(_cols, (_) => List.filled(_rows, null));
      });

  void _resizeBoard(int cols, int rows) {
    if (cols < 4) cols = 4;
    if (rows < 4) rows = 4;
    if (cols == _cols && rows == _rows) return;

    final newGrid = List.generate(cols, (x) {
      return List.generate(rows, (y) {
        if (x < _cols && y < _rows) {
          return _grid[x][y];
        }
        return true;
      });
    });
    final newJelly = List.generate(cols, (x) {
      return List.generate(rows, (y) {
        if (x < _cols && y < _rows) {
          return _jelly[x][y];
        }
        return 0;
      });
    });
    final newInitialBoard = List.generate(cols, (x) {
      return List.generate(rows, (y) {
        if (x < _cols && y < _rows) {
          return _initialBoard[x][y];
        }
        return null;
      });
    });
    setState(() {
      _cols = cols;
      _rows = rows;
      _grid = newGrid;
      _jelly = newJelly;
      _initialBoard = newInitialBoard;
    });
  }

  LevelModel _buildLevel({int? idOverride, String fallbackName = 'Custom'}) {
    return LevelModel(
      id: idOverride ??
          widget.editLevel?.id ??
          DateTime.now().millisecondsSinceEpoch % 100000,
      grid: _grid.map((col) => List<bool>.from(col)).toList(),
      jellyGrid: _jelly.map((col) => List<int>.from(col)).toList(),
      initialBoard:
          _initialBoard.map((col) => List<GemType?>.from(col)).toList(),
      moveLimit: int.tryParse(_movesCon.text) ?? 25,
      star1Score: int.tryParse(_star1Con.text) ?? 200,
      star2Score: int.tryParse(_star2Con.text) ?? 400,
      star3Score: int.tryParse(_star3Con.text) ?? 700,
      name: _nameCon.text.isEmpty ? fallbackName : _nameCon.text,
    );
  }

  Future<void> _save() async {
    final level = _buildLevel();
    if (widget.isCampaignLevel) {
      await GameRepository.instance.saveCampaignLevel(level);
    } else {
      await GameRepository.instance.saveCustomLevel(level);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.editLevel == null
              ? 'Level saved!'
              : widget.isCampaignLevel
                  ? 'Campaign level updated!'
                  : 'Level updated!'),
        ),
      );
    }
  }

  void _playTest() {
    final level = _buildLevel(
      idOverride: widget.editLevel?.id ?? 9999,
      fallbackName: 'Test',
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          level: level,
          isCampaignLevel: false,
        ),
      ),
    );
  }

  int get _activeCount {
    int count = 0;
    for (int x = 0; x < _cols; x++) {
      for (int y = 0; y < _rows; y++) {
        if (_grid[x][y]) {
          count++;
        }
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_editor.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.editLevel == null
                            ? 'Level Editor'
                            : 'Edit ${widget.editLevel!.name}',
                        style: GoogleFonts.bungee(
                          color: Colors.white,
                          fontSize: 22,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$_activeCount cells',
                        style: GoogleFonts.rubik(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _ModeBtn(
                          label: 'Cell',
                          leading: const Icon(
                            Icons.check_box_outline_blank,
                            color: Colors.white,
                            size: 16,
                          ),
                          selected: _tool == EditorTool.cell,
                          onTap: () => setState(() => _tool = EditorTool.cell),
                        ),
                        const SizedBox(width: 8),
                        _ModeBtn(
                          label: 'Jelly',
                          leading: const _EditorAssetIcon(
                            assetPath: jellyTileAssetPath,
                            size: 18,
                          ),
                          selected: _tool == EditorTool.jelly,
                          onTap: () => setState(() => _tool = EditorTool.jelly),
                        ),
                        const SizedBox(width: 8),
                        _ModeBtn(
                          label: 'Rock',
                          leading: const _EditorAssetIcon(
                            assetPath: rockTileAssetPath,
                            size: 18,
                          ),
                          selected: _tool == EditorTool.rock,
                          onTap: () => setState(() => _tool = EditorTool.rock),
                        ),
                        Container(
                          height: 24,
                          width: 1,
                          color: Colors.white24,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        _ToolBtn('Mirror', Icons.flip, _symmetrize),
                        const SizedBox(width: 8),
                        _ToolBtn('Fill', Icons.grid_on, _fill),
                        const SizedBox(width: 8),
                        _ToolBtn('Clear', Icons.grid_off, _clear),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DimensionControl(
                          label: 'Columns',
                          value: _cols,
                          onDecrease: () => _resizeBoard(_cols - 1, _rows),
                          onIncrease: () => _resizeBoard(_cols + 1, _rows),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DimensionControl(
                          label: 'Rows',
                          value: _rows,
                          onDecrease: () => _resizeBoard(_cols, _rows - 1),
                          onIncrease: () => _resizeBoard(_cols, _rows + 1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AspectRatio(
                    aspectRatio: 1,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final cellSize = constraints.maxWidth / _cols;
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D0D18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _cols,
                              childAspectRatio: 1,
                            ),
                            itemCount: _cols * _rows,
                            itemBuilder: (_, index) {
                              final x = index % _cols;
                              final y = index ~/ _cols;
                              return GestureDetector(
                                onTap: () => _onCellClick(x, y),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 100),
                                  margin: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    color: _grid[x][y]
                                        ? ((x + y) % 2 == 0
                                            ? const Color(0xFF4F46E5)
                                                .withValues(alpha: 0.7)
                                            : const Color(0xFF7C3AED)
                                                .withValues(alpha: 0.7))
                                        : const Color(0xFF111120),
                                    border: Border.all(
                                      color: _grid[x][y]
                                          ? Colors.white24
                                          : Colors.white10,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (_jelly[x][y] > 0)
                                        Opacity(
                                          opacity:
                                              _jelly[x][y] == 2 ? 0.95 : 0.55,
                                          child: _EditorAssetIcon(
                                            assetPath: jellyTileAssetPath,
                                            size: cellSize * 0.56,
                                          ),
                                        ),
                                      if (_initialBoard[x][y] == GemType.rock)
                                        _EditorAssetIcon(
                                          assetPath: rockTileAssetPath,
                                          size: cellSize * 0.62,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SettingsField('Level Name', _nameCon),
                  const SizedBox(height: 8),
                  _SettingsField('Move Limit', _movesCon, isNumber: true),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _SettingsField(
                          '★ Score',
                          _star1Con,
                          isNumber: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SettingsField(
                          '★★ Score',
                          _star2Con,
                          isNumber: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SettingsField(
                          '★★★ Score',
                          _star3Con,
                          isNumber: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          label: 'Test Play',
                          icon: Icons.play_arrow_rounded,
                          color: const Color(0xFF059669),
                          onTap: _playTest,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionBtn(
                          label: widget.editLevel == null
                              ? 'Save Level'
                              : 'Update Level',
                          icon: Icons.save_rounded,
                          color: const Color(0xFF4F46E5),
                          onTap: _save,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeBtn extends StatelessWidget {
  final String label;
  final Widget leading;
  final bool selected;
  final VoidCallback onTap;

  const _ModeBtn({
    required this.label,
    required this.leading,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              selected ? Colors.amber.withValues(alpha: 0.16) : Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? Colors.amber : Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.rubik(
                color: selected ? Colors.amber : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorAssetIcon extends StatelessWidget {
  final String assetPath;
  final double size;

  const _EditorAssetIcon({
    required this.assetPath,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ToolBtn(this.label, this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.rubik(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _DimensionControl extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _DimensionControl({
    required this.label,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.rubik(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$value',
                  style: GoogleFonts.bungee(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              _SmallIconButton(icon: Icons.add, onTap: onIncrease),
              const SizedBox(height: 6),
              _SmallIconButton(icon: Icons.remove, onTap: onDecrease),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SmallIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}

class _SettingsField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isNumber;

  const _SettingsField(this.label, this.controller, {this.isNumber = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.rubik(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.rubik(color: Colors.white54, fontSize: 12),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.rubik(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
