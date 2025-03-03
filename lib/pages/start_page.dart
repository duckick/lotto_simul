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
          // const LottoBallsAnimation(), // 공 애니메이션 주석 처리
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
                GestureDetector(
                  onTap: () => Get.offAllNamed('/main'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 110, horizontal: 80),
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
            right: 70,
            bottom: 20,
            child: IconButton(
              icon: const Icon(
                Icons.help_outline,
                size: 30,
                color: Colors.blue,
              ),
              onPressed: () => _showHelpDialog(context),
              style: IconButton.styleFrom(
                highlightColor: Colors.transparent,
              ),
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
              style: IconButton.styleFrom(
                highlightColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '게임 방법',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '로또 시뮬레이션 게임',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text('1. 매일 원하는 만큼 로또 티켓을 구매할 수 있습니다. (하루 최대 10만원)'),
                SizedBox(height: 4),
                Text('2. 월요일, 수요일 등 원하는 요일에 자동으로 구매하거나 수동으로 번호를 선택할 수 있습니다.'),
                SizedBox(height: 4),
                Text('3. 토요일에는 추첨 결과를 확인할 수 있습니다.'),
                SizedBox(height: 4),
                Text('4. 당첨금은 자동으로 계좌에 입금됩니다.'),
                SizedBox(height: 4),
                Text('5. 티켓을 구매하지 않은 날은 \'넘어가기\' 버튼을 눌러 다음 날로 이동할 수 있습니다.'),
                SizedBox(height: 8),
                Text(
                  '당첨금 규모',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text('1등: 6개 번호 일치 - 10억원 이상'),
                SizedBox(height: 4),
                Text('2등: 5개 번호 + 보너스 번호 일치 - 5천만원 이상'),
                SizedBox(height: 4),
                Text('3등: 5개 번호 일치 - 150만원 이상'),
                SizedBox(height: 4),
                Text('4등: 4개 번호 일치 - 5만원'),
                SizedBox(height: 4),
                Text('5등: 3개 번호 일치 - 5천원'),
              ],
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        );
      },
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
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
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
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
