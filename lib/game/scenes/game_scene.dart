import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

/// Main game scene component that manages the puzzle game flow
class GameScene extends Component with HasGameRef, HasKeyboardHandlerComponents {
  /// Current level being played
  int currentLevel = 1;
  
  /// Current score/runes earned
  int score = 0;
  
  /// Timer for level completion
  Timer? levelTimer;
  
  /// Remaining time in seconds
  int remainingTime = 0;
  
  /// Game state management
  bool isGameActive = false;
  bool isGamePaused = false;
  bool isLevelComplete = false;
  
  /// Symbol cards in the current level
  List<SymbolCard> symbolCards = [];
  
  /// Decoder beam component
  DecoderBeam? decoderBeam;
  
  /// Current word to decode
  String targetWord = '';
  
  /// Player's current input
  String playerInput = '';
  
  /// Wrong attempts counter
  int wrongAttempts = 0;
  
  /// Maximum allowed wrong attempts
  int maxWrongAttempts = 3;
  
  /// UI components
  late TextComponent scoreDisplay;
  late TextComponent timerDisplay;
  late TextComponent wordInputDisplay;
  late RectangleComponent inputField;
  
  /// Background component
  late SpriteComponent background;
  
  /// Random number generator
  final Random random = Random();
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _initializeUI();
    await _loadLevel(currentLevel);
  }
  
  /// Initialize UI components
  Future<void> _initializeUI() async {
    // Background
    background = SpriteComponent()
      ..sprite = await Sprite.load('temple_background.png')
      ..size = gameRef.size
      ..position = Vector2.zero();
    add(background);
    
    // Score display
    scoreDisplay = TextComponent(
      text: 'Runes: $score',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFD4AF37),
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    )..position = Vector2(20, 50);
    add(scoreDisplay);
    
    // Timer display
    timerDisplay = TextComponent(
      text: 'Time: --',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE6D7B8),
          fontSize: 20,
        ),
      ),
    )..position = Vector2(gameRef.size.x - 150, 50);
    add(timerDisplay);
    
    // Input field background
    inputField = RectangleComponent(
      size: Vector2(gameRef.size.x - 40, 60),
      position: Vector2(20, gameRef.size.y - 120),
      paint: Paint()..color = const Color(0xFF2C1810).withOpacity(0.8),
    );
    add(inputField);
    
    // Word input display
    wordInputDisplay = TextComponent(
      text: 'Decoded Word: $_formatPlayerInput()',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE6D7B8),
          fontSize: 18,
        ),
      ),
    )..position = Vector2(30, gameRef.size.y - 100);
    add(wordInputDisplay);
  }
  
  /// Load and setup a specific level
  Future<void> _loadLevel(int level) async {
    _clearLevel();
    
    final levelConfig = _getLevelConfiguration(level);
    targetWord = levelConfig['word'] as String;
    remainingTime = levelConfig['timeLimit'] as int;
    
    await _spawnSymbolCards(levelConfig);
    await _spawnDecoderBeam();
    
    _startLevelTimer();
    isGameActive = true;
    isLevelComplete = false;
    wrongAttempts = 0;
    playerInput = '';
    
    _updateUI();
  }
  
  /// Get configuration for a specific level
  Map<String, dynamic> _getLevelConfiguration(int level) {
    switch (level) {
      case 1:
        return {
          'word': 'RUNE',
          'cardCount': 4,
          'timeLimit': 0, // No time limit for tutorial
          'decoyCount': 0,
        };
      case 2:
        return {
          'word': 'TEMPLE',
          'cardCount': 6,
          'timeLimit': 120,
          'decoyCount': 1,
        };
      case 3:
        return {
          'word': 'ANCIENT',
          'cardCount': 8,
          'timeLimit': 100,
          'decoyCount': 2,
        };
      default:
        // Progressive difficulty for levels 4-10
        final wordLength = 4 + (level - 1);
        final cardCount = 3 + (level * 2);
        final timeLimit = max(60, 140 - (level * 10));
        final decoyCount = level - 2;
        
        return {
          'word': _generateRandomWord(wordLength),
          'cardCount': cardCount,
          'timeLimit': timeLimit,
          'decoyCount': decoyCount,
        };
    }
  }
  
  /// Generate a random word for higher levels
  String _generateRandomWord(int length) {
    const words = [
      'MYSTERY', 'ANCIENT', 'SYMBOLS', 'DECODER', 'TEMPLE',
      'ARTIFACT', 'CHAMBER', 'HIEROGLYPH', 'MYSTICAL', 'SACRED'
    ];
    
    final filteredWords = words.where((word) => word.length == length).toList();
    if (filteredWords.isNotEmpty) {
      return filteredWords[random.nextInt(filteredWords.length)];
    }
    
    // Fallback: generate random letters
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    return List.generate(length, (index) => letters[random.nextInt(letters.length)]).join();
  }
  
  /// Spawn symbol cards for the current level
  Future<void> _spawnSymbolCards(Map<String, dynamic> config) async {
    final word = config['word'] as String;
    final cardCount = config['cardCount'] as int;
    final decoyCount = config['decoyCount'] as int;
    
    final letters = word.split('');
    final allCards = <String>[];
    
    // Add target word letters
    allCards.addAll(letters);
    
    // Add decoy letters
    const decoyLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    for (int i = 0; i < decoyCount; i++) {
      String decoyLetter;
      do {
        decoyLetter = decoyLetters[random.nextInt(decoyLetters.length)];
      } while (letters.contains(decoyLetter));
      allCards.add(decoyLetter);
    }
    
    // Shuffle cards
    allCards.shuffle(random);
    
    // Position cards in a grid
    final cardsPerRow = (cardCount / 2).ceil();
    final cardSize = Vector2(80, 100);
    final spacing = Vector2(20, 20);
    final startX = (gameRef.size.x - (cardsPerRow * (cardSize.x + spacing.x) - spacing.x)) / 2;
    final startY = 150;
    
    for (int i = 0; i < allCards.length; i++) {
      final row = i ~/ cardsPerRow;
      final col = i % cardsPerRow;
      
      final position = Vector2(
        startX + col * (cardSize.x + spacing.x),
        startY + row * (cardSize.y + spacing.y),
      );
      
      final card = SymbolCard(
        letter: allCards[i],
        position: position,
        size: cardSize,
        isTargetLetter: letters.contains(allCards[i]),
      );
      
      symbolCards.add(card);
      add(card);
    }
  }
  
  /// Spawn the decoder beam
  Future<void> _spawnDecoderBeam() async {
    decoderBeam = DecoderBeam(
      position: Vector2(gameRef.size.x / 2, gameRef.size.y - 200),
      onCardHit: _onCardFlipped,
    );
    add(decoderBeam!);
  }
  
  /// Handle card flip event
  void _onCardFlipped(SymbolCard card) {
    if (!isGameActive || card.isFlipped) return;
    
    card.flip();
    
    if (card.isTargetLetter) {
      playerInput += card.letter;
      _updateUI();
      _checkWinCondition();
    }
  }
  
  /// Start the level timer
  void _startLevelTimer() {
    if (remainingTime <= 0) return;
    
    levelTimer?.cancel();
    levelTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isGamePaused || !isGameActive) return;
      
      remainingTime--;
      _updateUI();
      
      if (remainingTime <= 0) {
        _onTimeExpired();
      }
    });
  }
  
  /// Handle time expiration
  void _onTimeExpired() {
    levelTimer?.cancel();
    isGameActive = false;
    _onLevelFailed('Time expired!');
  }
  
  /// Check if the player has won the level
  void _checkWinCondition() {
    if (playerInput.length == targetWord.length) {
      if (playerInput == targetWord) {
        _onLevelComplete();
      } else {
        _onWrongWordSubmission();
      }
    }
  }
  
  /// Handle wrong word submission
  void _onWrongWordSubmission() {
    wrongAttempts++;
    playerInput = '';
    
    // Reset all flipped cards
    for (final card in symbolCards) {
      if (card.isFlipped) {
        card.reset();
      }
    }
    
    if (wrongAttempts >= maxWrongAttempts) {
      _onLevelFailed('Too many wrong attempts!');
    } else {
      _updateUI();
    }
  }
  
  /// Handle level completion
  void _onLevelComplete() {
    levelTimer?.cancel();
    isGameActive = false;
    isLevelComplete = true;
    
    // Award runes
    final runesEarned = 50 + (remainingTime * 2);
    score += runesEarned;
    
    _updateUI();
    
    // Progress to next level after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (currentLevel < 10) {
        currentLevel++;
        _loadLevel(currentLevel);
      } else {
        _onGameComplete();
      }
    });
  }
  
  /// Handle level failure
  void _onLevelFailed(String reason) {
    levelTimer?.cancel();
    isGameActive = false;
    
    // Show failure message and restart level after delay
    Future.delayed(const Duration(seconds: 2), () {
      _loadLevel(currentLevel);
    });
  }
  
  /// Handle complete game completion
  void _onGameComplete() {
    // Game completed - show victory screen
    isGameActive = false;
  }
  
  /// Clear current level components
  void _clearLevel() {
    for (final card in symbolCards) {
      card.removeFromParent();
    }
    symbolCards.clear();
    
    decoderBeam?.removeFromParent();
    decoderBeam = null;
    
    levelTimer?.cancel();
  }
  
  /// Update UI components
  void _updateUI() {
    scoreDisplay.text = 'Runes: $score';
    
    if (remainingTime > 0) {
      timerDisplay.text = 'Time: ${remainingTime}s';
    } else {
      timerDisplay.text = 'Time: ∞';
    }
    
    wordInputDisplay.text = 'Decoded Word: ${_formatPlayerInput()}';
  }
  
  /// Format player input for display
  String _formatPlayerInput() {
    final formatted = StringBuffer();
    for (int i = 0; i < targetWord.length; i++) {
      if (i < playerInput.length) {
        formatted.write(playerInput[i]);
      } else {
        formatted.write('_');
      }
      if (i < targetWord.length - 1) {
        formatted.write(' ');
      }
    }
    return formatted.toString();
  }
  
  /// Pause the game
  void pauseGame() {
    isGamePaused = true;
  }
  
  /// Resume the game
  void resumeGame() {
    isGamePaused = false;
  }
  
  /// Restart current level
  void restartLevel() {
    _loadLevel(currentLevel);
  }
  
  @override
  void onRemove() {
    levelTimer?.cancel();
    super.onRemove();
  }
}

/// Symbol card component that can be flipped to reveal letters
class SymbolCard extends RectangleComponent with HasGameRef {
  final String letter;
  final bool isTargetLetter;
  bool isFlipped = false;
  
  late TextComponent letterText;
  late TextComponent symbolText;
  
  SymbolCard({
    required this.letter,
    required Vector2 position,
    required Vector2 size,
    required this.isTargetLetter,
  }) : super(
    position: position,
    size: size,
    paint: Paint()..color = const Color(0xFF8B6914),
  );
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Symbol side (initially visible)
    symbolText = TextComponent(
      text: '⚡',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFD4AF37),
          fontSize: 32,
        ),
      ),
    )..position = Vector2(size.x / 2 - 16, size.y / 2 - 16);
    add(symbolText);
    
    // Letter side (hidden initially)
    letterText = TextComponent(
      text: letter,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE6D7B8),
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    )..position = Vector2(size.x / 2 - 14, size.y / 2 - 14);
    letterText.scale = Vector2.zero();
    add(letterText);
  }
  
  /// Flip the card to reveal the letter
  void flip() {
    if (isFlipped) return;
    
    isFlipped = true;
    symbolText.scale = Vector2.zero();
    letterText.scale = Vector2.all(1.0);
    paint.color = isTargetLetter ? const Color(0xFF4A4A4A) : const Color(0xFF2C1810);
  }
  
  /// Reset the card to symbol side
  void reset() {
    isFlipped = false;
    symbolText.scale = Vector2.all(1.0);
    letterText.scale = Vector2.zero();
    paint.color = const Color(0xFF8B6914);
  }
}

/// Decoder beam component that can be aimed and fired
class DecoderBeam extends Component with HasGameRef {