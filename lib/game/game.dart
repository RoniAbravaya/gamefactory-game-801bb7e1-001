import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/geometry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Main game class for the ancient symbol decoding puzzle game
class Batch20260107122649Puzzle01Game extends FlameGame
    with HasDragEvents, HasTapEvents, HasCollisionDetection {
  
  /// Current game state
  GameState _gameState = GameState.loading;
  GameState get gameState => _gameState;
  
  /// Current level being played
  int _currentLevel = 1;
  int get currentLevel => _currentLevel;
  
  /// Player's current score
  int _score = 0;
  int get score => _score;
  
  /// Player's rune currency
  int _runes = 0;
  int get runes => _runes;
  
  /// Level timer
  late Timer _levelTimer;
  double _timeRemaining = 0;
  double get timeRemaining => _timeRemaining;
  
  /// Wrong attempts counter
  int _wrongAttempts = 0;
  static const int maxWrongAttempts = 3;
  
  /// Game components
  late DecoderBeam _decoderBeam;
  final List<SymbolCard> _symbolCards = [];
  late WordInputComponent _wordInput;
  late GameUI _gameUI;
  
  /// Level configuration
  late LevelConfig _currentLevelConfig;
  
  /// Analytics and services hooks
  Function(String event, Map<String, dynamic> parameters)? onAnalyticsEvent;
  Function()? onShowRewardedAd;
  Function(String key, dynamic value)? onSaveData;
  Function(String key)? onLoadData;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Initialize collision detection
    add(ScreenHitbox());
    
    // Load initial level
    await _loadLevel(_currentLevel);
    
    // Initialize UI
    _gameUI = GameUI(game: this);
    add(_gameUI);
    
    // Track game start
    _trackEvent('game_start', {
      'level': _currentLevel,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    _changeGameState(GameState.playing);
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (_gameState == GameState.playing) {
      _levelTimer.update(dt);
      _timeRemaining = _levelTimer.limit - _levelTimer.current;
      
      if (_timeRemaining <= 0) {
        _handleTimeExpired();
      }
    }
  }

  /// Load a specific level
  Future<void> _loadLevel(int levelNumber) async {
    try {
      _currentLevelConfig = _generateLevelConfig(levelNumber);
      
      // Clear existing components
      _symbolCards.clear();
      removeWhere((component) => component is SymbolCard || 
                                 component is DecoderBeam || 
                                 component is WordInputComponent);
      
      // Create decoder beam
      _decoderBeam = DecoderBeam(
        position: Vector2(size.x * 0.5, size.y * 0.8),
        game: this,
      );
      add(_decoderBeam);
      
      // Create symbol cards
      await _createSymbolCards();
      
      // Create word input
      _wordInput = WordInputComponent(
        position: Vector2(size.x * 0.5, size.y * 0.9),
        expectedWord: _currentLevelConfig.targetWord,
        onWordSubmitted: _handleWordSubmission,
      );
      add(_wordInput);
      
      // Initialize timer
      _levelTimer = Timer(
        _currentLevelConfig.timeLimit,
        onTick: _handleTimeExpired,
        autoStart: false,
      );
      
      _timeRemaining = _currentLevelConfig.timeLimit;
      _wrongAttempts = 0;
      
      _trackEvent('level_start', {
        'level': levelNumber,
        'word_length': _currentLevelConfig.targetWord.length,
        'card_count': _currentLevelConfig.cardCount,
        'time_limit': _currentLevelConfig.timeLimit,
      });
      
    } catch (e) {
      debugPrint('Error loading level $levelNumber: $e');
      _changeGameState(GameState.gameOver);
    }
  }

  /// Create symbol cards for the current level
  Future<void> _createSymbolCards() async {
    final cardPositions = _calculateCardPositions(_currentLevelConfig.cardCount);
    final letters = _currentLevelConfig.targetWord.split('');
    
    // Add decoy letters if specified
    final allLetters = List<String>.from(letters);
    for (int i = 0; i < _currentLevelConfig.decoyCount; i++) {
      allLetters.add(String.fromCharCode(65 + (i % 26))); // A-Z
    }
    allLetters.shuffle();
    
    for (int i = 0; i < _currentLevelConfig.cardCount; i++) {
      final card = SymbolCard(
        position: cardPositions[i],
        hiddenLetter: allLetters[i % allLetters.length],
        symbolIndex: i % 10, // Cycle through available symbols
        onFlipped: _handleCardFlipped,
      );
      
      _symbolCards.add(card);
      add(card);
    }
  }

  /// Calculate positions for symbol cards in a grid layout
  List<Vector2> _calculateCardPositions(int cardCount) {
    final positions = <Vector2>[];
    final cols = (cardCount / 2).ceil().clamp(2, 4);
    final rows = (cardCount / cols).ceil();
    
    final cardWidth = 80.0;
    final cardHeight = 100.0;
    final spacing = 20.0;
    
    final totalWidth = (cols * cardWidth) + ((cols - 1) * spacing);
    final totalHeight = (rows * cardHeight) + ((rows - 1) * spacing);
    
    final startX = (size.x - totalWidth) / 2;
    final startY = (size.y - totalHeight) / 2 - 50;
    
    for (int i = 0; i < cardCount; i++) {
      final row = i ~/ cols;
      final col = i % cols;
      
      positions.add(Vector2(
        startX + (col * (cardWidth + spacing)) + (cardWidth / 2),
        startY + (row * (cardHeight + spacing)) + (cardHeight / 2),
      ));
    }
    
    return positions;
  }

  /// Generate level configuration based on difficulty curve
  LevelConfig _generateLevelConfig(int level) {
    final baseWords = [
      'RUNE', 'MAGIC', 'TEMPLE', 'ANCIENT', 'MYSTICAL',
      'ARTIFACT', 'GUARDIAN', 'PROPHECY', 'ENCHANTED', 'HIEROGLYPH'
    ];
    
    final word = baseWords[(level - 1) % baseWords.length];
    final cardCount = (3 + (level - 1) * 0.9).round().clamp(3, 12);
    final timeLimit = level <= 3 ? 0 : (150 - (level * 10)).toDouble().clamp(60, 120);
    final decoyCount = level > 3 ? ((level - 3) * 0.5).round() : 0;
    
    return LevelConfig(
      level: level,
      targetWord: word,
      cardCount: cardCount,
      timeLimit: timeLimit,
      decoyCount: decoyCount,
      hasRotatingSymbols: level > 7,
    );
  }

  @override
  bool onDragStart(DragStartEvent event) {
    if (_gameState != GameState.playing) return false;
    
    _decoderBeam.startAiming(event.localPosition);
    
    // Start timer on first interaction
    if (!_levelTimer.isRunning && _currentLevelConfig.timeLimit > 0) {
      _levelTimer.start();
    }
    
    return true;
  }

  @override
  bool onDragUpdate(DragUpdateEvent event) {
    if (_gameState != GameState.playing) return false;
    
    _decoderBeam.updateAiming(event.localPosition);
    return true;
  }

  @override
  bool onDragEnd(DragEndEvent event) {
    if (_gameState != GameState.playing) return false;
    
    _decoderBeam.fireBeam();
    return true;
  }

  /// Handle card being flipped by decoder beam
  void _handleCardFlipped(SymbolCard card) {
    if (_gameState != GameState.playing) return;
    
    HapticFeedback.lightImpact();
    _addScore(10);
    
    // Check if all required letters are revealed
    final revealedLetters = _symbolCards
        .where((card) => card.isFlipped)
        .map((card) => card.hiddenLetter)
        .toList();
    
    if (_hasAllRequiredLetters(revealedLetters)) {
      _wordInput.enableInput();
    }
  }

  /// Check if all letters needed for the target word are revealed
  bool _hasAllRequiredLetters(List<String> revealedLetters) {
    final targetLetters = _currentLevelConfig.targetWord.split('');
    for (final letter in targetLetters) {
      if (!revealedLetters.contains(letter)) {
        return false;
      }
    }
    return true;
  }

  /// Handle word submission
  void _handleWordSubmission(String submittedWord) {
    if (_gameState != GameState.playing) return;
    
    if (submittedWord.toUpperCase() == _currentLevelConfig.targetWord) {
      _handleLevelComplete();
    } else {
      _handleWrongAnswer();
    }
  }

  /// Handle correct word submission
  void _handleLevelComplete() {
    _changeGameState(GameState.levelComplete);
    
    final timeBonus = (_timeRemaining * 5).round();
    _addScore(100 + timeBonus);
    _addRunes(50);
    
    HapticFeedback.mediumImpact();
    
    _trackEvent('level_complete', {
      'level': _currentLevel,
      'time_remaining': _timeRemaining,
      'score': _score,
      'attempts': _wrongAttempts + 1,
    });
    
    // Show level complete overlay
    overlays.add('LevelComplete');
  }

  /// Handle wrong answer submission
  void _handleWrongAnswer() {
    _wrongAttempts++;
    HapticFeedback.heavyImpact();
    
    if (_wrongAttempts >= maxWrongAttempts) {
      _handleGameOver('maximum_wrong_attempts_reached');
    } else {
      // Show wrong answer feedback
      _wordInput.showWrongAnswerFeedback();
    }
  }

  /// Handle time expiration
  void _handleTimeExpired() {
    _handleGameOver('timer_expires');
  }

  /// Handle game over conditions
  void _handleGameOver(String reason) {
    _changeGameState(GameState.gameOver);
    
    _trackEvent('level_fail', {
      'level': _currentLevel,
      'reason': reason,
      'time_remaining': _timeRemaining,
      'wrong_attempts': _wrongAttempts,
    });
    
    overlays.add('GameOver');
  }

  /// Restart current level
  void restartLevel() {
    overlays.remove('GameOver');
    _loadLevel(_currentLevel);
    _changeGameState(GameState.playing);
  }

  /// Advance to next level
  void nextLevel() {
    overlays.remove('LevelComplete');
    
    if (_currentLevel >= 3 && _currentLevel < 10) {
      // Show unlock prompt for locked levels
      _trackEvent('unlock_prompt_shown', {'level': _currentLevel + 1});
      overlays.add('UnlockPrompt');
    } else {
      _proceedToNextLevel();
    }
  }

  /// Proceed to next level after unlock
  void _proceedToNextLevel() {
    _currentLevel++;
    _loadLevel(_currentLevel);
    _changeGameState(GameState.playing);
  }

  /// Show rewarded ad to unlock level
  void showRewardedAdForUnlock() {
    _trackEvent('rewarded_ad_started', {'level': _currentLevel + 1});
    onShowRewardedAd?.call();
  }

  /// Handle successful ad completion
  void onRewardedAdCompleted() {
    _trackEvent('rewarded_ad_completed', {'level': _currentLevel + 1});
    _trackEvent('level_unlocked', {'level': _currentLevel + 1});
    
    overlays.remove('UnlockPrompt');
    _proceedToNextLevel();
  }

  /// Handle ad failure
  void onRewardedAdFailed() {
    _trackEvent('rewarded_ad_failed', {'level': _currentLevel + 1});
    overlays.remove('UnlockPrompt');
  }

  /// Add to player score
  void _addScore(int points) {
    _score += points;
    _saveData('score', _score);
  }

  /// Add to player runes
  void _addRunes(int amount) {
    _runes += amount;
    _saveData('runes', _runes);
  }

  /// Change game state
  void _changeGameState(GameState newState) {
    _gameState = newState;
    
    switch (newState) {
      case GameState.playing:
        overlays.remove('PauseMenu');
        break;
      case GameState.paused:
        overlays.add('PauseMenu');
        break;
      case GameState.gameOver:
        _levelTimer.stop();
        break;
      case GameState.levelComplete:
        _levelTimer.stop();
        break;
      default:
        break;
    }
  }

  /// Pause the game
  void pauseGame() {
    if (_gameState == GameState.playing) {
      _levelTimer.stop();
      _changeGameState(GameState.paused);
    }
  }

  /// Resume the game
  void resumeGame() {
    if (_gameState == GameState.paused) {
      if (_currentLevelConfig.timeLimit > 0) {
        _levelTimer.start();
      }
      _changeGameState(GameState.playing);
    }
  }

  /// Track analytics event
  void _trackEvent(String event, Map<String, dynamic> parameters) {
    onAnalyticsEvent?.call(event, parameters);
  }

  /// Save data using external service
  void _saveData(String key, dynamic value) {
    onSaveData?.call(key, value);
  }

  /// Load data using external service
  T? _loadData<T>(String key) {
    return onLoadData?.call(key) as T?;
  }

  @override
  void onRemove() {
    _levelTimer.stop();
    super.onRemove();
  }
}

/// Game state enumeration
enum GameState {
  loading,
  playing,
  paused,
  gameOver,
  levelComplete,
}

/// Level configuration data class
class LevelConfig {
  final int level;
  final String targetWord;
  final int cardCount;
  final double timeLimit;
  final int decoyCount;
  final bool hasRotatingSymbols;

  const LevelConfig({
    required this.level,
    required this.targetWord,
    required this.cardCount,
    required this.timeLimit,
    required this.decoyCount,
    required this