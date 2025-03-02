import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/lotto_ticket_controller.dart';

class ResultPage extends StatelessWidget {
  const ResultPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LottoTicketController>();

    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          // 추첨일이 아니면 안내 메시지 표시
          if (!controller.isDrawDay.value) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '오늘은 추첨일이 아닙니다',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '추첨은 매주 토요일에 진행됩니다',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '다음 추첨일: ${DateFormat('yyyy년 MM월 dd일').format(controller.getNextDrawDate())}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          // 추첨일이면 추첨 결과 표시
          return Column(
            children: [
              // 상단 정보 표시
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.blue.shade200,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '추첨 결과',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('yyyy년 MM월 dd일')
                          .format(controller.currentDate.value),
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // 추첨 번호 표시
              if (controller.drawNumbers.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '당첨 번호',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ...controller.drawNumbers
                              .map((number) => _buildNumberBall(number)),
                          const SizedBox(width: 16),
                          const Text(
                            '+',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 16),
                          _buildNumberBall(controller.bonusNumber.value,
                              isBonus: true),
                        ],
                      ),
                    ],
                  ),
                ),

              // 당첨 결과 표시
              Expanded(
                child: controller.winningResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sentiment_dissatisfied,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '당첨된 티켓이 없습니다',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.winningResults.length,
                        itemBuilder: (context, index) {
                          final result = controller.winningResults[index];
                          return _buildWinningResultCard(result);
                        },
                      ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildNumberBall(int number, {bool isBonus = false}) {
    Color ballColor;
    if (number <= 10) {
      ballColor = Colors.yellow.shade600;
    } else if (number <= 20) {
      ballColor = Colors.blue.shade600;
    } else if (number <= 30) {
      ballColor = Colors.red.shade600;
    } else if (number <= 40) {
      ballColor = Colors.grey.shade700;
    } else {
      ballColor = Colors.green.shade600;
    }

    return Container(
      width: 40,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: ballColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: isBonus
            ? Border.all(
                color: Colors.white,
                width: 2,
              )
            : null,
      ),
      child: Center(
        child: Text(
          number.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildWinningResultCard(Map<String, dynamic> result) {
    final rank = result['rank'] as int;
    final prize = result['prize'] as int;
    final numbers = result['numbers'] as List<int>;
    final rowName = result['row_name'] as String;

    String rankText;
    Color rankColor;

    switch (rank) {
      case 1:
        rankText = '1등';
        rankColor = Colors.red.shade700;
        break;
      case 2:
        rankText = '2등';
        rankColor = Colors.orange.shade700;
        break;
      case 3:
        rankText = '3등';
        rankColor = Colors.amber.shade700;
        break;
      case 4:
        rankText = '4등';
        rankColor = Colors.green.shade700;
        break;
      case 5:
        rankText = '5등';
        rankColor = Colors.blue.shade700;
        break;
      default:
        rankText = '미당첨';
        rankColor = Colors.grey.shade700;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '게임 $rowName',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: rankColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    rankText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: numbers
                  .where((num) => num > 0)
                  .map((num) => _buildNumberBall(num, isBonus: false))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '당첨금',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                Text(
                  '₩${NumberFormat('#,###').format(prize)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
