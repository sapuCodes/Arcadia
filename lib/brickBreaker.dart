import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';  // Import audioplayers for sound effects

void main() => runApp(MaterialApp(home: BrickBreaker()));

class BrickBreaker extends StatefulWidget {
  const BrickBreaker({super.key});

  @override
  _BrickBreakerState createState() => _BrickBreakerState();
}

enum Direction { UP, DOWN, LEFT, RIGHT }

class _BrickBreakerState extends State<BrickBreaker> {
  // Ball variables
  double ballX = 0;
  double ballY = 0;
  double ballXSpeed = 0.01;
  double ballYSpeed = 0.01;
  Direction ballXDirection = Direction.RIGHT;
  Direction ballYDirection = Direction.DOWN;

  // Player (paddle) variables
  double playerX = -0.2;
  double playerWidth = 0.4;
  double playerHeight = 0.03;

  // Game settings
  bool hasGameStarted = false;
  bool isGameOver = false;
  int score = 0;
  int lives = 1;  // Keep only 1 life
  Timer? gameTimer;

  final AudioPlayer audioPlayer = AudioPlayer();

  void playHitSound() async {
    await audioPlayer.play(AssetSource('ball_hit.mp3'));
  }
  void playBrickSound() async {
    await audioPlayer.play(AssetSource('brick.mp3'));
  }
  void playGameOverSound() async {
    await audioPlayer.play(AssetSource('game_over.ogg'));
  }


  // Brick variables
  List<List<bool>> bricks = [];
  int brickRows = 5;
  int brickColumns = 8;
  double brickWidth = 0.2;
  double brickHeight = 0.05;
  double brickPadding = 0.005;

  @override
  void initState() {
    super.initState();
    resetBricks();
  }

  void resetBricks() {
    bricks = List.generate(
      brickRows,
      (i) => List.generate(brickColumns, (j) => true),
    );
  }

  void resetGame() {
    setState(() {
      ballX = 0;
      ballY = 0;
      ballXSpeed = 0.01;
      ballYSpeed = 0.01;
      ballXDirection = Direction.RIGHT;
      ballYDirection = Direction.DOWN;
      playerX = -0.2;
      hasGameStarted = false;
      isGameOver = false;
      score = 0;
      lives = 1;  // Reset to 1 life
      resetBricks();
    });
  }

  void startGame() {
    if (isGameOver) {
      playGameOverSound();
      resetGame();
      return;
    }
    
    if (!hasGameStarted) {
      setState(() {
        hasGameStarted = true;
      });
      
      gameTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
        updateGame();
      });
    }
  }

  void updateGame() {
    // Update direction
    updateDirection();

    // Move ball
    moveBall();

    // Check collisions with bricks
    checkBrickCollision();

    // Check if player lost a life
    if (isPlayerLost()) {
      setState(() {
        lives--;
        if (lives <= 0) {
          isGameOver = true;
          gameTimer?.cancel();
        } else {
          // Reset ball position but keep game running
          ballX = 0;
          ballY = 0;
          ballXDirection = Direction.RIGHT;
          ballYDirection = Direction.DOWN;
          hasGameStarted = false;
        }
      });
    }
  }

  bool isPlayerLost() {
    return ballY >= 1.1;
    playGameOverSound();
  }

  void moveBall() {
    setState(() {
      // Horizontal movement
      if (ballXDirection == Direction.RIGHT) {
        ballX += ballXSpeed;
      } else {
        ballX -= ballXSpeed;
      }

      // Vertical movement
      if (ballYDirection == Direction.DOWN) {
        ballY += ballYSpeed;
      } else {
        ballY -= ballYSpeed;
      }
    });
  }

  void updateDirection() {
    setState(() {
      // Paddle collision - more precise detection
      if (ballY >= 0.9 - playerHeight / 2 && 
          ballY <= 0.9 + playerHeight / 2 &&
          ballX >= playerX - 0.05 &&
          ballX <= playerX + playerWidth + 0.05) {
        ballYDirection = Direction.UP;

        // Play sound when the ball hits the paddle
        playHitSound();

        // Change angle based on where ball hits paddle
        double hitPosition = (ballX - playerX) / playerWidth;
        ballXSpeed = 0.015 * (hitPosition - 0.5) * 2;
        
        // Ensure ball doesn't get stuck in paddle
        if (ballY > 0.9) {
          ballY = 0.89;
        }
      }

      // Ceiling collision with buffer
      if (ballY <= -1.0) {
        ballY = -0.99;
        ballYDirection = Direction.DOWN;
      }

      // Wall collisions with buffer
      if (ballX >= 1.0) {
        ballX = 0.99;
        ballXDirection = Direction.LEFT;
      } else if (ballX <= -1.0) {
        ballX = -0.99;
        ballXDirection = Direction.RIGHT;
      }
    });
  }

  void checkBrickCollision() {
    for (int i = 0; i < brickRows; i++) {
      for (int j = 0; j < brickColumns; j++) {
        if (bricks[i][j]) {
          double brickX = -1 + j * (brickWidth + brickPadding * 2);
          double brickY = -0.8 + i * (brickHeight + brickPadding * 2);

          // More precise collision detection with bricks
          if (ballX + 0.02 >= brickX &&
              ballX - 0.02 <= brickX + brickWidth &&
              ballY + 0.02 >= brickY &&
              ballY - 0.02 <= brickY + brickHeight) {
            // Hit a brick
            setState(() {
              bricks[i][j] = false;
              score += 10;
              playBrickSound();

              // Determine which side was hit
              double brickCenterX = brickX + brickWidth / 2;
              double brickCenterY = brickY + brickHeight / 2;
              
              if ((ballX - brickCenterX).abs() / brickWidth > 
                  (ballY - brickCenterY).abs() / brickHeight) {
                // Horizontal collision
                ballXDirection = ballX < brickCenterX ? Direction.LEFT : Direction.RIGHT;
                if (ballXDirection == Direction.LEFT) {
                  ballX = brickX - 0.03;
                } else {
                  ballX = brickX + brickWidth + 0.03;
                }
              } else {
                // Vertical collision
                ballYDirection = ballY < brickCenterY ? Direction.UP : Direction.DOWN;
                if (ballYDirection == Direction.UP) {
                  ballY = brickY - 0.03;
                } else {
                  ballY = brickY + brickHeight + 0.03;
                }
              }
            });
          }
        }
      }
    }
  }

  void movePlayer(DragUpdateDetails details) {
    setState(() {
      double dx = details.primaryDelta! / MediaQuery.of(context).size.width * 2;
      playerX += dx;

      // Ensure the paddle stays within bounds
      if (playerX < -1) {
        playerX = -1;
      } else if (playerX + playerWidth > 1) {
        playerX = 1 - playerWidth;
      }
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: startGame,
      onHorizontalDragUpdate: movePlayer,
      child: Scaffold(
        backgroundColor: Colors.deepPurple[900],
        body: Center(
          child: Stack(
            children: [
              // Game elements
              ...buildBricks(),
              MyBall(ballX: ballX, ballY: ballY),
              MyPlayer(playerX: playerX, playerWidth: playerWidth, playerHeight: playerHeight),

              // Cover screen (tap to play)
              if (!hasGameStarted || isGameOver)
                CoverScreen(
                  hasGameStarted: hasGameStarted,
                  isGameOver: isGameOver,
                  score: score,
                  onTap: startGame,
                ),

              // Score display
              Positioned(
                top: 30,
                left: 20,
                child: Text(
                  'Score: $score',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),

            
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> buildBricks() {
    List<Widget> brickWidgets = [];
    double totalWidth = (brickColumns * brickWidth) + (brickPadding * 2 * (brickColumns - 1));
    double startX = -(totalWidth / 2); // Centering the bricks

    for (int i = 0; i < brickRows; i++) {
      for (int j = 0; j < brickColumns; j++) {
        if (bricks[i][j]) {
          double brickX = startX + j * (brickWidth + brickPadding * 2);
          double brickY = -0.8 + i * (brickHeight + brickPadding * 2);
          
          brickWidgets.add(
            Brick(
              brickX: brickX,
              brickY: brickY,
              brickWidth: brickWidth,
              brickHeight: brickHeight,
              color: Colors.primaries[i % Colors.primaries.length],
            ),
          );
        }
      }
    }
    return brickWidgets;
  }
}

class MyBall extends StatelessWidget {
  final ballX;
  final ballY;

  const MyBall({super.key, this.ballX, this.ballY});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment(ballX, ballY),
      child: Container(
        height: 20,
        width: 20,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.yellow.withOpacity(0.8),
              spreadRadius: 3,
              blurRadius: 7,
            ),
          ],
        ),
      ),
    );
  }
}

class CoverScreen extends StatelessWidget {
  final bool hasGameStarted;
  final bool isGameOver;
  final int score;
  final VoidCallback onTap;

  const CoverScreen({
    super.key,
    required this.hasGameStarted,
    required this.isGameOver,
    required this.score,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isGameOver ? 'GAME OVER' : 'BRICK BREAKER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Text(
                isGameOver ? 'Final Score: $score' : 'Tap to Play',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
              if (isGameOver) SizedBox(height: 20),
                Text(
                  'Tap to Restart',
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyPlayer extends StatelessWidget {
  final playerX;
  final playerWidth;
  final playerHeight;

  const MyPlayer({
    super.key,
    this.playerX,
    this.playerWidth,
    this.playerHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment(playerX, 0.9),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 15,
          width: MediaQuery.of(context).size.width * playerWidth / 2,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.lightBlueAccent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.5),
                spreadRadius: 3,
                blurRadius: 7,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Brick extends StatelessWidget {
  final double brickX;
  final double brickY;
  final double brickWidth;
  final double brickHeight;
  final Color color;

  const Brick({
    super.key,
    required this.brickX,
    required this.brickY,
    required this.brickWidth,
    required this.brickHeight,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment(brickX, brickY),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Container(
          width: MediaQuery.of(context).size.width * brickWidth / 2,
          height: MediaQuery.of(context).size.height * brickHeight / 2,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
