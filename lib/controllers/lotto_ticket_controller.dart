import 'package:get/get.dart';
import '../models/lotto_models.dart';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/lotto_draw_service.dart';

class LottoTicketController extends GetxController {
  final currentDate = DateTime.now().obs;
  final seedMoney = 1000000.obs;
  final dailyPurchaseLimit = 100000; // 하루 최대 구매 한도 (10만원)
  final tickets = <LottoTicket>[].obs;

  // 당첨 결과 관련 변수
  final winningResults = <Map<String, dynamic>>[].obs;
  final allWinningResults = <Map<String, dynamic>>[].obs; // 모든 당첨 결과를 저장하는 변수
  final isDrawDay = false.obs;
  final drawNumbers = <int>[].obs;
  final bonusNumber = 0.obs;
  final totalSpent = 0.obs; // 총 구매 금액
  final shouldShowResult = false.obs; // 결과 팝업을 표시해야 하는지 여부

  // purchaseCompleted 변수는 더 이상 사용하지 않지만 기존 코드와의 호환성을 위해 유지
  final purchaseCompleted = false.obs;
  final autoNumber = false.obs; // 자동 구매 여부를 관리하는 변수 (체크박스 상태)

  // 서비스 인스턴스
  final _dbService = DatabaseService.instance;
  final _drawService = LottoDrawService.instance;

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

  // 현재 날짜가 추첨일(토요일)인지 확인
  bool isCurrentDateDrawDay() {
    return currentDate.value.weekday == 6; // 6은 토요일
  }

  // 다음 날로 이동
  Future<void> moveToNextDay() async {
    // 현재 날짜가 토요일인지 확인
    final isCurrentlySaturday = isCurrentDateDrawDay();

    // 토요일이면 추첨 결과를 확인하고 결과 다이얼로그 표시
    if (isCurrentlySaturday) {
      await checkDrawResults();
      // 직접 다이얼로그를 표시하도록 함수 호출
      _showResultDialogAfterDelay();
      return; // 여기서 리턴하여 _showResultDialogAfterDelay 내에서 다음 날로 이동하도록 함
    }

    // 토요일이 아니면 결과 팝업 표시 신호 초기화
    shouldShowResult.value = false;

    // 현재 티켓 수 저장
    final currentTicketCount = tickets.length;

    // 날짜 변경
    currentDate.value = currentDate.value.add(const Duration(days: 1));

    // 구매 완료 상태 초기화 (더 이상 사용하지 않지만 호환성을 위해 유지)
    purchaseCompleted.value = false;

    // 티켓 목록 초기화하되, 같은 수의 빈 티켓 생성
    tickets.clear();

    // 이전과 동일한 수의 티켓 생성 (최소 1장)
    final ticketsToCreate = currentTicketCount > 0 ? currentTicketCount : 1;
    for (int i = 0; i < ticketsToCreate; i++) {
      _addEmptyTicket();
    }

    // 추첨일 여부 업데이트
    isDrawDay.value = isCurrentDateDrawDay();

    // 추첨일이 되었을 때만 초기화 (금요일에서 토요일로 넘어갈 때는 당첨 결과를 확인하지 않음)
    if (!isDrawDay.value) {
      // 추첨일이 아니면 당첨 결과 초기화
      winningResults.clear();
      drawNumbers.clear();
      bonusNumber.value = 0;
    }

    // 게임 상태 저장
    await _saveGameState();
  }

  // 실제로 다음 날로 이동하는 함수 (결과 표시 후 호출됨)
  Future<void> actuallyMoveToNextDay() async {
    shouldShowResult.value = false; // 결과 팝업 표시 신호 초기화

    // 현재 티켓 수 저장
    final currentTicketCount = tickets.length;

    // 날짜 변경
    currentDate.value = currentDate.value.add(const Duration(days: 1));

    // 구매 완료 상태 초기화 (더 이상 사용하지 않지만 호환성을 위해 유지)
    purchaseCompleted.value = false;

    // 티켓 목록 초기화하되, 같은 수의 빈 티켓 생성
    tickets.clear();

    // 이전과 동일한 수의 티켓 생성 (최소 1장)
    final ticketsToCreate = currentTicketCount > 0 ? currentTicketCount : 1;
    for (int i = 0; i < ticketsToCreate; i++) {
      _addEmptyTicket();
    }

    // 추첨일 여부 업데이트
    isDrawDay.value = isCurrentDateDrawDay();

    // 추첨일이면 추첨 결과 확인
    if (isDrawDay.value) {
      await checkDrawResults();
    } else {
      // 추첨일이 아니면 당첨 결과 초기화
      winningResults.clear();
      drawNumbers.clear();
      bonusNumber.value = 0;
    }
  }

  // 이전 날로 이동
  Future<void> moveToPreviousDay() async {
    // 현재 날짜가 일요일인지 확인
    final isCurrentlySunday = currentDate.value.weekday == 7;

    // 날짜 변경
    currentDate.value = currentDate.value.subtract(const Duration(days: 1));

    // 구매 완료 상태 초기화
    purchaseCompleted.value = false;

    // 티켓 목록 초기화하되, 같은 수의 빈 티켓 생성
    final currentTicketCount = tickets.length;
    tickets.clear();

    // 이전과 동일한 수의 티켓 생성 (최소 1장)
    final ticketsToCreate = currentTicketCount > 0 ? currentTicketCount : 1;
    for (int i = 0; i < ticketsToCreate; i++) {
      _addEmptyTicket();
    }

    // 추첨일 여부 업데이트
    isDrawDay.value = isCurrentDateDrawDay();

    // 일요일에서 토요일로 이동할 때만 당첨 결과 확인
    if (isCurrentlySunday && isDrawDay.value) {
      await checkDrawResults();
    } else {
      // 그 외의 경우에는 당첨 결과 초기화
      winningResults.clear();
      drawNumbers.clear();
      bonusNumber.value = 0;
    }

    // 게임 상태 저장
    await _saveGameState();
  }

  // 추첨 결과 확인
  Future<void> checkDrawResults() async {
    // 현재 날짜가 추첨일이 아니면 무시
    if (!isCurrentDateDrawDay()) return;

    // 추첨 번호 생성 또는 가져오기
    final drawResult = await _drawService.drawLottoNumbers(currentDate.value);

    // 추첨 번호 업데이트
    drawNumbers.assignAll(List<int>.from(drawResult['draw_numbers']));
    bonusNumber.value = drawResult['bonus_number'] as int;

    // 이 추첨일에 해당하는 티켓의 당첨 여부 확인
    final results =
        await _drawService.checkAllTicketsForDrawDate(currentDate.value);

    // 당첨 결과 업데이트
    winningResults.assignAll(results);

    // 모든 당첨 결과에 추가
    if (results.isNotEmpty) {
      allWinningResults.addAll(results);
    }

    // 당첨금 추가
    int totalPrize = 0;
    for (var result in results) {
      totalPrize += result['prize'] as int;
    }

    // 당첨금을 보유금액에 추가
    if (totalPrize > 0) {
      seedMoney.value += totalPrize;

      // 당첨 알림
      Get.snackbar(
        '당첨 알림',
        '총 ${results.length}개의 당첨이 있습니다. 당첨금: ₩${totalPrize.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
        backgroundColor: Colors.amber.shade100,
        duration: const Duration(seconds: 3),
        animationDuration: const Duration(milliseconds: 0),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(8),
      );
    }
  }

  // 빈 티켓 추가 (내부 메소드)
  void _addEmptyTicket() {
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

  // 로또 구매 시도
  Future<void> tryPurchaseTickets() async {
    // 이미 구매 완료된 경우
    if (purchaseCompleted.value) {
      Get.snackbar(
        '구매 완료',
        '이미 오늘의 구매를 완료했습니다. 다음 날로 이동하세요.',
        backgroundColor: Colors.orange.shade100,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(8),
      );
      return;
    }

    // 구매할 티켓이 없는 경우
    if (tickets.isEmpty) {
      Get.snackbar(
        '구매 실패',
        '구매할 티켓이 없습니다.',
        backgroundColor: Colors.red.shade100,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(8),
      );
      return;
    }

    // 총 구매 금액 계산
    final totalAmount = getTodayTotalAmount();

    // 구매 금액이 0인 경우
    if (totalAmount <= 0) {
      Get.snackbar(
        '구매 실패',
        '구매할 티켓이 없습니다.',
        backgroundColor: Colors.red.shade100,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(8),
      );
      return;
    }

    // 잔액 부족
    if (totalAmount > seedMoney.value) {
      Get.snackbar(
        '잔액 부족',
        '보유 금액이 부족합니다.',
        backgroundColor: Colors.red.shade100,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(8),
      );
      return;
    }

    // 구매 처리
    seedMoney.value -= totalAmount;
    totalSpent.value += totalAmount;

    // 구매 완료 상태로 변경
    purchaseCompleted.value = true;

    // 구매한 티켓 저장
    await _savePurchasedTickets();

    // 토요일에 구매한 경우 moveToNextDay 호출 (결과 확인 포함)
    if (isDrawDay.value) {
      await moveToNextDay();
    } else {
      // 토요일이 아닌 경우 바로 다음 날로 이동
      await moveToNextDay();
    }

    // 게임 상태 저장
    await _saveGameState();
  }

  // 이번 주 구매한 티켓 수 조회
  Future<int> getWeeklyTicketCount() async {
    try {
      // 이번 주 토요일(추첨일)에 해당하는 모든 티켓 조회
      final tickets =
          await _dbService.getAllTicketsForDrawDate(currentDate.value);
      return tickets.length;
    } catch (e) {
      print('주간 티켓 수 조회 오류: $e');
      return 0;
    }
  }

  // 지연 후 결과 다이얼로그를 표시하는 함수
  void _showResultDialogAfterDelay() {
    Future.delayed(const Duration(milliseconds: 300), () async {
      // 이번 주 구매한 티켓 수 조회
      final weeklyTicketCount = await getWeeklyTicketCount();

      // 당첨 결과를 등수별로 그룹화
      final Map<int, List<Map<String, dynamic>>> groupedResults = {};

      for (var result in winningResults) {
        final rank = result['rank'] as int;
        if (!groupedResults.containsKey(rank)) {
          groupedResults[rank] = [];
        }
        groupedResults[rank]!.add(result);
      }

      // 등수 순서대로 정렬 (1등부터 5등까지)
      final sortedRanks = groupedResults.keys.toList()..sort();

      // 로또 결과 다이얼로그를 직접 호출
      Get.dialog(
        AlertDialog(
          title: const Text('당첨 결과',
              style: TextStyle(fontWeight: FontWeight.bold)),
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
                      _buildLottoBall(bonusNumber.value, true),
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
                    ...sortedRanks.map((rank) {
                      final resultsForRank = groupedResults[rank]!;
                      final totalPrizeForRank = resultsForRank.fold<int>(
                          0, (sum, result) => sum + (result['prize'] as int));

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 등수와 총 당첨금 표시
                            Text(
                              '$rank등: ${resultsForRank.length}개 - ₩${totalPrizeForRank.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: rank <= 3 ? Colors.red : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // 각 당첨 번호와 구매 날짜 표시
                            ...resultsForRank.map((result) {
                              final numbers = List<int>.from(result['numbers']);
                              final purchaseDate =
                                  result['purchase_date'] != null
                                      ? DateTime.parse(
                                          result['purchase_date'].toString())
                                      : null;
                              final purchaseDateStr = purchaseDate != null
                                  ? '${purchaseDate.year}.${purchaseDate.month.toString().padLeft(2, '0')}.${purchaseDate.day.toString().padLeft(2, '0')}'
                                  : '';

                              return Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 4.0, left: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text('${numbers.join(', ')}'),
                                    ),
                                    if (purchaseDateStr.isNotEmpty)
                                      Text(
                                        purchaseDateStr,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                            const Divider(),
                          ],
                        ),
                      );
                    }).toList(),

                  // 이번 주 구매한 티켓 수 표시
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      '이번 주 구매한 로또: ${weeklyTicketCount}장',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        // fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back(); // 다이얼로그 닫기
                // 다음 날로 이동
                actuallyMoveToNextDay();
              },
              child: const Text('다음 날로 이동'),
            ),
          ],
        ),
        barrierDismissible: false, // 바깥쪽 터치로 닫히지 않도록 설정
      );
    });
  }

  // 로또 볼 위젯
  Widget _buildLottoBall(int number, bool isBonus, {double size = 24.0}) {
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

  // 통계 화면으로 이동
  void goToStatsPage() {
    Get.toNamed('/stats');
  }

  @override
  void onInit() async {
    super.onInit();

    // 저장된 게임 상태가 있는지 확인하고 로드
    final hasState = await _dbService.hasGameState();
    if (hasState) {
      await _loadGameState();
    } else {
      // 초기 티켓 생성
      addNewTicket();

      // 추첨일 여부 초기화
      isDrawDay.value = isCurrentDateDrawDay();

      // 추첨일이면 추첨 결과 확인 (구매 여부와 관계없이)
      if (isDrawDay.value) {
        await checkDrawResults();
      }

      // 초기 상태 저장
      await _saveGameState();
    }

    // 이전 당첨 결과 로드
    await loadAllWinningResults();

    // 게임 상태 변경 시 저장하도록 리스너 설정
    ever(currentDate, (_) => _saveGameState());
    ever(seedMoney, (_) => _saveGameState());
    ever(tickets, (_) => _saveGameState());
    ever(isDrawDay, (_) => _saveGameState());
    ever(drawNumbers, (_) => _saveGameState());
    ever(bonusNumber, (_) => _saveGameState());
    ever(totalSpent, (_) => _saveGameState());
  }

  // 게임 상태 저장
  Future<void> _saveGameState() async {
    try {
      await _dbService.saveGameState(
        currentDate: currentDate.value,
        seedMoney: seedMoney.value,
        tickets: tickets.toList(),
        isDrawDay: isDrawDay.value,
        drawNumbers: drawNumbers.toList(),
        bonusNumber: bonusNumber.value,
        totalSpent: totalSpent.value,
      );
    } catch (e) {
      print('게임 상태 저장 오류: $e');
    }
  }

  // 게임 상태 로드
  Future<void> _loadGameState() async {
    try {
      final state = await _dbService.loadGameState();
      if (state != null) {
        currentDate.value = state['current_date'] as DateTime;
        seedMoney.value = state['seed_money'] as int;
        tickets.assignAll(state['tickets'] as List<LottoTicket>);
        isDrawDay.value = state['is_draw_day'] as bool;
        drawNumbers.assignAll(state['draw_numbers'] as List<int>);
        bonusNumber.value = state['bonus_number'] as int;
        totalSpent.value = state['total_spent'] as int;

        print('게임 상태를 성공적으로 로드했습니다.');
      }
    } catch (e) {
      print('게임 상태 로드 오류: $e');
    }
  }

  // 구매한 티켓 저장
  Future<void> _savePurchasedTickets() async {
    try {
      for (var ticket in tickets) {
        if (ticket.amount > 0) {
          // 금액이 있는 티켓만 저장 (선택된 번호가 있는 티켓)
          await _dbService.savePurchasedTicket(currentDate.value, ticket);
        }
      }
    } catch (e) {
      print('티켓 저장 오류: $e');
    }
  }

  // 모든 당첨 결과 로드
  Future<void> loadAllWinningResults() async {
    try {
      final results = await _drawService.getAllWinningResults();
      allWinningResults.assignAll(results);
    } catch (e) {
      print('당첨 결과 로드 오류: $e');
    }
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

    _addEmptyTicket();
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
