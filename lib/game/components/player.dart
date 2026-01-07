import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/services.dart';

/// Player component for the puzzle game that handles the decoder beam aiming
/// and interaction with symbol cards
class Player extends SpriteAnimationComponent
    with HasKeyboardHandlerComponents, HasCollisionDetection, DragCallbacks {
  
  /// Current player health/lives
  int _lives = 3;
  
  /// Maximum lives allowed
  static const int maxLives = 3;
  
  /// Current score
  int _score = 0;
  
  /// Current runes (currency)
  int _runes = 0;
  
  /// Decoder beam range
  double _beamRange = 200.0;
  
  /// Decoder beam angle in radians
  double _beamAngle = 0.0;
  
  /// Whether the decoder beam is active
  bool _isBeamActive = false;
  
  /// Animation states
  late SpriteAnimation _idleAnimation;
  late SpriteAnimation _aimingAnimation;
  late SpriteAnimation _decodingAnimation;
  
  /// Current animation state
  PlayerState _currentState = PlayerState.idle;
  
  /// Callback for when player aims at a card
  Function(Vector2 targetPosition)? onAimAtCard;
  
  /// Callback for when player activates decoder beam
  Function(double angle, double range)? onActivateBeam;
  
  /// Callback for score changes
  Function(int newScore)? onScoreChanged;
  
  /// Callback for lives changes
  Function(int newLives)? onLivesChanged;
  
  /// Callback for runes changes
  Function(int newRunes)? onRunesChanged;

  @override
  Future<void> onLoad() async {
    try {
      // Load sprite animations
      await _loadAnimations();
      
      // Set initial animation
      animation = _idleAnimation;
      
      // Set up collision detection
      add(RectangleHitbox());
      
      // Set initial position (center bottom of screen)
      position = Vector2(
        gameRef.size.x / 2 - size.x / 2,
        gameRef.size.y - size.y - 50,
      );
      
      // Set anchor to center
      anchor = Anchor.center;
      
    } catch (e) {
      print('Error loading player: $e');
    }
  }

  /// Load all sprite animations for different states
  Future<void> _loadAnimations() async {
    // Load idle animation (ancient decoder at rest)
    _idleAnimation = await gameRef.loadSpriteAnimation(
      'player/decoder_idle.png',
      SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.5,
        textureSize: Vector2(64, 64),
      ),
    );
    
    // Load aiming animation (decoder charging up)
    _aimingAnimation = await gameRef.loadSpriteAnimation(
      'player/decoder_aiming.png',
      SpriteAnimationData.sequenced(
        amount: 6,
        stepTime: 0.2,
        textureSize: Vector2(64, 64),
      ),
    );
    
    // Load decoding animation (decoder beam active)
    _decodingAnimation = await gameRef.loadSpriteAnimation(
      'player/decoder_active.png',
      SpriteAnimationData.sequenced(
        amount: 8,
        stepTime: 0.1,
        textureSize: Vector2(64, 64),
      ),
    );
    
    // Set initial size
    size = Vector2(64, 64);
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Update animation based on current state
    _updateAnimation();
  }

  /// Update animation based on current player state
  void _updateAnimation() {
    SpriteAnimation targetAnimation;
    
    switch (_currentState) {
      case PlayerState.idle:
        targetAnimation = _idleAnimation;
        break;
      case PlayerState.aiming:
        targetAnimation = _aimingAnimation;
        break;
      case PlayerState.decoding:
        targetAnimation = _decodingAnimation;
        break;
    }
    
    if (animation != targetAnimation) {
      animation = targetAnimation;
    }
  }

  @override
  bool onDragStart(DragStartEvent event) {
    // Start aiming when drag begins
    _currentState = PlayerState.aiming;
    _isBeamActive = false;
    return true;
  }

  @override
  bool onDragUpdate(DragUpdateEvent event) {
    // Calculate beam angle based on drag direction
    final dragVector = event.localEndPosition - position;
    _beamAngle = dragVector.angleToSigned(Vector2(0, -1));
    
    // Notify game of aiming
    onAimAtCard?.call(event.localEndPosition);
    
    return true;
  }

  @override
  bool onDragEnd(DragEndEvent event) {
    // Activate decoder beam
    _currentState = PlayerState.decoding;
    _isBeamActive = true;
    
    // Notify game of beam activation
    onActivateBeam?.call(_beamAngle, _beamRange);
    
    // Return to idle after a delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _currentState = PlayerState.idle;
      _isBeamActive = false;
    });
    
    return true;
  }

  /// Add score to the player
  void addScore(int points) {
    _score += points;
    onScoreChanged?.call(_score);
  }

  /// Add runes to the player
  void addRunes(int amount) {
    _runes += amount;
    onRunesChanged?.call(_runes);
  }

  /// Spend runes for purchases
  bool spendRunes(int amount) {
    if (_runes >= amount) {
      _runes -= amount;
      onRunesChanged?.call(_runes);
      return true;
    }
    return false;
  }

  /// Take damage (lose a life)
  void takeDamage() {
    if (_lives > 0) {
      _lives--;
      onLivesChanged?.call(_lives);
    }
  }

  /// Restore a life
  void restoreLife() {
    if (_lives < maxLives) {
      _lives++;
      onLivesChanged?.call(_lives);
    }
  }

  /// Reset player to initial state
  void reset() {
    _lives = maxLives;
    _score = 0;
    _currentState = PlayerState.idle;
    _isBeamActive = false;
    _beamAngle = 0.0;
    
    onLivesChanged?.call(_lives);
    onScoreChanged?.call(_score);
  }

  /// Upgrade decoder beam range
  void upgradeBeamRange(double increase) {
    _beamRange += increase;
  }

  /// Get current lives
  int get lives => _lives;
  
  /// Get current score
  int get score => _score;
  
  /// Get current runes
  int get runes => _runes;
  
  /// Get current beam range
  double get beamRange => _beamRange;
  
  /// Get current beam angle
  double get beamAngle => _beamAngle;
  
  /// Check if beam is active
  bool get isBeamActive => _isBeamActive;
  
  /// Get current player state
  PlayerState get currentState => _currentState;
}

/// Enum for player animation states
enum PlayerState {
  idle,
  aiming,
  decoding,
}