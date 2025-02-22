import 'package:get/get.dart';
import '../models/lotto_models.dart';

class LottoTicketController extends GetxController {
  final currentDate = DateTime.now().obs;
  final seedMoney = 1000000.obs;
  final tickets = <LottoTicket>[].obs;

  final purchaseCompleted = false.obs;

  @override
  void onInit() {
    super.onInit();
    // 초기에 1장의 로또 용지 생성
    addNewTicket();
  }

  void addNewTicket() {
    if (tickets.length >= 10) {
      Get.snackbar('알림', '최대 10장까지만 구매할 수 있습니다.');
      return;
    }

    tickets.add(LottoTicket(
      round: 1,
      issueDate: DateTime.now(),
      drawDate: DateTime.now().add(const Duration(days: 7)),
      lottoRows: List.generate(
        5,
        (index) => LottoRow(
          rowName: String.fromCharCode(65 + index),
          numbers: List.filled(6, 0),
        ),
      ),
      amount: 0,
    ));
  }

  void removeTicket(int index) {
    if (index >= 0 && index < tickets.length) {
      tickets.removeAt(index);
    }
  }

  void resetTicket(int index) {
    if (index >= 0 && index < tickets.length) {
      final resetRows = tickets[index]
          .lottoRows
          .map((row) => LottoRow(
                rowName: row.rowName,
                numbers: List.filled(6, 0),
              ))
          .toList();

      tickets[index] = tickets[index].copyWith(
        lottoRows: resetRows,
        amount: 0,
      );
    }
  }

  void updateLottoNumber({
    required int ticketIndex,
    required String rowName,
    required int index,
    required int number,
  }) {
    if (ticketIndex >= 0 && ticketIndex < tickets.length) {
      final updatedRows = tickets[ticketIndex].lottoRows.map((row) {
        if (row.rowName == rowName) {
          final updatedNumbers = List<int>.from(row.numbers);
          updatedNumbers[index] = number;
          return LottoRow(
            rowName: row.rowName,
            numbers: updatedNumbers,
          );
        }
        return row;
      }).toList();

      tickets[ticketIndex] = tickets[ticketIndex].copyWith(
        lottoRows: updatedRows,
        amount: _calculateAmount(updatedRows),
      );
    }
  }

  void generateAutoNumbers({
    required int ticketIndex,
    required String rowName,
  }) {
    if (ticketIndex >= 0 && ticketIndex < tickets.length) {
      final numbers = List.generate(45, (index) => index + 1)..shuffle();
      final selectedNumbers = numbers.take(6).toList()..sort();

      final updatedRows = tickets[ticketIndex].lottoRows.map((row) {
        if (row.rowName == rowName) {
          return LottoRow(
            rowName: row.rowName,
            numbers: selectedNumbers,
            isAuto: true,
          );
        }
        return row;
      }).toList();

      tickets[ticketIndex] = tickets[ticketIndex].copyWith(
        lottoRows: updatedRows,
        amount: _calculateAmount(updatedRows),
      );
    }
  }

  int _calculateAmount(List<LottoRow> rows) {
    int count = 0;
    for (var row in rows) {
      if (row.numbers.any((number) => number > 0)) {
        count++;
      }
    }
    return count * 1000;
  }
}
