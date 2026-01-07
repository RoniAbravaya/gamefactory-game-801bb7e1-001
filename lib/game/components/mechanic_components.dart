/// Mechanic Components
/// 
/// Auto-generated components for game mechanics.

import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/input.dart';
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


class FlipCard extends PositionComponent with TapCallbacks {
  final Sprite frontSprite;
  final Sprite backSprite;
  bool isFaceUp = false;
  bool isMatched = false;
  final int cardId;
  double _flipProgress = 0;
  bool _isFlipping = false;
  
  FlipCard({
    required this.frontSprite,
    required this.backSprite,
    required this.cardId,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);
  
  void flip() {
    if (_isFlipping || isMatched) return;
    _isFlipping = true;
  }
  
  @override
  void update(double dt) {
    if (_isFlipping) {
      _flipProgress += dt * 4; // Flip speed
      
      if (_flipProgress >= 0.5 && !isFaceUp) {
        isFaceUp = true;
      }
      
      if (_flipProgress >= 1.0) {
        _flipProgress = 0;
        _isFlipping = false;
      }
    }
  }
  
  @override
  void render(Canvas canvas) {
    final scale = (_flipProgress < 0.5)
        ? 1 - _flipProgress * 2
        : (_flipProgress - 0.5) * 2;
    
    canvas.save();
    canvas.scale(scale, 1);
    
    final sprite = isFaceUp ? frontSprite : backSprite;
    sprite.render(canvas, size: size);
    
    canvas.restore();
  }
  
  @override
  void onTapUp(TapUpEvent event) {
    flip();
  }
}

