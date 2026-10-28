import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'package:audioplayers/audioplayers.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AppleOfFortune(),
    );
  }
}

class AppleOfFortune extends StatefulWidget {
  const AppleOfFortune({super.key});

  @override
  _AppleOfFortuneState createState() => _AppleOfFortuneState();
}

class _AppleOfFortuneState extends State<AppleOfFortune> {
  int currentRow = 0;
  String result = '';
  bool isGameOver = false;
  int coins = 100;  // Player's coin balance
  int betAmount = 0;  // Amount the player bets
  bool isMatchStarted = false;  // Track if the match has started
  final int totalRows = 10;
  List<List<bool>> gameBoard = [];
  List<bool> revealedRows = List.generate(10, (index) => false);
  int blinkingIndex = 0;
  late Timer blinkingTimer;

  // Row multipliers
  List<double> rowMultipliers = [
    1.23, 1.54, 1.93, 2.41, 4.02, 6.71, 11.18, 27.97, 69.93, 349.68
  ];

  @override
  void initState() {
    super.initState();
    generateGameBoard();
    startBlinking();
  }

  void generateGameBoard() {
    gameBoard.clear();
    Random random = Random();

    for (int i = 0; i < totalRows; i++) {
      int rottenApples = i < 4 ? 1 : (i < 7 ? 2 : (i < 9 ? 3 : 4));
      List<bool> row = List.generate(5, (index) => false);
      for (int j = 0; j < rottenApples; j++) {
        int pos;
        do {
          pos = random.nextInt(5);
        } while (row[pos]);
        row[pos] = true;
      }
      gameBoard.add(row);
    }
  }

  void startBlinking() {
    blinkingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        blinkingIndex = (blinkingIndex + 1) % 5;
      });
    });
  }

  void handleChoice(int rowIndex, int cellIndex) {
    if (isGameOver || rowIndex != currentRow || betAmount <= 0) return;

    setState(() {
      revealedRows[rowIndex] = true;
      if (gameBoard[rowIndex][cellIndex]) {
        result = 'Oops! Rotten apple in row ${rowIndex + 1}. You lost!';
        coins -= betAmount; // Subtract bet if lost
        if (coins < 0) coins = 0; // Prevent coins from going below zero
        isGameOver = true;
        revealedRows = List.generate(10, (index) => true);
      } else {
        result = 'Good choice! Moving to next row.';
        currentRow++;
      }
    });
  }

  void collectWinnings() async {
  if (!isGameOver) {
    setState(() {
      coins += (betAmount * rowMultipliers[currentRow - 1]).toInt(); // Collect current win
      result = 'You collected your winnings!';
      isGameOver = true;
    });

    // Save the highscore if this score is higher than the previously saved highscore
    final prefs = await SharedPreferences.getInstance();
    int highestCoins = prefs.getInt('highestCoins') ?? 0;

    if (coins > highestCoins) {
      await prefs.setInt('highestCoins', coins);
    }
  }
}

  // Check if the bet is valid
  void onBetEntered() {
    if (betAmount > 0 && betAmount <= coins) {
      setState(() {
        coins -= betAmount;
        isMatchStarted = true;  // Match is now started
      });
    } else {
      setState(() {
        result = 'Invalid bet. You cannot bet more than your total coins.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Display the current winnings only if the player has progressed to the next row
    double currentWinnings = betAmount > 0 && currentRow > 0 ? betAmount * rowMultipliers[currentRow - 1] : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apple of Fortune'),
        backgroundColor: Colors.green,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Coins: $coins',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.deepPurple,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(result, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 20),
            Row(
              children: [
                // Bet input field for dynamic bet entry
                SizedBox(
                  width: 150,
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        betAmount = int.tryParse(value) ?? 0;
                        if (betAmount > coins) {
                          betAmount = coins; // Prevent bet amount from exceeding available coins
                        }
                      });
                    },
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Enter Bet',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: onBetEntered,
                  child: const Text('Start Match'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: totalRows,
                itemBuilder: (context, rowIndex) {
                  return Column(
                    children: [
                      Text('Row ${rowIndex + 1} (Multiplier: x${rowMultipliers[rowIndex]})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          childAspectRatio: 1,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: 5,
                        itemBuilder: (context, cellIndex) {
                          bool isRevealed = revealedRows[rowIndex];
                          bool isRotten = gameBoard[rowIndex][cellIndex];
                          bool isCurrentRow = rowIndex == currentRow;
                          Color cellColor = isRevealed
                              ? (isRotten ? Colors.red : Colors.green)
                              : (isCurrentRow && blinkingIndex == cellIndex ? Colors.yellow : Colors.grey);

                          return GestureDetector(
                            onTap: isGameOver || !isCurrentRow || !isMatchStarted
                                ? null
                                : () => handleChoice(rowIndex, cellIndex),
                            child: Container(
                              decoration: BoxDecoration(
                                border: isCurrentRow && !isGameOver && !revealedRows[rowIndex] && cellIndex == blinkingIndex
                                    ? Border.all(color: Colors.blue, width: 3) // Highlight border for selected cell
                                    : null,
                                color: cellColor,
                              ),
                              child: Center(
                                child: isRevealed
                                    ? (isRotten
                                        ? Image.asset('assets/bitten_apple.jpeg', width: 60, height: 60)
                                        : Image.asset('assets/apple.jpeg', width: 60, height: 60))
                                    : const Icon(Icons.question_mark, color: Colors.white),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ),
            if (isGameOver)
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    currentRow = 0;
                    isGameOver = false;
                    result = '';
                    revealedRows = List.generate(10, (index) => false);
                    generateGameBoard();
                  });
                },
                child: const Text('Restart Game'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
            if (betAmount > 0 && !isGameOver)
              ElevatedButton(
                onPressed: collectWinnings,
                child: const Text('Collect Winnings'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
          ],
        ),
      ),
    );
  }
}
