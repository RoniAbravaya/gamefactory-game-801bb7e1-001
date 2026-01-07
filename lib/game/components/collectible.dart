import 'dart:math' as math;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame_audio/flame_audio.dart';

/// Collectible item component for the puzzle game that represents ancient runes
/// and artifacts that can be collected for points and progression.
class Collectible extends SpriteComponent with HasCollisionDetection, CollisionCallbacks {
  /// The score value awarded when this collectible is picked up
  final int scoreValue;
  
  /// The type of collectible (rune, artifact, etc.)
  final CollectibleType type;
  
  /// Whether this collectible has been collected
  bool _isCollected = false;
  
  /// Whether the collectible should animate with floating motion
  final bool shouldFloat;
  
  /// Whether the collectible should animate with spinning motion
  final bool shouldSpin;
  
  /// Sound effect file path for collection
  final String? collectSoundPath;
  
  /// Callback function triggered when collectible is picked up
  final void Function(Collectible collectible)? onCollected;
  
  /// Original Y position for floating animation
  late double _originalY;
  
  /// Animation time tracker
  double _animationTime = 0.0;

  Collectible({
    required this.scoreValue,
    required this.type,
    required Vector2 position,
    required Vector2 size,
    required Sprite sprite,
    this.shouldFloat = true,
    this.shouldSpin = false,
    this.collectSoundPath,
    this.onCollected,
  }) : super(
          sprite: sprite,
          position: position,
          size: size,
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    try {
      // Add collision detection
      add(RectangleHitbox());
      
      // Store original position for floating animation
      _originalY = position.y;
      
      // Add spinning animation if enabled
      if (shouldSpin) {
        add(
          RotateEffect.by(
            2 * math.pi,
            EffectController(
              duration: 3.0,
              infinite: true,
            ),
          ),
        );
      }
      
      // Add scale pulse effect for mystical feel
      add(
        ScaleEffect.by(
          Vector2.all(1.1),
          EffectController(
            duration: 2.0,
            infinite: true,
            alternate: true,
          ),
        ),
      );
      
      await super.onLoad();
    } catch (e) {
      // Handle loading errors gracefully
      print('Error loading collectible: $e');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (_isCollected) return;
    
    // Update floating animation
    if (shouldFloat) {
      _animationTime += dt;
      final floatOffset = math.sin(_animationTime * 2.0) * 5.0;
      position.y = _originalY + floatOffset;
    }
  }

  @override
  bool onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    // Only collect if not already collected and colliding with player
    if (!_isCollected && _isPlayer(other)) {
      _collect();
      return true;
    }
    return false;
  }

  /// Checks if the colliding component is a player
  bool _isPlayer(PositionComponent component) {
    // This would typically check for a Player component type
    // For now, we'll use a simple class name check
    return component.runtimeType.toString().toLowerCase().contains('player');
  }

  /// Handles the collection of this item
  void _collect() async {
    if (_isCollected) return;
    
    _isCollected = true;
    
    try {
      // Play collection sound effect
      if (collectSoundPath != null) {
        await FlameAudio.play(collectSoundPath!);
      }
      
      // Trigger collection callback
      onCollected?.call(this);
      
      // Add collection animation effects
      await _playCollectionAnimation();
      
      // Remove from game after animation
      removeFromParent();
      
    } catch (e) {
      print('Error during collection: $e');
      // Still remove the component even if sound/animation fails
      removeFromParent();
    }
  }

  /// Plays the collection animation sequence
  Future<void> _playCollectionAnimation() async {
    try {
      // Scale up and fade out effect
      final scaleEffect = ScaleEffect.to(
        Vector2.all(1.5),
        EffectController(duration: 0.3),
      );
      
      final fadeEffect = OpacityEffect.to(
        0.0,
        EffectController(duration: 0.3),
      );
      
      // Add upward movement
      final moveEffect = MoveByEffect(
        Vector2(0, -20),
        EffectController(duration: 0.3),
      );
      
      add(scaleEffect);
      add(fadeEffect);
      add(moveEffect);
      
      // Wait for animation to complete
      await Future.delayed(const Duration(milliseconds: 300));
      
    } catch (e) {
      print('Error playing collection animation: $e');
    }
  }

  /// Gets the collectible type as a string for analytics
  String get typeString => type.toString().split('.').last;
  
  /// Whether this collectible has been collected
  bool get isCollected => _isCollected;
  
  /// Manually trigger collection (for testing or special cases)
  void forceCollect() {
    _collect();
  }
}

/// Enum defining different types of collectibles in the game
enum CollectibleType {
  /// Basic rune currency
  rune,
  
  /// Special ancient artifact
  artifact,
  
  /// Bonus time extension
  timeBonus,
  
  /// Hint token
  hintToken,
  
  /// Decoder upgrade component
  decoderUpgrade,
  
  /// Rare mystical gem
  mysticalGem,
}

/// Extension to get score values for different collectible types
extension CollectibleTypeExtension on CollectibleType {
  /// Gets the default score value for this collectible type
  int get defaultScoreValue {
    switch (this) {
      case CollectibleType.rune:
        return 10;
      case CollectibleType.artifact:
        return 100;
      case CollectibleType.timeBonus:
        return 25;
      case CollectibleType.hintToken:
        return 50;
      case CollectibleType.decoderUpgrade:
        return 200;
      case CollectibleType.mysticalGem:
        return 500;
    }
  }
  
  /// Gets the default sound effect path for this collectible type
  String get defaultSoundPath {
    switch (this) {
      case CollectibleType.rune:
        return 'audio/rune_collect.wav';
      case CollectibleType.artifact:
        return 'audio/artifact_collect.wav';
      case CollectibleType.timeBonus:
        return 'audio/time_bonus.wav';
      case CollectibleType.hintToken:
        return 'audio/hint_collect.wav';
      case CollectibleType.decoderUpgrade:
        return 'audio/upgrade_collect.wav';
      case CollectibleType.mysticalGem:
        return 'audio/gem_collect.wav';
    }
  }
}