import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';

/// Represents the main menu scene for the puzzle game.
class MenuScene extends Component with Tappable {
  late final TextComponent _title;
  late final TextComponent _playButton;
  late final TextComponent _levelSelect;
  late final TextComponent _settingsButton;
  late final SpriteComponent _backgroundAnimation;

  MenuScene() {
    _createComponents();
  }

  /// Initializes all components of the menu scene.
  void _createComponents() {
    _title = TextComponent(
      text: 'Decode Ancient Symbols',
      textRenderer: TextPaint(style: TextStyle(fontSize: 24.0, color: Colors.gold)),
      position: Vector2(100, 50),
    );

    _playButton = TextComponent(
      text: 'Play',
      textRenderer: TextPaint(style: TextStyle(fontSize: 20.0, color: Colors.white)),
      position: Vector2(100, 150),
    )..add(TapGestureRecognizer()..onTapUp = (details) => _onPlayTap());

    _levelSelect = TextComponent(
      text: 'Select Level',
      textRenderer: TextPaint(style: TextStyle(fontSize: 20.0, color: Colors.white)),
      position: Vector2(100, 250),
    )..add(TapGestureRecognizer()..onTapUp = (details) => _onLevelSelectTap());

    _settingsButton = TextComponent(
      text: 'Settings',
      textRenderer: TextPaint(style: TextStyle(fontSize: 20.0, color: Colors.white)),
      position: Vector2(100, 350),
    )..add(TapGestureRecognizer()..onTapUp = (details) => _onSettingsTap());

    // Assuming a sprite sheet for background animation is available.
    _backgroundAnimation = SpriteComponent()
      ..sprite = Sprite()
      ..size = Vector2(400, 600) // Assuming a full-screen background.
      ..position = Vector2.zero();
  }

  @override
  Future<void>? onLoad() async {
    super.onLoad();
    add(_backgroundAnimation);
    add(_title);
    add(_playButton);
    add(_levelSelect);
    add(_settingsButton);
  }

  /// Handles tap on the Play button.
  void _onPlayTap() {
    // Navigate to the game screen or start the game.
  }

  /// Handles tap on the Level Select option.
  void _onLevelSelectTap() {
    // Navigate to the level selection screen.
  }

  /// Handles tap on the Settings button.
  void _onSettingsTap() {
    // Navigate to the settings screen.
  }

  @override
  bool onTapUp(TapUpInfo info) {
    // Implement tap handling if needed for other components.
    return super.onTapUp(info);
  }
}