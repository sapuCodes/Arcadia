import 'package:flutter/material.dart';
import 'package:my_game/brickBreaker.dart';
import 'package:my_game/BallBounceGame.dart';
import 'package:my_game/AppleFortuneGame.dart';
import 'package:my_game/snakeGame.dart';
import 'package:my_game/Pong.dart';
import 'package:my_game/highscore_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _titleController;
  late AnimationController _buttonController;

  @override
  void initState() {
    super.initState();

    // Title animation - keeps pulsing
    _titleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
      lowerBound: 0.9,
      upperBound: 1.1,
    )..repeat(reverse: true);

    // Button bounce animation - loops
    _buttonController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
      lowerBound: 0.95,
      upperBound: 1.05,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text("Game Palette"),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg1.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Highscores button at the top
                _buildAnimatedButton(
                  context,
                  "Highscores",
                  Icons.score,
                  Colors.purple,
                  0,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HighscoreScreen()),
                    );
                  },
                ),

                const SizedBox(height: 30),

                // Animated text title with a pulsing effect
                ScaleTransition(
                  scale: _titleController,
                  child: const Text(
                    "Let's Play & Relax!",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 30,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Animated game buttons
                for (int i = 1; i <= 5; i++) _buildGameButtons(context, i),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameButtons(BuildContext context, int index) {
    final titles = [
      "Brick Breaker",
      "Ball Bounce",
      "Apple of Fortune",
      "Snake Game",
      "Pong Game"
    ];

    final icons = [
      Icons.sports_baseball,
      Icons.sports_volleyball,
      Icons.apple,
      Icons.settings_ethernet,
      Icons.gamepad
    ];

    final colors = [
      Colors.deepPurple,
      Colors.blue,
      Colors.green,
      Colors.teal,
      Colors.orange
    ];

    final screens = [
      const BrickBreaker(),
      const BallBounceGame(),
      const AppleOfFortune(),
      const SnakeGame(),
      PongGame(),
    ];

    return _buildAnimatedButton(
      context,
      titles[index - 1],
      icons[index - 1],
      colors[index - 1],
      index,
      () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screens[index - 1]),
        );
      },
    );
  }

  Widget _buildAnimatedButton(BuildContext context, String title, IconData icon, Color color, int index, VoidCallback onTap) {
    final delay = index * 200;

    return AnimatedSlide(
      offset: Offset(0, _buttonController.value * 0.1), // Small bouncing effect
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTap: onTap,
        child: ScaleTransition(
          scale: _buttonController,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: MediaQuery.of(context).size.width * 0.8,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 28),
              label: Text(title),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
                shadowColor: Colors.black.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
