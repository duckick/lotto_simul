import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/lotto_models.dart';
import '../controllers/lotto_ticket_controller.dart';
import 'package:get/get.dart';

class LottoTicketWidget extends StatelessWidget {
  final int index;
  const LottoTicketWidget({Key? key, required this.index}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final LottoTicketController controller = Get.find<LottoTicketController>();

    return Obx(() {
      final lottoTicket = controller.tickets[index];
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(border: Border.all(color: Colors.black)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'LOTTO',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text('제 ${lottoTicket.round}회'),
              ],
            ),
            const Divider(height: 4.0, thickness: 1.0),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '발행일 : ${DateFormat('yyyy/MM/dd').format(lottoTicket.issueDate)}',
                ),
              ],
            ),
            const SizedBox(height: 1.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '추첨일 : ${DateFormat('yyyy/MM/dd').format(lottoTicket.drawDate)}',
                ),
              ],
            ),
            const Divider(height: 10.0),
            ...lottoTicket.lottoRows
                .map((row) => _buildLottoRow(row, controller))
                .toList(),
            const Divider(height: 4.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '금액 : ₩${NumberFormat('#,###').format(lottoTicket.amount)}',
                  style: const TextStyle(fontSize: 16),
                ),
                TextButton(
                  onPressed: () => controller.removeTicket(index),
                  style: ButtonStyle(
                    minimumSize: MaterialStateProperty.all(const Size(20, 10)),
                  ),
                  child: const Text('취소'),
                )
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLottoRow(LottoRow row, LottoTicketController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        children: [
          Text(row.rowName),
          const SizedBox(width: 8.0),
          Expanded(
            child: Row(
              children: row.numbers.asMap().entries.map((entry) {
                int numIndex = entry.key;
                int number = entry.value;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: InkWell(
                      onTap: () {
                        int nextNumber =
                            (number == 0 || number >= 45) ? 1 : (number + 1);
                        controller.updateLottoNumber(
                          ticketIndex: index,
                          rowName: row.rowName,
                          index: numIndex,
                          number: nextNumber,
                        );
                      },
                      child: Container(
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          number > 0 ? number.toString().padLeft(2, '0') : '00',
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 6.0),
          ElevatedButton(
            onPressed: () => controller.generateAutoNumbers(
              ticketIndex: index,
              rowName: row.rowName,
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
            ),
            child: const Text('자동'),
          ),
        ],
      ),
    );
  }
}
