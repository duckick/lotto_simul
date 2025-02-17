import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../widgets/lotto_ticket_widget.dart';
import '../controllers/lotto_ticket_controller.dart';

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
                    Obx(() => ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.tickets.length,
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
                        )),
                    const SizedBox(height: 16),
                    Obx(() => controller.tickets.length < 10
                        ? ElevatedButton(
                            onPressed: () => controller.addNewTicket(),
                            child: const Text('로또 구매하기'),
                          )
                        : const SizedBox()),
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
