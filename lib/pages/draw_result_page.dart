import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/lotto_ticket_controller.dart';

class DrawResultPage extends StatelessWidget {
  const DrawResultPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LottoTicketController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('로또 추첨 결과'),
        backgroundColor: Colors.amber,
      ),
      body: Obx(() {
        if (controller.drawNumbers.isEmpty) {
          return const Center(
            child: Text('추첨 결과가 없습니다.'),
          );
        }

        return Column(
          children: [
            // 추첨 번호 표시
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.amber.shade100,
              child: Column(
                children: [
                  Text(
                    DateFormat('yyyy년 MM월 dd일')
                        .format(controller.currentDate.value),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '당첨 번호',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ...controller.drawNumbers
                          .map((number) => _buildNumberBall(number)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '+',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildNumberBall(controller.bonusNumber.value,
                          isBonus: true),
                    ],
                  ),
                ],
              ),
            ),

            // 당첨 결과 목록
            Expanded(
              child: controller.winningResults.isEmpty
                  ? const Center(
                      child: Text('당첨된 티켓이 없습니다.'),
                    )
                  : ListView.builder(
                      itemCount: controller.winningResults.length,
                      itemBuilder: (context, index) {
                        final result = controller.winningResults[index];
                        return _buildWinningResultItem(result);
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildNumberBall(int number, {bool isBonus = false}) {
    Color ballColor;

    if (number <= 10) {
      ballColor = Colors.yellow;
    } else if (number <= 20) {
      ballColor = Colors.blue;
    } else if (number <= 30) {
      ballColor = Colors.red;
    } else if (number <= 40) {
      ballColor = Colors.grey;
    } else {
      ballColor = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: ballColor,
        shape: BoxShape.circle,
        border: isBonus ? Border.all(color: Colors.red, width: 2) : null,
      ),
      child: Center(
        child: Text(
          number.toString(),
          style: TextStyle(
            color: (ballColor == Colors.yellow || ballColor == Colors.grey)
                ? Colors.black
                : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildWinningResultItem(Map<String, dynamic> result) {
    final rank = result['rank'] as int;
    final prize = result['prize'] as int;
    final numbers = result['numbers'] as List<int>;
    final rowName = result['row_name'] as String;

    String rankText;
    Color rankColor;

    switch (rank) {
      case 1:
        rankText = '1등';
        rankColor = Colors.red;
        break;
      case 2:
        rankText = '2등';
        rankColor = Colors.orange;
        break;
      case 3:
        rankText = '3등';
        rankColor = Colors.amber;
        break;
      case 4:
        rankText = '4등';
        rankColor = Colors.green;
        break;
      case 5:
        rankText = '5등';
        rankColor = Colors.blue;
        break;
      default:
        rankText = '미당첨';
        rankColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  .map((num) => _buildNumberBall(num))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Text(
              '당첨금: ₩${NumberFormat('#,###').format(prize)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
