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

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LottoTicketController>();

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
                  Obx(() => Text(
                        '보유금액: ₩${NumberFormat('#,###').format(controller.seedMoney.value)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      )),
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
                        Get.snackbar(
                          '일괄 자동',
                          '일괄 자동이 적용되었습니다.',
                          backgroundColor: Colors.green.shade100,
                          duration: const Duration(seconds: 1),
                          animationDuration: const Duration(milliseconds: 0),
                          snackPosition: SnackPosition.TOP,
                          margin: const EdgeInsets.all(8),
                        );
                      },
                      icon: const Icon(Icons.flash_on),
                      label: const Text('일괄 자동'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() {
                      // 총 구매금액 계산
                      final totalAmount = controller.tickets
                          .fold(0, (sum, ticket) => sum + ticket.amount);

                      // 총 구매금액이 0보다 크면 구매하기, 아니면 넘어가기
                      final canPurchase = totalAmount > 0;

                      return ElevatedButton.icon(
                        onPressed: () {
                          // 이미 스낵바가 표시 중인지 확인
                          if (Get.isSnackbarOpen) {
                            return; // 이미 스낵바가 열려있으면 추가 스낵바를 표시하지 않음
                          }

                          if (canPurchase) {
                            controller.purchaseCompleted.value = true;
                            Get.snackbar(
                              '구매 완료',
                              '${controller.tickets.length}장의 로또를 구매했습니다.',
                              backgroundColor: Colors.green.shade100,
                              duration: const Duration(seconds: 1),
                              animationDuration:
                                  const Duration(milliseconds: 0),
                              snackPosition: SnackPosition.TOP,
                              margin: const EdgeInsets.all(8),
                            );
                          } else {
                            // 총 구매금액이 0일 때는 다음 날로 넘어가기
                            controller.moveToNextDay();
                            Get.snackbar(
                              '다음 날로 이동',
                              '다음 날로 이동했습니다.',
                              backgroundColor: Colors.blue.shade100,
                              duration: const Duration(seconds: 1),
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
