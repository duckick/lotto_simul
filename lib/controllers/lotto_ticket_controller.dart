import 'package:get/get.dart';
import '../models/lotto_models.dart';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/lotto_draw_service.dart';
import '../services/prize_calculator_service.dart';
import 'dart:convert';

class LottoTicketController extends GetxController {
  final currentDate = DateTime.now().obs;
  final seedMoney = 1000000.obs;
  final dailyPurchaseLimit = 100000; // 하루 최대 구매 한도 (10만원)
  final tickets = <LottoTicket>[].obs;

  // 회차 관련 변수 추가
  final currentRound = 1.obs; // 현재 회차

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
  final _prizeCalculatorService = PrizeCalculatorService.instance;

  // 버튼 비활성화 상태 관리 변수
  final isButtonDisabled = false.obs;

  // 버튼 비활성화 처리 함수
  void _disableButtonTemporarily() {
    isButtonDisabled.value = true;
    Future.delayed(const Duration(milliseconds: 100), () {
      isButtonDisabled.value = false;
    });
  }

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

  // 현재 회차 문자열 반환 (예: "1회차")
  String getCurrentRoundString() {
    return "${currentRound.value}회차";
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
    // 버튼 비활성화 상태면 무시
    if (isButtonDisabled.value) return;

    // 버튼 일시 비활성화
    _disableButtonTemporarily();

    // 현재 날짜가 토요일인지 확인
    final isCurrentlySaturday = isCurrentDateDrawDay();

    // 이미 다이얼로그가 표시 중인지 확인
    final isDialogOpen = Get.isDialogOpen ?? false;

    // 디버깅 로그 추가
    print(
        'moveToNextDay 호출: 토요일=$isCurrentlySaturday, shouldShowResult=${shouldShowResult.value}, isDialogOpen=$isDialogOpen');

    // 토요일이면 추첨 결과를 확인하고 결과 다이얼로그를 표시
    if (isCurrentlySaturday && !isDialogOpen) {
      await checkDrawResults();
      // 결과 다이얼로그를 표시하고 닫기 버튼을 누르면 다음날로 이동
      _showResultDialogWithNextDay();
      return;
    }

    // 토요일이 아니면 바로 다음 날로 이동
    await actuallyMoveToNextDay();
  }

  // 실제로 다음 날로 이동하는 함수
  Future<void> actuallyMoveToNextDay() async {
    shouldShowResult.value = false; // 결과 팝업 표시 신호 초기화

    // 현재 티켓 수 저장
    final currentTicketCount = tickets.length;

    // 날짜 변경 - 딜레이 없이 즉시 변경
    currentDate.value = currentDate.value.add(const Duration(days: 1));

    // 토요일이 지난 후 일요일로 넘어갈 때 새로운 회차 시작
    if (currentDate.value.weekday == 7) {
      // 일요일
      currentRound.value += 1;
    }

    // 구매 완료 상태 초기화 (더 이상 사용하지 않지만 호환성을 위해 유지)
    purchaseCompleted.value = false;

    // 애니메이션 효과를 위한 지연 제거
    // await Future.delayed(const Duration(milliseconds: 50));

    // 티켓 목록 초기화하되, 같은 수의 빈 티켓 생성
    tickets.clear();

    // 이전과 동일한 수의 티켓 생성 (최소 1장)
    final ticketsToCreate = currentTicketCount > 0 ? currentTicketCount : 1;
    for (int i = 0; i < ticketsToCreate; i++) {
      _addEmptyTicket();
    }

    // 추첨일 여부 업데이트
    isDrawDay.value = isCurrentDateDrawDay();

    // 추첨일이 되었을 때만 초기화
    if (!isDrawDay.value) {
      // 추첨일이 아니면 당첨 결과 초기화
      winningResults.clear();
      drawNumbers.clear();
      bonusNumber.value = 0;
    }

    // 게임 상태 저장
    await _saveGameState();
  }

  // 이전 날로 이동
  Future<void> moveToPreviousDay() async {
    // 버튼 비활성화 상태면 무시
    if (isButtonDisabled.value) return;

    // 버튼 일시 비활성화
    _disableButtonTemporarily();

    // 현재 날짜가 일요일인지 확인
    final isCurrentlySunday = currentDate.value.weekday == 7;

    // 날짜 변경
    currentDate.value = currentDate.value.subtract(const Duration(days: 1));

    // 구매 완료 상태 초기화
    purchaseCompleted.value = false;

    // 애니메이션 효과를 위한 지연 제거
    // await Future.delayed(const Duration(milliseconds: 50));

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
  Future<void> checkDrawResults({List<LottoTicket>? includeTickets}) async {
    // 현재 날짜가 추첨일이 아니면 무시
    if (!isCurrentDateDrawDay()) return;

    try {
      // 디버그 로그 추가
      print('===========================================================');
      print('추첨 시작 - 회차: ${currentRound.value}, 날짜: ${currentDate.value}');
      if (includeTickets != null) {
        print('방금 구매한 티켓 포함: ${includeTickets.length}장');
        for (var ticket in includeTickets) {
          print(
              '티켓 회차: ${ticket.round}, 발행일: ${ticket.issueDate}, 추첨일: ${ticket.drawDate}');
        }
      }

      // 당첨 결과 초기화
      winningResults.clear();

      // 로또 번호 추첨 및 당첨 확인 서비스 호출 (현재 회차 정보 전달)
      final results = await _drawService.checkAllTicketsForDrawDate(
          currentDate.value,
          currentRound: currentRound.value,
          includeTickets: includeTickets);

      // 추첨 결과 업데이트 (당첨 정보 저장)
      final drawResult = await _drawService.drawLottoNumbers(currentDate.value);
      drawNumbers.assignAll(List<int>.from(drawResult['draw_numbers']));
      bonusNumber.value = drawResult['bonus_number'] as int;

      // 당첨된 티켓을 결과 배열에 추가
      if (results.isNotEmpty) {
        // 당첨 결과에 추가 정보 포함하여 저장
        for (var result in results) {
          final matchedNumbers = <int>[];
          for (var num in result['numbers']) {
            if (drawNumbers.contains(num)) {
              matchedNumbers.add(num);
            }
          }

          winningResults.add({
            'rank': result['rank'],
            'prize': result['prize'],
            'numbers': result['numbers'],
            'matched_numbers': matchedNumbers,
            'purchase_date': currentDate.value.toString(),
            'round': currentRound.value, // 회차 정보 추가
          });
        }

        // 당첨 금액 합산
        int totalWinnings = 0;
        for (var result in winningResults) {
          totalWinnings += result['prize'] as int;
        }

        // 잔액에 당첨금 추가
        seedMoney.value += totalWinnings;

        // 디버그 로그 추가
        print('당첨결과: ${winningResults.length}개, 총 당첨금: ${totalWinnings}원');
      } else {
        print('당첨된 티켓이 없습니다.');
      }
      print('===========================================================');

      // 결과 팝업 표시
      shouldShowResult.value = true;
    } catch (e) {
      print('당첨 번호 확인 오류: $e');
    }
  }

  // 빈 티켓 추가 (내부 메소드)
  void _addEmptyTicket() {
    tickets.add(LottoTicket(
      round: currentRound.value,
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
    // 버튼 비활성화 상태면 무시
    if (isButtonDisabled.value) return;

    // 버튼 일시 비활성화
    _disableButtonTemporarily();

    // 이미 구매 완료된 경우 (토요일이 아닌 경우에만 체크)
    if (purchaseCompleted.value && !isDrawDay.value) {
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

    // 하루 구매 한도 초과
    if (totalAmount > dailyPurchaseLimit) {
      Get.snackbar(
        '구매 한도 초과',
        '하루 최대 구매 한도는 10만원입니다.',
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

    // 현재 티켓의 복사본 보관 (추첨에 포함시키기 위함)
    final currentTickets = List<LottoTicket>.from(tickets);

    // 구매한 티켓 저장
    await _savePurchasedTickets();

    // 토요일인지 확인
    final isCurrentlySaturday = isCurrentDateDrawDay();

    // 토요일에 구매한 경우
    if (isCurrentlySaturday) {
      // 당첨 결과 확인 전에 현재 구매한 티켓을 메모리에 보관
      final purchasedTickets =
          currentTickets.where((ticket) => ticket.amount > 0).toList();

      // 당첨 결과 확인
      await checkDrawResults(includeTickets: purchasedTickets);

      // 결과 다이얼로그를 표시하고 닫기 버튼을 누르면 다음날로 이동
      _showResultDialogWithNextDay();
    } else {
      // 토요일이 아닌 경우 바로 다음 날로 이동
      await actuallyMoveToNextDay();
    }

    // 게임 상태 저장
    await _saveGameState();
  }

  // 결과 다이얼로그를 표시하고 닫기 버튼 누르면 다음날로 이동하는 함수
  void _showResultDialogWithNextDay() {
    // 이미 다이얼로그가 열려있는 경우 중복 표시 방지
    if (Get.isDialogOpen ?? false) {
      return;
    }

    Future.delayed(const Duration(milliseconds: 10), () async {
      // 한번 더 체크
      if (Get.isDialogOpen ?? false) {
        return;
      }

      // 이번 회차 구매한 티켓 수 조회
      final ticketCount = await getCurrentRoundTicketCount();

      // 당첨금 직접 계산
      final calculatedPrizes = _prizeCalculatorService.calculatePrizes();

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
          title: Row(
            children: [
              const Text('당첨 결과',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text(
                '${currentRound.value}회차',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints:
                BoxConstraints(maxHeight: Get.height * 0.7), // 다이얼로그 최대 높이 설정
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // 각 당첨 번호와 구매 날짜 표시
                            ...resultsForRank.map((result) {
                              final numbers = List<int>.from(result['numbers']);
                              final matchedNumbers = result
                                      .containsKey('matched_numbers')
                                  ? List<int>.from(result['matched_numbers'])
                                  : <int>[];

                              return Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 4.0, left: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text('${numbers.join(', ')}'),
                                        ),
                                      ],
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

                  // 이번 회차 구매한 티켓 수 표시
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      '이번 회차 구매한 로또: ${ticketCount}장',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                  // 이번 회차 당첨금액 정보 추가
                  const SizedBox(height: 20),
                  Text(
                    '1등: ₩${_formatCurrency(calculatedPrizes[1] ?? 0)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '2등: ₩${_formatCurrency(calculatedPrizes[2] ?? 0)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '3등: ₩${_formatCurrency(calculatedPrizes[3] ?? 0)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
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
                // 다이얼로그를 닫은 후 다음 날로 이동
                actuallyMoveToNextDay();
              },
              child: const Text('닫기'),
            ),
          ],
        ),
        barrierDismissible: false, // 바깥쪽 터치로 닫히지 않도록 설정
      );
    });
  }

  // 숫자를 통화 형식으로 포맷팅 (1000000 -> 1,000,000)
  String _formatCurrency(int value) {
    return value.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
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
      // 초기 회차 설정 (첫 실행 시 1회차로 시작)
      currentRound.value = 1;

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
        currentRound: currentRound.value, // 회차 정보 저장
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

        // 회차 정보 로드 (없으면 기본값 1)
        currentRound.value = state['current_round'] as int? ?? 1;
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

  // 이번 회차 구매한 티켓 수 조회 (일요일부터 토요일까지)
  Future<int> getCurrentRoundTicketCount() async {
    try {
      // 이번 회차 추첨일(토요일)
      final drawDate = currentDate.value;
      // 이번 회차 시작일(이전 일요일)
      final startDate = DateTime(
          drawDate.year, drawDate.month, drawDate.day - 6 // 일요일은 토요일로부터 6일 전
          );

      // 이번 회차에 해당하는 모든 티켓 조회 (일요일~토요일)
      final tickets = await _dbService.getAllTicketsForDrawDate(drawDate,
          currentRound: currentRound.value);

      // 이전 주 일요일에 구매한 티켓도 조회 (이번 회차에 포함)
      final sundayTickets = await _dbService.getTicketsOnDate(startDate);

      // 일요일 티켓 중 현재 회차에 해당하는 티켓만 필터링
      final validSundayTickets = <Map<String, dynamic>>[];
      for (var ticket in sundayTickets) {
        try {
          final ticketData = jsonDecode(ticket['ticket_data'] as String);
          final ticketRound = ticketData['round'] as int;
          if (ticketRound == currentRound.value) {
            validSundayTickets.add(ticket);
          }
        } catch (e) {
          print('티켓 데이터 파싱 오류: $e');
        }
      }

      return tickets.length + validSundayTickets.length;
    } catch (e) {
      print('회차 티켓 수 조회 오류: $e');
      return 0;
    }
  }

  // 게임 상태 초기화 (전체 리셋)
  Future<void> resetAllGameData() async {
    try {
      // 데이터베이스 초기화
      await _dbService.resetAllData();

      // 메모리 변수 초기화
      currentDate.value = DateTime.now();
      seedMoney.value = 1000000;
      tickets.clear();
      addNewTicket(); // 기본 티켓 하나 추가

      // 당첨 결과 관련 변수 초기화
      winningResults.clear();
      allWinningResults.clear();
      isDrawDay.value = isCurrentDateDrawDay();
      drawNumbers.clear();
      bonusNumber.value = 0;
      totalSpent.value = 0;

      // 회차 초기화
      currentRound.value = 1;

      // 구매 완료 상태 초기화
      purchaseCompleted.value = false;

      // 게임 상태 저장
      await _saveGameState();

      print('모든 게임 데이터가 초기화되었습니다.');
    } catch (e) {
      print('게임 데이터 초기화 오류: $e');
    }
  }
}
