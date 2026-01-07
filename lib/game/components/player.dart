import 'package:flame/components.dart';
import 'package:flame/geometry.dart';
import 'package:flame/sprite.dart';

/// Represents the player in the puzzle game, handling movement, collision,
/// animations, health, and invulnerability logic.
class Player extends SpriteAnimationComponent with HasGameRef, Hitbox, Collidable {
  Vector2 _movement = Vector2.zero();
  double _speed = 150.0;
  bool _isInvulnerable = false;
  int _health = 3;
  final double _invulnerabilityTime = 2.0;
  double _currentInvulnerabilityTime = 0.0;

  Player()
      : super(size: Vector2(50.0, 50.0), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final spriteSheet = SpriteSheet(
      image: await gameRef.images.load('player_spritesheet.png'),
      srcSize: Vector2(50.0, 50.0),
    );
    animation = spriteSheet.createAnimation(row: 0, stepTime: 0.1, from: 0, to: 3);
    addShape(HitboxRectangle());
  }

  /// Updates the player's position, handles invulnerability timing, and checks for collisions.
  @override
  void update(double dt) {
    super.update(dt);
    if (_isInvulnerable) {
      _currentInvulnerabilityTime += dt;
      if (_currentInvulnerabilityTime >= _invulnerabilityTime) {
        _isInvulnerable = false;
        _currentInvulnerabilityTime = 0.0;
      }
    }
    position += _movement * _speed * dt;
  }

  /// Sets the movement direction of the player.
  void move(Vector2 direction) {
    _movement = direction;
  }

  /// Stops the player's movement.
  void stop() {
    _movement = Vector2.zero();
  }

  /// Handles collision with other [Collidable] objects.
  @override
  void onCollision(Set<Vector2> intersectionPoints, Collidable other) {
    if (other is Obstacle) {
      takeDamage();
    } else if (other is Collectible) {
      // Handle collectible logic, e.g., increase score or health.
    }
  }

  /// Reduces the player's health and triggers invulnerability.
  void takeDamage() {
    if (!_isInvulnerable) {
      _health -= 1;
      _isInvulnerable = true;
      if (_health <= 0) {
        // Handle player death, e.g., end game or respawn.
      }
    }
  }

  /// Returns whether the player is currently invulnerable.
  bool get isInvulnerable => _isInvulnerable;

  /// Returns the player's current health.
  int get health => _health;
}

/// Represents an obstacle in the game.
class Obstacle extends SpriteComponent with Hitbox, Collidable {
  Obstacle({required Vector2 position, required Vector2 size, required Sprite sprite})
      : super(position: position, size: size, sprite: sprite) {
    addShape(HitboxRectangle());
  }
}

/// Represents a collectible item in the game.
class Collectible extends SpriteComponent with Hitbox, Collidable {
  Collectible({required Vector2 position, required Vector2 size, required Sprite sprite})
      : super(position: position, size: size, sprite: sprite) {
    addShape(HitboxRectangle());
  }
}