import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Obstacle component that blocks the decoder beam and can damage the player
/// Represents ancient temple hazards like rotating stone wheels, moving pillars, and energy barriers
class Obstacle extends PositionComponent with HasGameRef, CollisionCallbacks {
  /// Type of obstacle affecting behavior and appearance
  final ObstacleType type;
  
  /// Damage dealt to player on collision
  final int damage;
  
  /// Movement speed for moving obstacles
  final double moveSpeed;
  
  /// Whether this obstacle is currently active and can cause damage
  bool isActive = true;
  
  /// Visual representation of the obstacle
  late SpriteComponent _sprite;
  
  /// Collision detection hitbox
  late RectangleHitbox _hitbox;
  
  /// Movement direction for moving obstacles
  Vector2 _moveDirection = Vector2.zero();
  
  /// Rotation speed for rotating obstacles
  double _rotationSpeed = 0.0;
  
  /// Timer for pulsing energy barriers
  double _pulseTimer = 0.0;
  
  /// Original position for oscillating movement
  Vector2? _originalPosition;

  Obstacle({
    required this.type,
    required Vector2 position,
    required Vector2 size,
    this.damage = 1,
    this.moveSpeed = 50.0,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Initialize visual representation based on obstacle type
    await _initializeSprite();
    
    // Set up collision detection
    _hitbox = RectangleHitbox(
      size: size * 0.8, // Slightly smaller than visual for better gameplay feel
      position: size * 0.1, // Center the hitbox
    );
    add(_hitbox);
    
    // Initialize movement behavior
    _initializeMovement();
    
    // Store original position for oscillating obstacles
    _originalPosition = position.clone();
  }

  /// Initialize sprite based on obstacle type
  Future<void> _initializeSprite() async {
    try {
      String spritePath;
      switch (type) {
        case ObstacleType.stoneWheel:
          spritePath = 'obstacles/stone_wheel.png';
          _rotationSpeed = 2.0;
          break;
        case ObstacleType.movingPillar:
          spritePath = 'obstacles/stone_pillar.png';
          break;
        case ObstacleType.energyBarrier:
          spritePath = 'obstacles/energy_barrier.png';
          break;
        case ObstacleType.spikeTrap:
          spritePath = 'obstacles/spike_trap.png';
          break;
      }
      
      _sprite = SpriteComponent(
        sprite: await gameRef.loadSprite(spritePath),
        size: size,
      );
      add(_sprite);
      
      // Add visual effects based on type
      _addVisualEffects();
    } catch (e) {
      // Fallback to colored rectangle if sprite loading fails
      final rect = RectangleComponent(
        size: size,
        paint: Paint()..color = _getObstacleColor(),
      );
      add(rect);
    }
  }

  /// Initialize movement patterns based on obstacle type
  void _initializeMovement() {
    switch (type) {
      case ObstacleType.movingPillar:
        // Horizontal movement
        _moveDirection = Vector2(1, 0);
        break;
      case ObstacleType.energyBarrier:
        // Pulsing effect
        _pulseTimer = 0.0;
        break;
      case ObstacleType.stoneWheel:
      case ObstacleType.spikeTrap:
        // Static or rotation only
        break;
    }
  }

  /// Add visual effects specific to obstacle type
  void _addVisualEffects() {
    switch (type) {
      case ObstacleType.energyBarrier:
        // Add glowing effect
        final glowEffect = ColorEffect(
          const Color(0xFF00FFFF),
          const Offset(0.5, 0.5),
          EffectController(
            duration: 1.0,
            alternate: true,
            infinite: true,
          ),
        );
        _sprite.add(glowEffect);
        break;
      case ObstacleType.stoneWheel:
        // Add rotation effect
        final rotateEffect = RotateEffect.by(
          2 * math.pi,
          EffectController(
            duration: 3.0,
            infinite: true,
          ),
        );
        _sprite.add(rotateEffect);
        break;
      default:
        break;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (!isActive) return;
    
    // Update movement based on obstacle type
    switch (type) {
      case ObstacleType.movingPillar:
        _updateMovingPillar(dt);
        break;
      case ObstacleType.energyBarrier:
        _updateEnergyBarrier(dt);
        break;
      case ObstacleType.stoneWheel:
        _updateStoneWheel(dt);
        break;
      case ObstacleType.spikeTrap:
        _updateSpikeTrap(dt);
        break;
    }
  }

  /// Update moving pillar behavior
  void _updateMovingPillar(dt) {
    final newPosition = position + (_moveDirection * moveSpeed * dt);
    
    // Reverse direction at boundaries
    if (newPosition.x <= 0 || newPosition.x >= gameRef.size.x - size.x) {
      _moveDirection.x *= -1;
    }
    if (newPosition.y <= 0 || newPosition.y >= gameRef.size.y - size.y) {
      _moveDirection.y *= -1;
    }
    
    position = newPosition;
  }

  /// Update energy barrier pulsing effect
  void _updateEnergyBarrier(dt) {
    _pulseTimer += dt;
    final pulseIntensity = (math.sin(_pulseTimer * 3) + 1) / 2;
    
    // Modulate opacity based on pulse
    _sprite.paint.color = _sprite.paint.color.withOpacity(0.5 + pulseIntensity * 0.5);
  }

  /// Update stone wheel rotation
  void _updateStoneWheel(dt) {
    angle += _rotationSpeed * dt;
  }

  /// Update spike trap activation
  void _updateSpikeTrap(dt) {
    // Spike traps could have periodic activation patterns
    _pulseTimer += dt;
    if (_pulseTimer > 2.0) {
      _pulseTimer = 0.0;
      // Trigger spike animation or effect
    }
  }

  @override
  bool onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (!isActive) return false;
    
    // Handle collision with player or decoder beam
    if (other is HasCollisionDetection) {
      _handleCollision(other);
      return true;
    }
    
    return false;
  }

  /// Handle collision with other components
  void _handleCollision(PositionComponent other) {
    try {
      // Deal damage or block decoder beam
      if (other.hasComponent<PlayerComponent>()) {
        _dealDamageToPlayer(other);
      } else if (other.hasComponent<DecoderBeamComponent>()) {
        _blockDecoderBeam(other);
      }
      
      // Add collision visual effect
      _addCollisionEffect();
    } catch (e) {
      // Handle collision error gracefully
      print('Obstacle collision error: $e');
    }
  }

  /// Deal damage to player component
  void _dealDamageToPlayer(PositionComponent player) {
    // Trigger damage event
    gameRef.add(DamageEvent(damage: damage, position: position.clone()));
    
    // Add screen shake effect
    gameRef.camera.viewfinder.add(
      MoveEffect.by(
        Vector2(5, 0),
        EffectController(
          duration: 0.1,
          alternate: true,
          repeatCount: 3,
        ),
      ),
    );
  }

  /// Block decoder beam
  void _blockDecoderBeam(PositionComponent beam) {
    // Stop or deflect the beam
    beam.removeFromParent();
    
    // Add spark effect at collision point
    _addSparkEffect();
  }

  /// Add visual effect when collision occurs
  void _addCollisionEffect() {
    final effect = ScaleEffect.by(
      Vector2.all(1.2),
      EffectController(
        duration: 0.2,
        alternate: true,
      ),
    );
    add(effect);
  }

  /// Add spark effect for beam collision
  void _addSparkEffect() {
    // Create particle effect or sprite animation
    final sparkEffect = SpriteAnimationComponent(
      animation: SpriteAnimation.spriteList(
        [], // Spark animation sprites
        stepTime: 0.1,
        loop: false,
      ),
      position: size / 2,
      size: Vector2.all(32),
    );
    add(sparkEffect);
  }

  /// Get fallback color for obstacle type
  Color _getObstacleColor() {
    switch (type) {
      case ObstacleType.stoneWheel:
        return const Color(0xFF8B6914);
      case ObstacleType.movingPillar:
        return const Color(0xFF4A4A4A);
      case ObstacleType.energyBarrier:
        return const Color(0xFF00FFFF);
      case ObstacleType.spikeTrap:
        return const Color(0xFF2C1810);
    }
  }

  /// Activate the obstacle
  void activate() {
    isActive = true;
    _sprite.paint.color = _sprite.paint.color.withOpacity(1.0);
  }

  /// Deactivate the obstacle
  void deactivate() {
    isActive = false;
    _sprite.paint.color = _sprite.paint.color.withOpacity(0.5);
  }

  /// Destroy the obstacle with animation
  void destroy() {
    isActive = false;
    
    final destroyEffect = RemoveEffect(
      delay: 0.5,
    );
    
    final fadeEffect = OpacityEffect.fadeOut(
      EffectController(duration: 0.5),
    );
    
    add(destroyEffect);
    add(fadeEffect);
  }
}

/// Types of obstacles in the puzzle game
enum ObstacleType {
  /// Rotating stone wheel that blocks decoder beams
  stoneWheel,
  
  /// Moving stone pillar that can crush the player
  movingPillar,
  
  /// Pulsing energy barrier that deflects beams
  energyBarrier,
  
  /// Spike trap that damages on contact
  spikeTrap,
}

/// Placeholder components referenced in collision handling
mixin PlayerComponent on Component {}
mixin DecoderBeamComponent on Component {}

/// Damage event for game state management
class DamageEvent extends Component {
  final int damage;
  final Vector2 position;
  
  DamageEvent({required this.damage, required this.position});
}