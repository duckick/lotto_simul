import 'package:get/get.dart';
import '../models/lotto_models.dart';
import 'package:flutter/material.dart';

class LottoTicketController extends GetxController {
  final currentDate = DateTime.now().obs;
  final seedMoney = 1000000.obs;
  final dailyPurchaseLimit = 100000; // 하루 최대 구매 한도 (10만원)
  final tickets = <LottoTicket>[].obs;

  final purchaseCompleted = false.obs;

  final autoNumber = false.obs; // 자동 구매 여부를 관리하는 변수 (체크박스 상태)

  // 다음 추첨일(토요일) 계산
  DateTime getNextDrawDate() {
    final date = currentDate.value;
    // 현재 요일 (1: 월요일, 7: 일요일)
    final weekday = date.weekday;
    // 다음 토요일까지 남은 일수 계산 (토요일은 6)
    final daysUntilSaturday = weekday == 6 ? 7 : 6 - weekday;
    // 다음 토요일 날짜 반환
    return DateTime(date.year, date.month, date.day + daysUntilSaturday);
  }

  // 오늘 구매한 총 금액
  int getTodayTotalAmount() {
    return tickets.fold(0, (sum, ticket) => sum + ticket.amount);
  }

  // 오늘 더 구매 가능한 금액
  int getRemainingDailyLimit() {
    return dailyPurchaseLimit - getTodayTotalAmount();
  }

  // 다음 날로 이동
  void moveToNextDay() {
    currentDate.value = currentDate.value.add(const Duration(days: 1));
    // 새로운 날이 되면 구매 완료 상태 초기화
    purchaseCompleted.value = false;
  }

  // 이전 날로 이동
  void moveToPreviousDay() {
    currentDate.value = currentDate.value.subtract(const Duration(days: 1));
    // 새로운 날이 되면 구매 완료 상태 초기화
    purchaseCompleted.value = false;
  }

  @override
  void onInit() {
    super.onInit();
    // 초기 티켓 생성
    addNewTicket();
  }

  void addNewTicket() {
    // 이미 스낵바가 표시 중인지 확인
    if (Get.isSnackbarOpen) {
      return; // 이미 스낵바가 열려있으면 추가 스낵바를 표시하지 않음
    }

    // 하루 구매 한도 체크
    if (getTodayTotalAmount() >= dailyPurchaseLimit) {
      Get.snackbar(
        '구매 한도 초과',
        '하루에 최대 10만원까지만 구매할 수 있습니다.',
        backgroundColor: Colors.red.shade100,
        duration: const Duration(seconds: 1),
        animationDuration: const Duration(milliseconds: 0),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(8),
      );
      return;
    }

    if (tickets.length >= 20) {
      // 최대 20장까지 구매 가능
      Get.snackbar(
        '알림',
        '하루에 최대 20장까지만 구매할 수 있습니다.',
        backgroundColor: Colors.red.shade100,
        duration: const Duration(seconds: 1),
        animationDuration: const Duration(milliseconds: 0),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(8),
      );
      return;
    }

    tickets.add(LottoTicket(
      round: 1,
      issueDate: currentDate.value,
      drawDate: getNextDrawDate(),
      lottoRows: List.generate(
        5,
        (index) => LottoRow(
          rowName: String.fromCharCode(65 + index),
          numbers: List.filled(6, 0),
          isAuto: false, // 초기에는 자동 아님
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
            isAuto: true, // 자동 생성 표시
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

  // 모든 티켓의 빈 게임을 자동으로 채우는 메소드
  void generateAllAutoNumbers() {
    for (int i = 0; i < tickets.length; i++) {
      final ticket = tickets[i];
      for (var row in ticket.lottoRows) {
        // 선택되지 않은 게임이면 자동 생성
        if (!row.numbers.any((number) => number > 0)) {
          generateAutoNumbers(
            ticketIndex: i,
            rowName: row.rowName,
          );
        }
      }
    }
  }
}
