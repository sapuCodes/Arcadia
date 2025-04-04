import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

void main() {
  runApp(PongGame());
}

class PongGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pong Game',
      debugShowCheckedModeBanner: false,
      home: PongScreen(),
    );
  }
}

class PongScreen extends StatefulWidget {
  @override
  _PongScreenState createState() => _PongScreenState();
}

class _PongScreenState extends State<PongScreen> {
  double ballX = 0, ballY = 0;
  double ballDX = 0.01, ballDY = 0.01;
  double speedMultiplier = 1.0;
  double paddleWidth = 0.3;
  double playerPaddleX = 0, opponentPaddleX = 0;
  int playerScore = 0;
  bool gameOver = false;
  bool gameStarted = false;
  Timer? gameLoop;
  final AudioPlayer audioPlayer = AudioPlayer();

  int highScore = 0; // Store high score

  void playHitSound() async {
    await audioPlayer.play(AssetSource('ball_hit.mp3'));
  }
  void playGameOverSound() async {
    await audioPlayer.play(AssetSource('game_over.ogg'));
  }
  void playNightSound() async {
    await audioPlayer.play(AssetSource('night.mp3'));
  }

  @override
  void dispose() {
    gameLoop?.cancel();
    audioPlayer.dispose();
    super.dispose();
  }

  void startGame() {
    gameOver = false;
    ballX = 0;
    ballY = 0;
    speedMultiplier = 1.0;
    ballDX = Random().nextBool() ? 0.01 : -0.01;
    ballDY = 0.01;
    playerScore = 0;
    opponentPaddleX = 0;
    playerPaddleX = 0;
playNightSound();
    gameLoop?.cancel();
    gameLoop = Timer.periodic(Duration(milliseconds: 16), (timer) {
      if (gameOver) {
        timer.cancel();
      }
      moveBall();
      moveOpponentPaddle();
    });
  }

  void moveBall() {
    setState(() {
      ballX += ballDX * speedMultiplier;
      ballY += ballDY * speedMultiplier;

      // Ball collision with walls
      if (ballX <= -1 || ballX >= 1) {
        ballDX = -ballDX;
        playHitSound();
      }

      // Ball collision with opponent paddle (Top)
      if (ballY <= -0.85 &&
          ballX >= opponentPaddleX - paddleWidth &&
          ballX <= opponentPaddleX + paddleWidth) {
        ballDY = -ballDY;
        playHitSound();
      }

      // Ball collision with player paddle (Bottom)
      if (ballY >= 0.85 &&
          ballX >= playerPaddleX - paddleWidth &&
          ballX <= playerPaddleX + paddleWidth) {
        ballDY = -ballDY;
        playerScore++;
        playHitSound();

        // Increase speed noticeably
        speedMultiplier += 0.15;
        if (speedMultiplier > 3.0) speedMultiplier = 3.0; // Cap max speed

        // Add random slight variation to ball direction
        ballDX += (Random().nextDouble() - 0.5) * 0.01;
        ballDX = ballDX.clamp(-0.03, 0.03); // Prevent extreme angles
      }

      // Ball should NEVER go past opponent (opponent always returns)
      if (ballY < -1) {
        ballDY = -ballDY; // If ball goes past opponent, make it bounce back
      }

      // Ball missed (Game Over) if it goes past player
      if (ballY > 1) {
        gameOver = true;
        gameLoop?.cancel();
        playGameOverSound();
        _showGameOverDialog();
      }
    });
  }

  void moveOpponentPaddle() {
    setState(() {
      opponentPaddleX += (ballX - opponentPaddleX) * 0.15;
      opponentPaddleX = opponentPaddleX.clamp(-1 + paddleWidth, 1 - paddleWidth);
    });
  }

  void movePlayerPaddle(DragUpdateDetails details) {
    setState(() {
      playerPaddleX += details.delta.dx / (MediaQuery.of(context).size.width / 2);
      playerPaddleX = playerPaddleX.clamp(-1 + paddleWidth, 1 - paddleWidth);
    });
  }

  // Load the high score from SharedPreferences
  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('pongHighScore') ?? 0;
    });
  }

  // Save the high score to SharedPreferences
Future<void> _saveHighScore() async {
  final prefs = await SharedPreferences.getInstance();
  if (playerScore > highScore) {
    // Save high score for Pong game
    await prefs.setInt('Pong Game', playerScore);
    setState(() {
      highScore = playerScore;
    });
  }
}


  // Show the game over dialog with current score and high score
  void _showGameOverDialog() {
    _saveHighScore(); // Save the high score if the current score is higher

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Game Over'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Your Score: $playerScore"),
              Text("High Score: $highScore"),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                startGame(); // Restart the game
              },
              child: Text("Restart", style: TextStyle(fontSize: 18)),
            ),
          ],
        );
      },
    );
  }

  // Show game rules dialog
  void showRulesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Game Rules'),
          content: Text(
            '1. Move your paddle to hit the ball.\n'
            '2. The ball will bounce off the walls and paddles.\n'
            '3. Every time the ball hits your paddle, your score increases.\n'
            '4. The speed of the ball increases after every hit.\n'
            '5. Try to keep the ball from hitting the bottom of the screen.'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadHighScore(); // Load high score when the app starts
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: gameStarted ? movePlayerPaddle : null,
      onTap: () {
        if (!gameStarted) {
          setState(() {
            gameStarted = true;
          });
          startGame(); // Start the game when tapped
        }
      },
      child: Scaffold(
        backgroundColor: Colors.blueGrey[900], // Keep this for fallback
        appBar: AppBar(
          title: Text('Pong Game'),
          backgroundColor: Colors.black,
          actions: [
            IconButton(
              icon: Icon(Icons.help_outline),
              onPressed: showRulesDialog,
            ),
          ],
        ),
        body: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Image.asset(
                'assets/sky.jpg', // Background image
                fit: BoxFit.cover, // Cover the entire screen
              ),
            ),
            // Display the player's score and high score
            Align(
              alignment: Alignment(0, -0.95),
              child: Text(
                "Score: $playerScore",
                style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
              ),
            ),
            Align(
              alignment: Alignment(0, -0.85),
              child: Text(
                "Current High Score: $highScore",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Align(
              alignment: Alignment(ballX, ballY),
              child: Image.asset(
                'assets/pong.png', // Ball image
                width: 20,
                height: 20,
              ),
            ),
            Align(
              alignment: Alignment(playerPaddleX, 0.9),
              child: Container(
                width: MediaQuery.of(context).size.width * paddleWidth,
                height: 10,
                color: Colors.green, // Player paddle is green
              ),
            ),
            Align(
              alignment: Alignment(opponentPaddleX, -0.9),
              child: Container(
                width: MediaQuery.of(context).size.width * paddleWidth,
                height: 10,
                color: Colors.red, // Opponent paddle is red
              ),
            ),
            if (!gameStarted)
              Positioned(
                top: MediaQuery.of(context).size.height * 0.4,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Tap to Start',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            if (gameOver)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Game Over",
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: startGame,
                      child: Text("Restart", style: TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}