import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ball Bouncer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const BallBounceGame(),
    );
  }
}

class BallBounceGame extends StatefulWidget {
  const BallBounceGame({super.key});

  @override
  _BallBounceGameState createState() => _BallBounceGameState();
}

class _BallBounceGameState extends State<BallBounceGame> {
  // Game state
  double ballX = 0;
  double ballY = 0;
  double ballSpeedX = 0.015;
  double ballSpeedY = 0.015;
  bool isGameOver = false;
  bool isGameStarted = false;
  int score = 0;
  int highScore = 0;
  int lives = 3;
  
  // Paddle
  double paddleX = 0;
  double paddleWidth = 0.3;
  
  // Collectibles
  List<Offset> collectibles = [];
  Random random = Random();
  
  // Audio
  late AudioPlayer bounceSound;
  late AudioPlayer collectSound;
  late AudioPlayer gameOverSound;


    final AudioPlayer audioPlayer = AudioPlayer();

  void playHitSound() async {
    await audioPlayer.play(AssetSource('rubberballbouncing.mp3'));
  }
   void playCollectSound() async {
    await audioPlayer.play(AssetSource('collect.ogg'));
  }
  void playGameOverSound() async {
    await audioPlayer.play(AssetSource('game_over.ogg'));
  }
  void playNightSound() async {
    await audioPlayer.play(AssetSource('night.mp3'));
  }




  // Game timer
  Timer? gameTimer;
  
  @override
  void initState() {
    super.initState();
    bounceSound = AudioPlayer();
    collectSound = AudioPlayer();
    gameOverSound = AudioPlayer();
    _loadSounds();
  }
  
  Future<void> _loadSounds() async {
    try {
      await bounceSound.setSource(AssetSource('assets/rubberballbouncing.mp3'));
      await collectSound.setSource(AssetSource('assets/collect.ogg'));
      await gameOverSound.setSource(AssetSource('assets/game_over.ogg'));
    } catch (e) {
      debugPrint('Error loading sounds: $e');
    }
  }
  
  @override
  void dispose() {
    gameTimer?.cancel();
    bounceSound.dispose();
    collectSound.dispose();
    gameOverSound.dispose();
    super.dispose();
  }

  Future<void> _playSound(AudioPlayer player) async {
    try {
      await player.seek(Duration.zero);
      await player.resume();
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  void startGame() {
    setState(() {
      isGameStarted = true;
      isGameOver = false;
      ballX = 0;
      ballY = 0;
      ballSpeedX = 0.015 * (random.nextBool() ? 1 : -1);
      ballSpeedY = 0.015;
      score = 0;
      lives = 3;
      collectibles.clear();
    });

    playNightSound();
    
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!isGameOver) {
        updateGame();
      } else {
        timer.cancel();
      }
    });
  }

  void updateGame() {
    setState(() {
      // Move the ball
      ballX += ballSpeedX;
      ballY += ballSpeedY;

      // Ball collision with top
      if (ballY <= -1) {
        ballY = -1;
        ballSpeedY = -ballSpeedY;
        playHitSound();
      }
      
      // Ball collision with sides
      if (ballX <= -1 || ballX >= 1) {
        ballSpeedX = -ballSpeedX;
        playHitSound();
      }
      
      // Ball collision with paddle
      if (ballY >= 0.9 && 
          ballX > paddleX - paddleWidth / 2 && 
          ballX < paddleX + paddleWidth / 2) {
        ballY = 0.9;
        ballSpeedY = -ballSpeedY;
        
        // Increase ball speed after hitting the paddle
        ballSpeedX *= 1.05;  // Increase horizontal speed
        ballSpeedY *= 1.05;  // Increase vertical speed
        
        // Add some randomness to the bounce
        double hitPosition = (ballX - paddleX) / (paddleWidth / 2);
        ballSpeedX = hitPosition * 0.02;
        
        playHitSound();
      }
      
      // Ball out of bounds (bottom)
      if (ballY > 1.1) {
        lives--;
        if (lives <= 0) {
          isGameOver = true;
          if (score > highScore) {
            highScore = score;
            _saveHighScore(); // Save high score
          }
          playGameOverSound();
        } else {
          // Reset ball position
          ballX = paddleX;
          ballY = 0;
          ballSpeedX = 0.015 * (random.nextBool() ? 1 : -1);
          ballSpeedY = 0.015;
        }
      }
      
      // Check collectible collisions
      List<Offset> collected = [];
      for (var collectible in collectibles) {
        double dx = ballX - collectible.dx;
        double dy = ballY - collectible.dy;
        double distance = sqrt(dx * dx + dy * dy);
        
        if (distance < 0.075) {
          collected.add(collectible);
          score += 1;
          playCollectSound();
        }
      }
      
      collectibles.removeWhere((item) => collected.contains(item));
      
      // Spawn new collectibles
      if (random.nextDouble() < 0.02) {
        double x = random.nextDouble() * 1.8 - 0.9;
        double y = random.nextDouble() * 0.8 - 0.9;
        
        double dx = ballX - x;
        double dy = ballY - y;
        if (sqrt(dx * dx + dy * dy) > 0.3) {
          collectibles.add(Offset(x, y));
        }
      }
    });
  }

  void onTap() {
    if (!isGameStarted) {
      startGame();
    }
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (!isGameOver) {
      setState(() {
        double newPaddleX = paddleX + details.delta.dx / (context.size!.width / 2);
        paddleX = newPaddleX.clamp(-1 + paddleWidth / 2, 1 - paddleWidth / 2);
      });
    }
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('Ball Bounce', highScore);
  }

  @override
Widget build(BuildContext context) {
  return GestureDetector(
    onTap: onTap,
    onPanUpdate: onPanUpdate,
    child: Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Image.asset(
                'assets/night.jpg', // Background image
                fit: BoxFit.cover,
              ),
            ),
            // Ball
            AnimatedPositioned(
              duration: const Duration(milliseconds: 16),
              left: (ballX + 1) * MediaQuery.of(context).size.width / 2 - 20,
              top: (ballY + 1) * MediaQuery.of(context).size.height / 2 - 20,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.7),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
              ),
            ),
            
            // Paddle
            Positioned(
              left: (paddleX + 1 - paddleWidth / 2) * MediaQuery.of(context).size.width / 2,
              bottom: 20,
              child: Container(
                width: paddleWidth * MediaQuery.of(context).size.width / 2,
                height: 15,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            
            // Collectibles
            ...collectibles.map((collectible) {
              return Positioned(
                left: (collectible.dx + 1) * MediaQuery.of(context).size.width / 2 - 12,
                top: (collectible.dy + 1) * MediaQuery.of(context).size.height / 2 - 12,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Colors.yellow, Colors.orange],
                      stops: [0.3, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.yellow.withOpacity(0.7),
                        blurRadius: 5,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                ),
              );
            }).toList(),
            
            // Score and Lives Display
            Positioned(
              top: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Score: $score',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: List.generate(lives, (index) {
                      return Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 30,
                      );
                    }),
                  ),
                ],
              ),
            ),
            
            // Start screen
            if (!isGameStarted && !isGameOver)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'BALL BOUNCER',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.blue,
                            offset: Offset(3, 3),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Tap to Start',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Game over screen
            if (isGameOver)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'GAME OVER',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.red,
                            offset: Offset(3, 3),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'Score: $score',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 10,
                        ),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: const Text('Play Again'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
    );
  }
}
