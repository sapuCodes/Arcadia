import 'package:shared_preferences/shared_preferences.dart';

class HighScoreService {
  static Future<void> saveHighScore(String gameName, int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(gameName, score);
  }

  static Future<int> loadHighScore(String gameName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(gameName) ?? 0; // Default to 0 if no score is saved
  }
}
