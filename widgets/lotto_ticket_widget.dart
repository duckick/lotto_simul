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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          decoration: BoxDecoration(border: Border.all(color: Colors.black)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 영역
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '발행일 : ${DateFormat('yyyy/MM/dd').format(lottoTicket.issueDate)}',
                  ),
                ],
              ),
              const SizedBox(height: 2.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '추첨일 : ${DateFormat('yyyy/MM/dd').format(lottoTicket.drawDate)}',
                  ),
                ],
              ),
              const Divider(height: 8.0),
              // 로또 번호 행들 (게임 당 세로 간격 최소화)
              ...lottoTicket.lottoRows
                  .map((row) => _buildLottoRow(row, controller))
                  .toList(),
              const Divider(height: 4.0),
              // 하단 금액 및 바코드 영역
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '금액 : ₩${NumberFormat('#,###').format(lottoTicket.amount)}',
                    style: const TextStyle(fontSize: 16),
                  ),
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
      padding: const EdgeInsets.symmetric(vertical: 2.0), // 행 사이의 간격을 최소화
      child: Row(
        children: [
          Text(row.rowName),
          const SizedBox(width: 4.0),
          Expanded(
            child: SizedBox(
              height: 32,
              child: Row(
                children: List.generate(
                  6,
                  (i) {
                    final number = row.numbers[i];
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: GestureDetector(
                          onTap: () {
                            // 넘버 피커 다이얼로그 표시
                            _showNumberPickerDialog(
                              controller,
                              index,
                              row.rowName,
                              i,
                              number,
                            );
                          },
                          child: Container(
                            height: 28,
                            decoration: BoxDecoration(
                              color: number > 0
                                  ? Colors.blue.shade100
                                  : Colors.white,
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              number > 0
                                  ? number.toString().padLeft(2, '0')
                                  : '00',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: number > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: number > 0
                                    ? Colors.blue.shade800
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 6.0),
          // '자동' 버튼의 패딩과 최소 크기 조정
          ElevatedButton(
            onPressed: () => controller.generateAutoNumbers(
              ticketIndex: index,
              rowName: row.rowName,
            ),
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6.0, vertical: 5.0),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              textStyle: const TextStyle(fontSize: 12),
            ),
            child: const Text('자동'),
          ),
        ],
      ),
    );
  }

  // 넘버 피커 다이얼로그를 표시하는 메소드
  void _showNumberPickerDialog(
    LottoTicketController controller,
    int ticketIndex,
    String rowName,
    int numberIndex,
    int currentNumber,
  ) {
    // 이미 사용된 번호 목록 가져오기
    final usedNumbers = controller.tickets[ticketIndex].lottoRows
        .firstWhere((row) => row.rowName == rowName)
        .numbers
        .where((num) => num > 0)
        .toList();

    // 현재 번호는 사용된 것으로 간주하지 않음
    usedNumbers.remove(currentNumber);

    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
              crossAxisSpacing: 4.0,
              mainAxisSpacing: 4.0,
            ),
            itemCount: 45,
            itemBuilder: (context, index) {
              final number = index + 1;
              final isSelected = number == currentNumber;
              final isUsed = usedNumbers.contains(number);

              return GestureDetector(
                onTap: isUsed
                    ? null
                    : () {
                        controller.updateLottoNumber(
                          ticketIndex: ticketIndex,
                          rowName: rowName,
                          index: numberIndex,
                          number: number,
                        );
                        Get.back();
                      },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue
                        : isUsed
                            ? Colors.grey.shade300
                            : Colors.white,
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    number.toString().padLeft(2, '0'),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : isUsed
                              ? Colors.grey.shade700
                              : Colors.black,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      barrierDismissible: true, // 바깥쪽 탭으로 닫기 가능
    );
  }

  /// LottoTicket의 정보를 기반으로 Code93 바코드를 생성하여 위젯으로 반환
  Widget _generateBarcode(LottoTicket lottoTicket) {
    String data =
        '${lottoTicket.round}-${lottoTicket.issueDate.millisecondsSinceEpoch}-${lottoTicket.amount}';
    return BarcodeWidget(
      barcode: Barcode.code93(),
      data: data,
      width: 70,
      height: 26,
      drawText: false,
    );
  }
}
