/// Card Flip Mechanic
/// 
/// Card flipping for memory games

import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';


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

