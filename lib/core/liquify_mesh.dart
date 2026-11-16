import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/liquify_point.dart';

class LiquifyMesh {
  static const int gridX = 30;
  static const int gridY = 30;

  final Size imageSize;
  late List<Offset> originalPositions;
  late List<Offset> deformedPositions;
  late List<int> indices;

  LiquifyMesh(this.imageSize) {
    _initMesh();
  }

  void _initMesh() {
    originalPositions = [];
    deformedPositions = [];
    indices = [];

    double dx = imageSize.width / gridX;
    double dy = imageSize.height / gridY;

    for (int y = 0; y <= gridY; y++) {
      for (int x = 0; x <= gridX; x++) {
        Offset pt = Offset(x * dx, y * dy);
        originalPositions.add(pt);
        deformedPositions.add(pt);
      }
    }

    // Build triangle indices
    for (int y = 0; y < gridY; y++) {
      for (int x = 0; x < gridX; x++) {
        int i0 = y * (gridX + 1) + x;
        int i1 = i0 + 1;
        int i2 = i0 + (gridX + 1);
        int i3 = i2 + 1;

        // Triangle 1
        indices.add(i0);
        indices.add(i2);
        indices.add(i1);

        // Triangle 2
        indices.add(i1);
        indices.add(i2);
        indices.add(i3);
      }
    }
  }

  void reset() {
    for (int i = 0; i < originalPositions.length; i++) {
      deformedPositions[i] = originalPositions[i];
    }
  }

  /// Rebuilds entire mesh from a list of LiquifyActions
  void applyActions(List<LiquifyAction> actions) {
    reset();
    for (var action in actions) {
      applySingleAction(action);
    }
  }

  /// Applies a single action to the mesh in place
  void applySingleAction(LiquifyAction action) {
    double r = action.radius * max(imageSize.width, imageSize.height);
    double rSq = r * r;

    Offset startPx = Offset(
      action.start.dx * imageSize.width,
      action.start.dy * imageSize.height,
    );
    Offset endPx = Offset(
      action.end.dx * imageSize.width,
      action.end.dy * imageSize.height,
    );
    Offset delta = endPx - startPx;

    for (int i = 0; i < deformedPositions.length; i++) {
      Offset pos = deformedPositions[i];
      double distSq = (pos - startPx).distanceSquared;

      if (distSq < rSq) {
        double dist = sqrt(distSq);
        double factor = (1.0 - (dist / r));
        double weight = factor * factor * action.strength;

        switch (action.mode) {
          case LiquifyMode.push:
            deformedPositions[i] = pos + delta * weight;
            break;

          case LiquifyMode.shrink:
            Offset dir = startPx - pos;
            deformedPositions[i] = pos + dir * (weight * 0.4);
            break;

          case LiquifyMode.enlarge:
            Offset dir = pos - startPx;
            if (dir == Offset.zero) dir = const Offset(1, 0);
            deformedPositions[i] = pos + dir * (weight * 0.4);
            break;

          case LiquifyMode.restore:
            Offset orig = originalPositions[i];
            deformedPositions[i] = Offset.lerp(pos, orig, weight * 0.5)!;
            break;
        }
      }
    }
  }

  /// Creates a GPU Vertices object for Canvas.drawVertices
  ui.Vertices toVertices() {
    return ui.Vertices(
      ui.VertexMode.triangles,
      deformedPositions,
      textureCoordinates: originalPositions,
      indices: indices,
    );
  }
}
