import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/lotto_models.dart';
import '../controllers/lotto_ticket_controller.dart';
import 'lotto_ticket_widget.dart';

class MiniLottoTicketWidget extends StatelessWidget {
  final int index;

  const MiniLottoTicketWidget({Key? key, required this.index})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LottoTicketController>();

    return Obx(() {
      final lottoTicket = controller.tickets[index];

      // 위젯의 총 높이 계산 (더 작게 조정)
      // 로고 행: 16px (로고 높이 + 패딩)
      // 각 게임 라인: 14px (숫자 표시를 위해 약간 높임)
      // 간격: 1px
      final totalHeight = 16.0 +
          1.0 +
          (lottoTicket.lottoRows.length * 14.0) +
          ((lottoTicket.lottoRows.length - 1) * 1.0);

      return GestureDetector(
        onTap: () => _showTicketDetail(context, lottoTicket, index),
        child: Container(
          height: totalHeight, // 명시적인 높이 지정
          constraints: BoxConstraints(maxHeight: totalHeight), // 최대 높이 제한
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4), // 더 각진 모서리로 변경
          ),
          padding: const EdgeInsets.fromLTRB(6, 4, 6, 0), // 상단 패딩도 줄임
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start, // 위에서부터 시작
            children: [
              // 로또 로고와 취소 버튼 (더 작게)
              SizedBox(
                height: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // LOTTO 로고
                    const Text(
                      'LOTTO',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 10, // 글꼴 크기 줄임
                        color: Colors.blue,
                      ),
                    ),
                    // 티켓 삭제 버튼
                    GestureDetector(
                      onTap: () {
                        controller.removeTicket(index);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(1), // 패딩 줄임
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.rectangle, // 원형에서 사각형으로 변경
                          borderRadius: BorderRadius.circular(2), // 살짝 둥근 모서리
                        ),
                        child: Icon(
                          Icons.close,
                          size: 10, // 아이콘 크기 줄임
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 1), // 간격 최소화

              // 게임 라인 A, B, C, D, E 표시 (실제 숫자 표시)
              ...lottoTicket.lottoRows.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;
                final isLastRow = index == lottoTicket.lottoRows.length - 1;
                final hasNumbers = row.numbers.any((num) => num > 0);

                return Container(
                  height: 14, // 숫자 표시를 위해 높이 조정
                  margin: EdgeInsets.only(bottom: isLastRow ? 0 : 1), // 간격 줄임
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // 게임 라인 이름 (A, B, C, D, E)
                      SizedBox(
                        width: 10, // 너비 줄임
                        child: Text(
                          row.rowName,
                          style: TextStyle(
                            fontSize: 9, // 글꼴 크기 줄임
                            fontWeight: FontWeight.bold,
                            color:
                                hasNumbers ? Colors.grey.shade800 : Colors.grey,
                          ),
                        ),
                      ),
                      // 실제 선택한 숫자들 표시
                      if (hasNumbers)
                        Expanded(
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceAround, // 균등 간격으로 배치
                            children: row.numbers
                                .where((num) => num > 0)
                                .map((num) => Container(
                                      width: 14,
                                      height: 14,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 2), // 가로 여백 조정 (3 -> 2)
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                            2), // 원형에서 약간 둥근 사각형으로 변경
                                        color: row.isAuto
                                            ? Colors.green.withOpacity(0.2)
                                            : Colors.orange.withOpacity(0.2),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        num.toString(),
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: row.isAuto
                                              ? Colors.green.shade800
                                              : Colors.orange.shade800,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        )
                      else
                        Expanded(
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceEvenly, // 균등 간격으로 배치
                            children: List.generate(
                              6,
                              (i) => Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 2), // 가로 여백 조정 (3 -> 2)
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                      2), // 원형에서 약간 둥근 사각형으로 변경
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      );
    });
  }

  void _showTicketDetail(BuildContext context, LottoTicket ticket, int index) {
    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4), // 다이얼로그 모서리를 각지게 변경
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '로또 티켓 ${index + 1}장',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      highlightColor: Colors.transparent, // 하이라이트 효과 제거
                    ),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const Divider(),
              Flexible(
                child: SingleChildScrollView(
                  child: LottoTicketWidget(index: index),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }
}
