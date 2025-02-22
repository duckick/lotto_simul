import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/lotto_models.dart';
import '../controllers/lotto_ticket_controller.dart';
import 'package:get/get.dart';
import 'package:barcode_widget/barcode_widget.dart';

class LottoTicketWidget extends StatelessWidget {
  final int index;
  const LottoTicketWidget({Key? key, required this.index}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final LottoTicketController controller = Get.find<LottoTicketController>();

    return Transform.scale(
      scale: 1.0,
      child: Obx(() {
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
                  // 구매하기 버튼이 눌렸으면 바코드 위젯을 표시, 아니면 아무것도 표시하지 않음
                  controller.purchaseCompleted.value
                      ? _generateBarcode(lottoTicket)
                      : Container(),
                ],
              ),
            ],
          ),
        );
      }),
    );
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
              padding:
              const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: const Text('자동'),
          ),
        ],
      ),
    );
  }

  /// LottoTicket의 정보를 기반으로 Code93 바코드를 생성하여 위젯으로 반환
  Widget _generateBarcode(LottoTicket lottoTicket) {
    String data =
        '${lottoTicket.round}-${lottoTicket.issueDate.millisecondsSinceEpoch}-${lottoTicket.amount}';
    return BarcodeWidget(
      barcode: Barcode.code93(),
      data: data,
      width: 70, // 기존 가로 200의 반절
      height: 26, // 기존 세로 80의 반절
      drawText: false,
    );
  }
}