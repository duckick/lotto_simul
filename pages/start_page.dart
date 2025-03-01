import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StartPage extends StatelessWidget {
  const StartPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => Get.toNamed('/ticket'),
        child: Stack(
          children: [
            const LottoBallsAnimation(),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'LOTTO',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Tap to Start',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.grey[600],
                    ),
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

class LottoBallsAnimation extends StatefulWidget {
  const LottoBallsAnimation({Key? key}) : super(key: key);

  @override
  State<LottoBallsAnimation> createState() => _LottoBallsAnimationState();
}

class _LottoBallsAnimationState extends State<LottoBallsAnimation>
    with SingleTickerProviderStateMixin {
  late List<LottoBall> balls;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _initializeBalls();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initializeBalls() {
    final random = math.Random();
    balls = List.generate(6, (index) {
      return LottoBall(
        number: random.nextInt(45) + 1,
        x: random.nextDouble() * 300 + 50,
        y: -50.0 - (random.nextDouble() * 200),
        vx: random.nextDouble() * 2 - 1,
        vy: random.nextDouble() * 2 + 3,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: LottoBallsPainter(balls),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          _updateBalls();
          return const SizedBox.expand();
        },
      ),
    );
  }

  void _updateBalls() {
    for (var ball in balls) {
      // Apply gravity
      ball.vy += 0.2;

      // Update position
      ball.x += ball.vx;
      ball.y += ball.vy;

      // Bottom boundary
      if (ball.y > MediaQuery.of(context).size.height - 30) {
        ball.y = MediaQuery.of(context).size.height - 30;
        ball.vy *= -0.8; // Bounce with energy loss
      }

      // Side boundaries
      if (ball.x < 30) {
        ball.x = 30;
        ball.vx *= -0.8;
      }
      if (ball.x > MediaQuery.of(context).size.width - 30) {
        ball.x = MediaQuery.of(context).size.width - 30;
        ball.vx *= -0.8;
      }
    }
  }
}

class LottoBall {
  final int number;
  double x;
  double y;
  double vx;
  double vy;

  LottoBall({
    required this.number,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
  });
}

class LottoBallsPainter extends CustomPainter {
  final List<LottoBall> balls;

  LottoBallsPainter(this.balls);

  @override
  void paint(Canvas canvas, Size size) {
    for (var ball in balls) {
      final paint = Paint()
        ..color = _getBallColor(ball.number)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(ball.x, ball.y),
        25,
        paint,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: ball.number.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          ball.x - textPainter.width / 2,
          ball.y - textPainter.height / 2,
        ),
      );
    }
  }

  Color _getBallColor(int number) {
    if (number <= 10) return Colors.yellow;
    if (number <= 20) return Colors.blue;
    if (number <= 30) return Colors.red;
    if (number <= 40) return Colors.grey;
    return Colors.green;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
