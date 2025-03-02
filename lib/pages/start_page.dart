import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/lotto_ticket_controller.dart';
import '../services/database_service.dart';

class StartPage extends StatelessWidget {
  const StartPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
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
                InkWell(
                  onTap: () => Get.offAllNamed('/main'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 48),
                    decoration: BoxDecoration(
                      // color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Tap to Start',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: IconButton(
              icon: const Icon(
                Icons.settings,
                size: 30,
                color: Colors.blue,
              ),
              onPressed: () => _showSettingsDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '설정',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.red),
                title: const Text('모든 데이터 초기화'),
                subtitle: const Text('모든 데이터가 삭제되고 처음부터 다시 시작합니다.'),
                onTap: () => _showResetConfirmationDialog(context),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  void _showResetConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('데이터 초기화'),
          content: const Text(
            '정말로 모든 데이터를 초기화하시겠습니까?\n\n모든 구매 내역, 당첨 결과, 통계 데이터가 영구적으로 삭제됩니다.',
            style: TextStyle(
              color: Colors.red,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                await _resetAllData();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                Get.snackbar(
                  '초기화 완료',
                  '모든 데이터가 초기화되었습니다.',
                  backgroundColor: Colors.green.shade100,
                  duration: const Duration(seconds: 2),
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              child: const Text(
                '초기화',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetAllData() async {
    try {
      await DatabaseService.instance.resetAllData();

      final controller = Get.find<LottoTicketController>();
      controller.seedMoney.value = 1000000;
      controller.totalSpent.value = 0;
      controller.winningResults.clear();
      controller.allWinningResults.clear();
      controller.drawNumbers.clear();
      controller.bonusNumber.value = 0;

      controller.currentDate.value = DateTime.now();

      controller.tickets.clear();
      controller.addNewTicket();

      controller.isDrawDay.value = controller.isCurrentDateDrawDay();
    } catch (e) {
      print('데이터 초기화 오류: $e');
      Get.snackbar(
        '오류',
        '데이터 초기화 중 오류가 발생했습니다: $e',
        backgroundColor: Colors.red.shade100,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
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
