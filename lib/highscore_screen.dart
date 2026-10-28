import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HighscoreScreen extends StatefulWidget {
  const HighscoreScreen({super.key});

  @override
  _HighscoreScreenState createState() => _HighscoreScreenState();
}

class _HighscoreScreenState extends State<HighscoreScreen> {
  late Future<Map<String, int>> highScoresFuture;

  @override
  void initState() {
    super.initState();
    _refreshHighScores();
  }

  void _refreshHighScores() {
    setState(() {
      highScoresFuture = _loadHighScores();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("High Scores"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple, Colors.pink],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: FutureBuilder<Map<String, int>>(
        future: highScoresFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final highScores = snapshot.data ?? {};
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: highScores.length,
            itemBuilder: (context, index) {
              final gameName = highScores.keys.elementAt(index);
              final score = highScores[gameName]!;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Card(
                  elevation: 5,
                  shadowColor: Colors.black.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(20),
                    leading: Icon(
                      Icons.gamepad,
                      size: 30,
                      color: Colors.purpleAccent,
                    ),
                    title: Text(
                      gameName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    subtitle: Text(
                      "Highscore: $score",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshHighScores,
        backgroundColor: Colors.purple,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Future<Map<String, int>> _loadHighScores() async {
    final prefs = await SharedPreferences.getInstance();
    final gameNames = [
      'Brick Breaker', 'Ball Bounce', 'Apple of Fortune', 'Snake Game', 'Pong Game'
    ];
    final highScores = <String, int>{};

    for (var game in gameNames) {
      highScores[game] = prefs.getInt(game) ?? 0;
    }

    return highScores;
  }
}
