import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

import 'models/edit_state.dart';
import 'models/liquify_point.dart';
import 'widgets/bottom_toolbar.dart';
import 'widgets/image_canvas.dart';
import 'widgets/adjust_panel.dart';
import 'widgets/filter_panel.dart';
import 'widgets/curve_panel.dart';
import 'widgets/hsl_panel.dart';
import 'widgets/beauty_panel.dart';
import 'widgets/liquify_panel.dart';
import 'widgets/blemish_panel.dart';
import 'widgets/crop_panel.dart';
import 'core/image_exporter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const HypicLiteApp());
}

class HypicLiteApp extends StatelessWidget {
  const HypicLiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '醒图Lite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD166),
          surface: Color(0xFF1E1E1E),
        ),
      ),
      home: const EditorHomeScreen(),
    );
  }
}

class EditorHomeScreen extends StatefulWidget {
  const EditorHomeScreen({super.key});

  @override
  State<EditorHomeScreen> createState() => _EditorHomeScreenState();
}

class _EditorHomeScreenState extends State<EditorHomeScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;

  // Edit State & History Stack
  EditState _currentState = EditState();
  final List<EditState> _undoStack = [];
  final List<EditState> _redoStack = [];

  // Active Tool & Tool Params
  MainTool _activeTool = MainTool.filter;
  LiquifyMode _liquifyMode = LiquifyMode.push;
  double _liquifyRadius = 0.15;
  double _liquifyStrength = 0.5;
  double _blemishRadius = 0.035;

  bool _isComparing = false;
  bool _isExporting = false;

  void _pushState(EditState newState) {
    _undoStack.add(_currentState.copy());
    _redoStack.clear();
    setState(() {
      _currentState = newState;
    });
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    final prev = _undoStack.removeLast();
    _redoStack.add(_currentState.copy());
    setState(() {
      _currentState = prev;
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    final next = _redoStack.removeLast();
    _undoStack.add(_currentState.copy());
    setState(() {
      _currentState = next;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 4096,
        maxHeight: 4096,
        imageQuality: 100,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _currentState = EditState();
          _undoStack.clear();
          _redoStack.clear();
        });
      }
    } catch (e) {
      _showToast('选择图片失败: $e');
    }
  }

  void _loadDemoPortrait() {
    // Generate an instant high-quality procedural test image
    final sample = img.Image(width: 800, height: 1000);
    for (int y = 0; y < 1000; y++) {
      for (int x = 0; x < 800; x++) {
        // Soft portrait gradient with facial highlights
        double dx = (x - 400) / 400.0;
        double dy = (y - 450) / 450.0;
        double dist = (dx * dx + dy * dy);

        int r = (235 - (dist * 70)).round().clamp(130, 245);
        int g = (195 - (dist * 80)).round().clamp(100, 210);
        int b = (175 - (dist * 90)).round().clamp(90, 190);

        // Highlight eyes & cheek area
        if ((y - 380).abs() < 40 && ((x - 300).abs() < 50 || (x - 500).abs() < 50)) {
          r = (r + 20).clamp(0, 255);
          g = (g + 20).clamp(0, 255);
          b = (b + 20).clamp(0, 255);
        }

        sample.setPixelRgb(x, y, r, g, b);
      }
    }
    setState(() {
      _imageBytes = Uint8List.fromList(img.encodeJpg(sample, quality: 90));
      _currentState = EditState();
      _undoStack.clear();
      _redoStack.clear();
    });
  }

  Future<void> _exportAndSave() async {
    if (_imageBytes == null) return;
    setState(() => _isExporting = true);

    try {
      final savedPath = await ImageExporter.exportImage(
        originalBytes: _imageBytes!,
        state: _currentState,
      );

      if (mounted) {
        setState(() => _isExporting = false);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF222222),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFFFFD166)),
                SizedBox(width: 8),
                Text('导出高清照片成功', style: TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('已完成全分辨率无损渲染处理并保存至本地文件：', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                SelectableText(
                  savedPath,
                  style: const TextStyle(color: Color(0xFFFFD166), fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('完成', style: TextStyle(color: Color(0xFFFFD166))),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        _showToast('保存失败: $e');
      }
    }
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF333333),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _imageBytes == null ? _buildWelcomeView() : _buildEditorView(),
      ),
    );
  }

  Widget _buildWelcomeView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD166), Color(0xFFFF6B6B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD166).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome, size: 48, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            const Text(
              '醒图 Lite',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              '纯本地离线修图与人像美颜神器\n零云端收费 · 120FPS GPU渲染 · 隐私安全',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.white60, height: 1.5),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.photo_library_rounded, color: Colors.black),
              label: const Text('从手机相册导入照片', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD166),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              onPressed: () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
              label: const Text('拍摄新照片', style: TextStyle(color: Colors.white)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF444444)),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              onPressed: () => _pickImage(ImageSource.camera),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: _loadDemoPortrait,
              child: const Text('使用演示人像测试体验', style: TextStyle(color: Color(0xFFFFD166), fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorView() {
    return Column(
      children: [
        // Top Header
        _buildTopBar(),

        // Canvas Area
        Expanded(
          child: Stack(
            children: [
              ImageCanvas(
                imageBytes: _imageBytes!,
                state: _currentState,
                activeTool: _activeTool,
                liquifyMode: _liquifyMode,
                liquifyRadius: _liquifyRadius,
                liquifyStrength: _liquifyStrength,
                blemishRadius: _blemishRadius,
                isComparingOriginal: _isComparing,
                onLiquifyActionAdded: (action) {
                  _undoStack.add(_currentState.copy());
                  _redoStack.clear();
                  setState(() {
                    _currentState.liquifyActions.add(action);
                  });
                },
                onBlemishSpotAdded: (spot) {
                  _undoStack.add(_currentState.copy());
                  _redoStack.clear();
                  setState(() {
                    _currentState.blemishSpots.add(spot);
                  });
                },
              ),

              // Export Loading Overlay
              if (_isExporting)
                Container(
                  color: Colors.black.withOpacity(0.7),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFFFFD166)),
                        SizedBox(height: 16),
                        Text('正在渲染全尺寸无损画质...', style: TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Secondary Adjustment Tool Panel
        _buildActiveSubPanel(),

        // Primary Bottom Toolbar
        BottomToolbar(
          activeTool: _activeTool,
          onToolSelected: (tool) => setState(() => _activeTool = tool),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        border: Border(bottom: BorderSide(color: Color(0xFF222222))),
      ),
      child: Row(
        children: [
          // Re-pick image
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white70),
            tooltip: '返回更换照片',
            onPressed: () => setState(() => _imageBytes = null),
          ),
          const Spacer(),

          // Undo / Redo
          IconButton(
            icon: const Icon(Icons.undo_rounded, size: 20),
            color: _undoStack.isNotEmpty ? Colors.white : Colors.white24,
            tooltip: '撤销',
            onPressed: _undoStack.isNotEmpty ? _undo : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo_rounded, size: 20),
            color: _redoStack.isNotEmpty ? Colors.white : Colors.white24,
            tooltip: '重做',
            onPressed: _redoStack.isNotEmpty ? _redo : null,
          ),

          // Compare with Original (Hold to compare)
          GestureDetector(
            onLongPressStart: (_) => setState(() => _isComparing = true),
            onLongPressEnd: (_) => setState(() => _isComparing = false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: _isComparing ? const Color(0xFFFFD166) : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '长按对比',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _isComparing ? Colors.black : Colors.white70,
                ),
              ),
            ),
          ),

          const Spacer(),

          // Save / Export Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD166),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _exportAndSave,
            child: const Text('保存', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSubPanel() {
    switch (_activeTool) {
      case MainTool.filter:
        return FilterPanel(
          state: _currentState,
          onStateChanged: () => setState(() {}),
        );
      case MainTool.adjust:
        return AdjustPanel(
          state: _currentState,
          onStateChanged: () => setState(() {}),
        );
      case MainTool.curves:
        return CurvePanel(
          state: _currentState,
          onStateChanged: () => setState(() {}),
        );
      case MainTool.hsl:
        return HslPanel(
          state: _currentState,
          onStateChanged: () => setState(() {}),
        );
      case MainTool.beauty:
        return BeautyPanel(
          state: _currentState,
          onStateChanged: () => setState(() {}),
        );
      case MainTool.liquify:
        return LiquifyPanel(
          state: _currentState,
          activeMode: _liquifyMode,
          brushRadius: _liquifyRadius,
          brushStrength: _liquifyStrength,
          onModeChanged: (m) => setState(() => _liquifyMode = m),
          onRadiusChanged: (r) => setState(() => _liquifyRadius = r),
          onStrengthChanged: (s) => setState(() => _liquifyStrength = s),
          onResetLiquify: () {
            _undoStack.add(_currentState.copy());
            _redoStack.clear();
            setState(() => _currentState.liquifyActions.clear());
          },
        );
      case MainTool.blemish:
        return BlemishPanel(
          state: _currentState,
          brushRadius: _blemishRadius,
          onRadiusChanged: (r) => setState(() => _blemishRadius = r),
          onUndoSpot: () {
            if (_currentState.blemishSpots.isNotEmpty) {
              _undoStack.add(_currentState.copy());
              _redoStack.clear();
              setState(() => _currentState.blemishSpots.removeLast());
            }
          },
          onClearAllSpots: () {
            _undoStack.add(_currentState.copy());
            _redoStack.clear();
            setState(() => _currentState.blemishSpots.clear());
          },
        );
      case MainTool.crop:
        return CropPanel(
          state: _currentState,
          onStateChanged: () => setState(() {}),
        );
    }
  }
}
