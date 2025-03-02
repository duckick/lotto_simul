import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/lotto_ticket_controller.dart';
import '../widgets/mini_lotto_ticket_widget.dart';

class PlayPage extends StatelessWidget {
  const PlayPage({Key? key}) : super(key: key);

  String _getKoreanWeekday(DateTime date) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[date.weekday - 1];
  }

  // 당첨 결과 다이얼로그 표시
  void _showResultDialog(
      BuildContext context, LottoTicketController controller) {
    final drawNumbers = controller.drawNumbers;
    final bonusNumber = controller.bonusNumber.value;
    final winningResults = controller.winningResults;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            const Text('당첨 결과', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 추첨 번호 표시
                const Text('이번 회차 당첨 번호',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...drawNumbers
                        .map((number) => _buildLottoBall(number, false)),
                    const Text(' + ', style: TextStyle(fontSize: 16)),
                    _buildLottoBall(bonusNumber, true),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),

                // 당첨 결과 표시
                if (winningResults.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text('당첨된 번호가 없습니다.')),
                  )
                else
                  ...winningResults.map((result) {
                    final rank = result['rank'] as int;
                    final prize = result['prize'] as int;
                    final numbers = List<int>.from(result['numbers']);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getRankColor(rank),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '$rank등',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '₩${NumberFormat('#,###').format(prize)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: numbers
                                .map((num) =>
                                    _buildLottoBall(num, false, size: 24))
                                .toList(),
                          ),
                          const Divider(),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 결과 확인 후 다음 날로 이동
              controller.actuallyMoveToNextDay();
            },
            child: const Text('다음 날로 이동'),
          ),
        ],
      ),
    );
  }

  // 로또 볼 위젯
  Widget _buildLottoBall(int number, bool isBonus, {double size = 32}) {
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
      width: size,
      height: size,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: ballColor,
        shape: BoxShape.circle,
        border: isBonus ? Border.all(color: Colors.red, width: 2) : null,
      ),
      child: Center(
        child: Text(
          number.toString(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.5,
          ),
        ),
      ),
    );
  }

  // 등수별 색상
  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.red.shade700;
      case 2:
        return Colors.orange.shade700;
      case 3:
        return Colors.amber.shade700;
      case 4:
        return Colors.green.shade700;
      case 5:
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LottoTicketController>();

    // shouldShowResult 변수를 감시하여 결과 팝업 표시
    ever(controller.shouldShowResult, (shouldShow) {
      if (shouldShow) {
        // 약간의 지연 후 결과 다이얼로그 표시 (다른 작업이 완료되도록)
        Future.delayed(const Duration(milliseconds: 100), () {
          _showResultDialog(context, controller);
        });
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.blue.shade200,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(() {
                    final date = controller.currentDate.value;
                    return Text(
                      '${DateFormat('yyyy년 MM월 dd일').format(date)} (${_getKoreanWeekday(date)})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }),
                  Row(
                    children: [
                      // 통계 버튼
                      IconButton(
                        icon: const Icon(Icons.bar_chart),
                        tooltip: '당첨 통계',
                        onPressed: () => controller.goToStatsPage(),
                      ),
                      const SizedBox(width: 8),
                      // 보유금액
                      Obx(() => Text(
                            '₩${NumberFormat('#,###').format(controller.seedMoney.value)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          )),
                    ],
                  ),
                ],
              ),
            ),

            // 상단 요약 정보
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Obx(() {
                      final totalAmount = controller.tickets
                          .fold(0, (sum, ticket) => sum + ticket.amount);
                      return Container(
                        height: 65, // 56 + 9 = 65픽셀로 높이 증가
                        child: Card(
                          margin: EdgeInsets.zero,
                          color: Colors.blue.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('총 구매금액',
                                    style: TextStyle(fontSize: 12)),
                                Text(
                                  '₩${NumberFormat('#,###').format(totalAmount)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Obx(() {
                      return Container(
                        height: 65, // 56 + 9 = 65픽셀로 높이 증가
                        child: InkWell(
                          onTap: () {
                            controller.addNewTicket();
                          },
                          child: Card(
                            margin: EdgeInsets.zero,
                            color: Colors.green.shade50,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('총 티켓수',
                                          style: TextStyle(fontSize: 12)),
                                      Text(
                                        '${controller.tickets.length}장',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // 로또 추가 아이콘 표시
                                  Icon(
                                    Icons.add_circle,
                                    color: Colors.green.shade700,
                                    size: 28,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // 미니 로또 티켓 그리드
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Obx(() {
                  if (controller.tickets.isEmpty) {
                    return const Center(
                      child: Text('로또 티켓이 없습니다. + 버튼을 눌러 티켓을 추가하세요.'),
                    );
                  }

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.8,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    itemCount: controller.tickets.length,
                    itemBuilder: (context, index) {
                      return MiniLottoTicketWidget(index: index);
                    },
                  );
                }),
              ),
            ),

            // 하단 버튼 영역
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // 이미 스낵바가 표시 중인지 확인
                        if (Get.isSnackbarOpen) {
                          return; // 이미 스낵바가 열려있으면 추가 스낵바를 표시하지 않음
                        }

                        // 다이얼로그 없이 바로 모든 티켓의 빈 칸을 자동으로 채우기
                        for (int ticketIndex = 0;
                            ticketIndex < controller.tickets.length;
                            ticketIndex++) {
                          final ticket = controller.tickets[ticketIndex];
                          for (final row in ticket.lottoRows) {
                            // 빈 칸이면 자동 생성
                            if (!row.numbers.any((num) => num > 0)) {
                              controller.generateAutoNumbers(
                                ticketIndex: ticketIndex,
                                rowName: row.rowName,
                              );
                            }
                          }
                        }
                        // Get.snackbar(
                        //   '일괄 자동',
                        //   '일괄 자동이 적용되었습니다.',
                        //   backgroundColor: Colors.green.shade100,
                        //   duration: const Duration(seconds: 1),
                        //   animationDuration: const Duration(milliseconds: 0),
                        //   snackPosition: SnackPosition.TOP,
                        //   margin: const EdgeInsets.all(8),
                        // );
                      },
                      icon: const Icon(Icons.flash_on),
                      label: const Text('일괄 자동'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() {
                      // 추첨일(토요일) 여부 확인
                      final isDrawDay = controller.isDrawDay.value;
                      // 구매 완료 여부 확인
                      final isPurchaseCompleted =
                          controller.purchaseCompleted.value;

                      // 총 구매금액 계산
                      final totalAmount = controller.tickets
                          .fold(0, (sum, ticket) => sum + ticket.amount);

                      // 총 구매금액이 0보다 크면 구매하기, 아니면 넘어가기
                      final canPurchase = totalAmount > 0;

                      // 항상 구매하기 또는 넘어가기 버튼만 표시 (결과 확인 버튼 제거)
                      return ElevatedButton.icon(
                        onPressed: () {
                          // 이미 스낵바가 표시 중인지 확인
                          if (Get.isSnackbarOpen) {
                            return; // 이미 스낵바가 열려있으면 추가 스낵바를 표시하지 않음
                          }

                          if (canPurchase) {
                            // 구매 시도
                            controller.tryPurchaseTickets();
                            // 성공 여부는 tryPurchaseTickets 메소드 내에서 처리함
                          } else {
                            // 총 구매금액이 0일 때는 다음 날로 넘어가기
                            controller.moveToNextDay();
                            Get.snackbar(
                              '다음 날로 이동',
                              '다음 날로 이동했습니다.',
                              backgroundColor: Colors.blue.shade100,
                              duration: const Duration(milliseconds: 500),
                              animationDuration:
                                  const Duration(milliseconds: 0),
                              snackPosition: SnackPosition.TOP,
                              margin: const EdgeInsets.all(8),
                            );
                          }
                        },
                        icon: Icon(canPurchase
                            ? Icons.shopping_cart
                            : Icons.arrow_forward),
                        label: Text(canPurchase ? '구매하기' : '넘어가기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              canPurchase ? Colors.blue : Colors.amber,
                        ),
                      );
                    }),
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
