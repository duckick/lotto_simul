import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/lotto_ticket_controller.dart';
import '../widgets/lotto_ticket_widget.dart';

class PlayPage extends StatelessWidget {
  const PlayPage({Key? key}) : super(key: key);

  String _getKoreanWeekday(DateTime date) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LottoTicketController>();

    // 티켓이 2장이 아니면 2장이 되도록 보장 (이미 2장이 생성되어 있다고 가정)
    if (controller.tickets.length < 2) {
      while (controller.tickets.length < 2) {
        controller.addNewTicket();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('로또 구매'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (controller.tickets.isNotEmpty) {
                controller.resetTicket(0);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
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
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 2, // 로또 티켓 위젯 2장 고정
                      separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return Center(
                          child: Card(
                            elevation: 4,
                            child: LottoTicketWidget(index: index),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // 3개의 버튼 (전날, 구매하기, 다음날)을 가로로 배치
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // 전날로 이동하는 기능 구현
                          },
                          child: const Text('전날'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            // 구매하기 버튼을 누르면 구매 완료 상태를 true로 변경
                            controller.purchaseCompleted.value = true;
                          },
                          child: const Text('구매하기'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            // 다음날로 이동하는 기능 구현
                          },
                          child: const Text('다음날'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}