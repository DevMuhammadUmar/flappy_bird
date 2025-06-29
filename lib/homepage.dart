import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flappy_bird/bird.dart';
import 'package:flappy_bird/barriers.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  double birdY = 0;
  double time = 0;
  double height = 0;
  double initialHeight = 0;
  Timer? gameTimer;
  bool gameHasStarted = false;
  int score = 0;
  int bestScore = 0;

  static const int numBarriers = 2;
  final List<double> barrierX = [2, 3.5];
  final List<double> barrierHeight = [0.5, 0.5];
  final List<bool> barrierScored = [false, false];

  // Constants for better game balance
  static const double birdSize = 0.05; // Bird's collision box size (smaller)
  static const double gapSize = 0.8; // Gap between barriers (much larger)
  static const double maxBirdY = 0.95; // Maximum bird position
  static const double minBirdY = -0.95; // Minimum bird position

  void jump() {
    time = 0;
    initialHeight = birdY;
  }

  void startGame() {
    gameHasStarted = true;
    time = 0;
    initialHeight = birdY;

    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      time += 0.05;
      height = -4.9 * time * time + 2.5 * time;

      setState(() {
        birdY = initialHeight - height;

        // Clamp bird position to prevent it from going too far out of bounds
        birdY = birdY.clamp(minBirdY, maxBirdY);

        // Move barriers
        for (int i = 0; i < numBarriers; i++) {
          barrierX[i] -= 0.05;

          // Score when bird passes barrier (check center of barrier)
          if (!barrierScored[i] && barrierX[i] < -0.1) {
            score++;
            barrierScored[i] = true;
            print("Score! Current score: $score"); // Debug
          }

          if (barrierX[i] < -1.5) {
            barrierX[i] += 3.5;
            // Generate much more varied barrier heights
            barrierHeight[i] = 0.1 + Random().nextDouble() * 0.8; // Full range from 0.1 to 0.9
            barrierScored[i] = false;
            print("Barrier $i reset, new height: ${barrierHeight[i]}"); // Debug
          }
        }
        
        // Debug bird position occasionally
        if ((time * 20).round() % 20 == 0) { // Every second
          print("Bird position: $birdY, Time: $time");
        }
      });

      // Check for game over conditions with debug info
      bool collision = checkCollision();
      bool tooHigh = birdY >= maxBirdY;
      bool tooLow = birdY <= minBirdY;
      
      if (collision || tooHigh || tooLow) {
        if (collision) print("Game over: Collision");
        if (tooHigh) print("Game over: Too high - birdY=$birdY");
        if (tooLow) print("Game over: Too low - birdY=$birdY");
        endGame();
      }
    });
  }

  bool checkCollision() {
    for (int i = 0; i < numBarriers; i++) {
      // Very tight horizontal detection - only when bird is directly at the barrier
      if (barrierX[i] < 0.01 && barrierX[i] > -0.01) {
        // Much simpler gap calculation
        // The gap is centered around y=0, extending gapSize/2 up and down
        double gapTop = gapSize / 2;
        double gapBottom = -gapSize / 2;
        
        // Very small offset based on barrier height to add variation
        double offset = (barrierHeight[i] - 0.5) * 0.8; // Increased offset for more variation
        gapTop += offset;
        gapBottom += offset;
        
        // Check if bird hits barriers (with debug info)
        bool collision = (birdY + birdSize > gapTop || birdY - birdSize < gapBottom);
        
        // Debug print with barrier position
        if (collision) {
          print("Collision: birdY=$birdY, barrierX=${barrierX[i]}, gapTop=$gapTop, gapBottom=$gapBottom");
        }
        
        return collision;
      }
    }
    return false;
  }

  void endGame() {
    gameTimer?.cancel();
    gameHasStarted = false;

    if (score > bestScore) bestScore = score;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Game Over"),
          content: Text("Your Score: $score"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                resetGame();
              },
              child: const Text("Restart"),
            )
          ],
        );
      },
    );
  }

  void resetGame() {
    setState(() {
      birdY = 0;
      time = 0;
      initialHeight = 0;
      height = 0;
      score = 0;
      barrierX[0] = 2;
      barrierX[1] = 3.5;
      barrierHeight[0] = 0.2 + Random().nextDouble() * 0.6;
      barrierHeight[1] = 0.2 + Random().nextDouble() * 0.6;
      barrierScored[0] = false;
      barrierScored[1] = false;
      gameHasStarted = false;
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
      onTap: () {
        if (gameHasStarted) {
          jump();
        } else {
          startGame();
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Bird
                  AnimatedContainer(
                    alignment: Alignment(0, birdY),
                    duration: const Duration(milliseconds: 0),
                    color: Colors.lightBlue,
                    child: MyBird(),
                  ),

                  // Tap to Play text
                  if (!gameHasStarted)
                    Container(
                      alignment: const Alignment(0, -0.2),
                      child: const Text(
                        "TAP TO PLAY",
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),

                  // Barriers - Fixed positioning
                  for (int i = 0; i < numBarriers; i++) ...[
                    // Bottom Barrier - More varied sizing based on barrier height
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 0),
                      alignment: Alignment(barrierX[i], 1.1),
                      child: Barriers(size: 80.0 + (barrierHeight[i] * 120.0)), // More variation
                    ),

                    // Top Barrier - More varied sizing (inverse of bottom)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 0),
                      alignment: Alignment(barrierX[i], -1.1),
                      child: Barriers(size: 80.0 + ((1.0 - barrierHeight[i]) * 120.0)), // More variation
                    ),
                  ]
                ],
              ),
            ),

            // Ground
            Container(
              height: 18,
              color: const Color.fromARGB(255, 40, 134, 55),
            ),

            // Score panel
            Expanded(
              child: Container(
                color: const Color.fromARGB(255, 90, 70, 33),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Score",
                            style:
                                TextStyle(color: Colors.white, fontSize: 20)),
                        const SizedBox(height: 10),
                        Text("$score",
                            style:
                                const TextStyle(color: Colors.white, fontSize: 20))
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Best",
                            style:
                                TextStyle(color: Colors.white, fontSize: 20)),
                        const SizedBox(height: 10),
                        Text("$bestScore",
                            style:
                                const TextStyle(color: Colors.white, fontSize: 20))
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}