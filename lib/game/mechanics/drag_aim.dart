/// Drag Aim Mechanic
/// 
/// Drag to aim, release to launch

import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';


class DragAimComponent extends PositionComponent {
  Vector2 dragStart = Vector2.zero();
  Vector2 dragCurrent = Vector2.zero();
  bool isDragging = false;
  double maxDragDistance = 150;
  
  void startDrag(Vector2 position) {
    dragStart = position;
    dragCurrent = position;
    isDragging = true;
  }
  
  void updateDrag(Vector2 position) {
    if (isDragging) {
      dragCurrent = position;
      // Clamp drag distance
      final delta = dragCurrent - dragStart;
      if (delta.length > maxDragDistance) {
        dragCurrent = dragStart + delta.normalized() * maxDragDistance;
      }
    }
  }
  
  Vector2 endDrag() {
    isDragging = false;
    final launchVector = (dragStart - dragCurrent) * 5; // Launch opposite to drag
    dragStart = Vector2.zero();
    dragCurrent = Vector2.zero();
    return launchVector;
  }
  
  @override
  void render(Canvas canvas) {
    if (isDragging) {
      // Draw aim line
      canvas.drawLine(
        dragStart.toOffset(),
        dragCurrent.toOffset(),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2,
      );
    }
  }
}

