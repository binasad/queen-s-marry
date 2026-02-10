import 'dart:math';
import 'package:flutter/material.dart';

class NumberGuessingGame extends StatefulWidget {
  @override
  _NumberGuessingGameState createState() => _NumberGuessingGameState();
}

class _NumberGuessingGameState extends State<NumberGuessingGame> {
  final TextEditingController _controller = TextEditingController();
  int secretNumber = Random().nextInt(100) + 1;
  int guessCount = 0;
  int maxTries = 7;
  String message = "I'm thinking of a number between 1 and 100. You have 7 tries!";
  bool gameOver = false;

  void checkGuess() {
    if (gameOver) return;

    int? guess = int.tryParse(_controller.text);
    if (guess == null) {
      setState(() {
        message = "That's not a valid number! Please try again.";
      });
      return;
    }

    setState(() {
      guessCount++;

      if (guess < secretNumber) {
        message = "Too low! Guess again. $secretNumber";
      } else if (guess > secretNumber) {
        message = "Too high! Guess again.$secretNumber";
      } else {
        message = "You got it! The number was $secretNumber.\n"
            "You did it in $guessCount tries!";
        gameOver = true;
      }

      int triesLeft = maxTries - guessCount;
      if (triesLeft <= 0 && !gameOver) {
        message = "Game over! The secret number was $secretNumber.";
        gameOver = true;
      } else if (!gameOver) {
        message += "\nYou have $triesLeft ${triesLeft == 1 ? 'try' : 'tries'} left.";
      }
    });

    _controller.clear();
  }

  void restartGame() {
    setState(() {
      secretNumber = Random().nextInt(100) + 1;
      guessCount = 0;
      gameOver = false;
      message = "I'm thinking of a number between 1 and 100. You have 7 tries!";
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Number Guessing Game"),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Enter your guess",
              ),
              enabled: !gameOver,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: checkGuess,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
              child: Text("Submit Guess"),
            ),
            SizedBox(height: 10),
            if (gameOver)
              ElevatedButton(
                onPressed: restartGame,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: Text("Play Again"),
              ),
          ],
        ),
      ),
    );
  }
}
