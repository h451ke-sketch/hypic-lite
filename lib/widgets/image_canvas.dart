import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/edit_state.dart';
import '../models/liquify_point.dart';
import '../core/color_matrix_builder.dart';
import '../core/liquify_mesh.dart';
import '../core/blemish_brush.dart';
import 'bottom_toolbar.dart';

class ImageCanvas extends StatefulWidget {
  final Uint8List imageBytes;
  final EditState state;
  final MainTool activeTool;
  final LiquifyMode liquifyMode;
  final double liquifyRadius;
  final double liquifyStrength;
  final double blemishRadius;
  final bool isComparingOriginal;
  final Function(LiquifyAction) onLiquifyActionAdded;
  final Function(BlemishSpot) onBlemishSpotAdded;

  const ImageCanvas({
    super.key,
    required this.imageBytes,
    required this.state,
    required this.activeTool,
    required this.liquifyMode,
    required this.liquifyRadius,
    required this.liquifyStrength,
    required this.blemishRadius,
    required this.isComparingOriginal,
    required this.onLiquifyActionAdded,
    required this.onBlemishSpotAdded,
  });

  @override
  State<ImageCanvas> createState() => _ImageCanvasState();
}

class _ImageCanvasState extends State<ImageCanvas> {
  ui.Image? _decodedImage;
  LiquifyMesh? _mesh;
  Offset? _touchPosition;
  Offset? _panStartPosition;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant ImageCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageBytes != widget.imageBytes) {
      _loadImage();
    } else if (oldWidget.state.liquifyActions.length != widget.state.liquifyActions.length) {
      _rebuildMesh();
    }
  }

  Future<void> _loadImage() async {
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _decodedImage = frame.image;
        _rebuildMesh();
      });
    }
  }

  void _rebuildMesh() {
    if (_decodedImage == null) return;
    final size = Size(_decodedImage!.width.toDouble(), _decodedImage!.height.toDouble());
    _mesh = LiquifyMesh(size);
    _mesh!.applyActions(widget.state.liquifyActions);
  }

  @override
  Widget build(BuildContext context) {
    if (_decodedImage == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFD166)),
      );
    }

    final imgW = _decodedImage!.width.toDouble();
    final imgH = _decodedImage!.height.toDouble();

    // Check if touch gestures should route to Liquify or Blemish instead of Zoom
    final bool isLiquifyActive = widget.activeTool == MainTool.liquify;
    final bool isBlemishActive = widget.activeTool == MainTool.blemish;
    final bool isInteractive = !isLiquifyActive && !isBlemishActive;

    Widget imageDisplay = AspectRatio(
      aspectRatio: imgW / imgH,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boxWidth = constraints.maxWidth;
          final boxHeight = constraints.maxHeight;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            // Liquify Pan Gestures
            onPanStart: isLiquifyActive
                ? (details) {
                    setState(() {
                      _touchPosition = details.localPosition;
                      _panStartPosition = Offset(
                        details.localPosition.dx / boxWidth,
                        details.localPosition.dy / boxHeight,
                      );
                    });
                  }
                : null,
            onPanUpdate: isLiquifyActive
                ? (details) {
                    setState(() {
                      _touchPosition = details.localPosition;
                    });
                    if (_panStartPosition != null && _mesh != null) {
                      final currentNorm = Offset(
                        details.localPosition.dx / boxWidth,
                        details.localPosition.dy / boxHeight,
                      );
                      final action = LiquifyAction(
                        start: _panStartPosition!,
                        end: currentNorm,
                        radius: widget.liquifyRadius,
                        strength: widget.liquifyStrength,
                        mode: widget.liquifyMode,
                      );
                      _mesh!.applySingleAction(action);
                      setState(() {});
                    }
                  }
                : null,
            onPanEnd: isLiquifyActive
                ? (details) {
                    if (_panStartPosition != null && _touchPosition != null) {
                      final endNorm = Offset(
                        _touchPosition!.dx / boxWidth,
                        _touchPosition!.dy / boxHeight,
                      );
                      final action = LiquifyAction(
                        start: _panStartPosition!,
                        end: endNorm,
                        radius: widget.liquifyRadius,
                        strength: widget.liquifyStrength,
                        mode: widget.liquifyMode,
                      );
                      widget.onLiquifyActionAdded(action);
                    }
                    setState(() {
                      _touchPosition = null;
                      _panStartPosition = null;
                    });
                  }
                : null,

            // Blemish Tap Gesture
            onTapUp: isBlemishActive
                ? (details) {
                    final normPos = Offset(
                      details.localPosition.dx / boxWidth,
                      details.localPosition.dy / boxHeight,
                    );
                    final spot = BlemishSpot(
                      center: normPos,
                      radius: widget.blemishRadius,
                    );
                    widget.onBlemishSpotAdded(spot);
                    setState(() {
                      _touchPosition = details.localPosition;
                    });
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) setState(() => _touchPosition = null);
                    });
                  }
                : null,

            child: CustomPaint(
              size: Size(boxWidth, boxHeight),
              painter: _CanvasPainter(
                image: _decodedImage!,
                state: widget.state,
                mesh: _mesh,
                isComparing: widget.isComparingOriginal,
                touchPosition: _touchPosition,
                brushRadiusPx: isLiquifyActive
                    ? widget.liquifyRadius * boxWidth
                    : isBlemishActive
                        ? widget.blemishRadius * boxWidth
                        : null,
              ),
            ),
          );
        },
      ),
    );

    // Apply rotation & flip transforms
    Widget transformed = RotatedBox(
      quarterTurns: widget.isComparingOriginal ? 0 : widget.state.rotationQuarterTurns,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..scale(
            widget.isComparingOriginal || !widget.state.flipHorizontal ? 1.0 : -1.0,
            widget.isComparingOriginal || !widget.state.flipVertical ? 1.0 : -1.0,
          ),
        child: imageDisplay,
      ),
    );

    return Container(
      color: const Color(0xFF0A0A0A),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          isInteractive
              ? InteractiveViewer(
                  maxScale: 5.0,
                  minScale: 0.8,
                  child: Center(child: transformed),
                )
              : Center(child: transformed),

          // Original comparison watermark badge
          if (widget.isComparingOriginal)
            Positioned(
              top: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text(
                  '原图对比中',
                  style: TextStyle(
                    color: Color(0xFFFFD166),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final ui.Image image;
  final EditState state;
  final LiquifyMesh? mesh;
  final bool isComparing;
  final Offset? touchPosition;
  final double? brushRadiusPx;

  _CanvasPainter({
    required this.image,
    required this.state,
    required this.mesh,
    required this.isComparing,
    this.touchPosition,
    this.brushRadiusPx,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    final Paint paint = Paint()..filterQuality = FilterQuality.medium;

    // Apply GPU Color Filter Matrix
    if (!isComparing) {
      final matrix = ColorMatrixBuilder.build(state);
      paint.colorFilter = ColorFilter.matrix(matrix);
    }

    // Draw Liquify deformed mesh or standard image
    if (!isComparing && mesh != null && state.liquifyActions.isNotEmpty) {
      canvas.scale(size.width / image.width, size.height / image.height);
      paint.shader = ImageShader(
        image,
        TileMode.clamp,
        TileMode.clamp,
        Matrix4.identity().storage,
      );
      canvas.drawVertices(mesh!.toVertices(), paint);
    } else {
      final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
      final dst = Rect.fromLTWH(0, 0, size.width, size.height);
      canvas.drawImageRect(image, src, dst, paint);
    }

    canvas.restore();

    // Draw Blemish spots
    if (!isComparing && state.blemishSpots.isNotEmpty) {
      BlemishPainter.drawBlemishPatches(canvas, size, state.blemishSpots);
    }

    // Draw touch cursor indicator for Liquify & Blemish tools
    if (touchPosition != null && brushRadiusPx != null) {
      final ringPaint = Paint()
        ..color = const Color(0xFFFFD166).withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(touchPosition!, brushRadiusPx!, ringPaint);
      canvas.drawCircle(touchPosition!, 3.0, Paint()..color = const Color(0xFFFFD166));
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) => true;
}
