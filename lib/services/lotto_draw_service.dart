import 'dart:math';
import '../models/lotto_models.dart';
import 'database_service.dart';
import 'prize_calculator_service.dart';
import 'prize_info_service.dart';

class LottoDrawService {
  static final LottoDrawService _instance = LottoDrawService._internal();
  static LottoDrawService get instance => _instance;

  LottoDrawService._internal();

  final _random = Random();
  final _dbService = DatabaseService.instance;
  final _prizeCalculator = PrizeCalculatorService.instance;

  // 현재 회차의 당첨금 정보
  Map<int, int>? _currentRoundPrizes;

  // 로또 번호 추첨 (6개 번호 + 보너스 번호 1개)
  Future<Map<String, dynamic>> drawLottoNumbers(DateTime drawDate) async {
    // 이미 추첨된 결과가 있는지 확인
    final existingResult = await _dbService.getDrawResult(drawDate);
    if (existingResult != null) {
      // 이미 추첨된 결과가 있어도 당첨금 정보를 로그로 출력
      if (existingResult.containsKey('prizes')) {
        _currentRoundPrizes =
            Map<int, int>.from(existingResult['prizes'] as Map);
        _logPrizeAmounts(drawDate);
      }
      return existingResult;
    }

    // 1~45 사이의 번호 생성
    final numbers = List.generate(45, (index) => index + 1);
    numbers.shuffle(_random);

    // 6개 번호 선택 및 정렬
    final selectedNumbers = numbers.take(6).toList()..sort();

    // 보너스 번호 선택 (이미 선택된 6개 번호와 중복되지 않도록)
    int bonusNumber;
    do {
      bonusNumber = _random.nextInt(45) + 1;
    } while (selectedNumbers.contains(bonusNumber));

    // 새로운 회차마다 당첨금 다시 계산
    _currentRoundPrizes = _prizeCalculator.calculatePrizes();

    // 추첨 결과 및 당첨금 로그 출력
    _logPrizeAmounts(drawDate);

    // 추첨 결과 저장
    await _dbService.saveDrawResult(drawDate, selectedNumbers, bonusNumber);

    return {
      'draw_date': drawDate,
      'draw_numbers': selectedNumbers,
      'bonus_number': bonusNumber,
      'prizes': _currentRoundPrizes,
    };
  }

  // 당첨금 정보를 콘솔에 로그로 출력
  void _logPrizeAmounts(DateTime drawDate) {
    if (_currentRoundPrizes == null) return;

    final String dateStr =
        '${drawDate.year}년 ${drawDate.month}월 ${drawDate.day}일';
    print('\n========== 로또 추첨 결과 (${dateStr}) ==========');
    print(
        '1등 당첨금: ${PrizeInfoService.formatCurrency(_currentRoundPrizes![1] ?? 0)}원');
    print(
        '2등 당첨금: ${PrizeInfoService.formatCurrency(_currentRoundPrizes![2] ?? 0)}원');
    print(
        '3등 당첨금: ${PrizeInfoService.formatCurrency(_currentRoundPrizes![3] ?? 0)}원');
    print('4등 당첨금: 50,000원');
    print('5등 당첨금: 5,000원');
    print('=============================================\n');
  }

  // 당첨 등수 확인
  int checkWinningRank(
      List<int> ticketNumbers, List<int> drawNumbers, int bonusNumber) {
    // 일치하는 번호 개수 확인
    int matchCount = 0;
    for (var num in ticketNumbers) {
      if (num > 0 && drawNumbers.contains(num)) {
        matchCount++;
      }
    }

    // 당첨 등수 결정
    switch (matchCount) {
      case 6: // 1등: 6개 번호 일치
        return 1;
      case 5: // 2등: 5개 번호 + 보너스 번호 일치, 3등: 5개 번호 일치
        return ticketNumbers.contains(bonusNumber) ? 2 : 3;
      case 4: // 4등: 4개 번호 일치
        return 4;
      case 3: // 5등: 3개 번호 일치
        return 5;
      default: // 미당첨
        return 0;
    }
  }

  // 특정 추첨일에 해당하는 모든 티켓의 당첨 여부 확인
  Future<List<Map<String, dynamic>>> checkAllTicketsForDrawDate(
      DateTime drawDate) async {
    // 추첨 결과 가져오기 (없으면 새로 추첨)
    final drawResult = await drawLottoNumbers(drawDate);
    final drawNumbers = List<int>.from(drawResult['draw_numbers']);
    final bonusNumber = drawResult['bonus_number'] as int;

    // 당첨금 정보 업데이트
    if (drawResult.containsKey('prizes')) {
      _currentRoundPrizes = Map<int, int>.from(drawResult['prizes'] as Map);
    } else {
      // 기존 데이터에 당첨금 정보가 없는 경우 새로 계산
      _currentRoundPrizes = _prizeCalculator.calculatePrizes();
      // 당첨금 정보 로그 출력
      _logPrizeAmounts(drawDate);
    }

    // 해당 추첨일에 대한 미확인 티켓 가져오기
    final uncheckedTickets =
        await _dbService.getUncheckedTicketsForDrawDate(drawDate);

    final results = <Map<String, dynamic>>[];

    for (var ticketMap in uncheckedTickets) {
      final ticketId = ticketMap['id'] as int;
      final ticketData = ticketMap['ticket_data'];

      // 티켓 데이터 파싱
      final ticket = LottoTicket.fromJson(ticketData);

      // 각 로또 행에 대해 당첨 여부 확인
      for (var row in ticket.lottoRows) {
        // 선택된 번호가 있는 경우에만 확인
        if (row.numbers.any((num) => num > 0)) {
          final rank = checkWinningRank(row.numbers, drawNumbers, bonusNumber);

          if (rank > 0) {
            results.add({
              'ticket_id': ticketId,
              'row_name': row.rowName,
              'numbers': row.numbers,
              'rank': rank,
              'prize': _getPrizeAmount(rank),
            });
          }
        }
      }

      // 티켓을 확인했음으로 표시
      await _dbService.updateTicketCheckedStatus(ticketId, true);
    }

    return results;
  }

  // 모든 당첨 결과 가져오기
  Future<List<Map<String, dynamic>>> getAllWinningResults() async {
    try {
      // 데이터베이스에서 모든 당첨 결과를 가져오는 로직
      // 실제 구현에서는 데이터베이스에 당첨 결과를 저장하는 테이블이 필요합니다.
      // 현재는 임시로 빈 리스트를 반환합니다.

      // 모든 추첨 결과 가져오기
      final allDrawResults = await _dbService.getAllDrawResults();

      final allResults = <Map<String, dynamic>>[];

      // 각 추첨 결과에 대해 당첨된 티켓 확인
      for (var drawResult in allDrawResults) {
        final drawDate = drawResult['draw_date'] as DateTime;
        final drawNumbers = List<int>.from(drawResult['draw_numbers']);
        final bonusNumber = drawResult['bonus_number'] as int;

        // 현재 회차의 당첨금 정보 설정
        if (drawResult.containsKey('prizes')) {
          _currentRoundPrizes = Map<int, int>.from(drawResult['prizes'] as Map);
        } else {
          // 기존 데이터에 당첨금 정보가 없는 경우 새로 계산
          _currentRoundPrizes = _prizeCalculator.calculatePrizes();
          // 당첨금 정보 로그 출력
          _logPrizeAmounts(drawDate);
        }

        // 해당 추첨일에 대한 모든 티켓 가져오기 (이미 확인된 티켓 포함)
        final tickets = await _dbService.getAllTicketsForDrawDate(drawDate);

        for (var ticketMap in tickets) {
          final ticketId = ticketMap['id'] as int;
          final ticketData = ticketMap['ticket_data'];

          // 티켓 데이터 파싱
          final ticket = LottoTicket.fromJson(ticketData);

          // 각 로또 행에 대해 당첨 여부 확인
          for (var row in ticket.lottoRows) {
            // 선택된 번호가 있는 경우에만 확인
            if (row.numbers.any((num) => num > 0)) {
              final rank =
                  checkWinningRank(row.numbers, drawNumbers, bonusNumber);

              if (rank > 0) {
                allResults.add({
                  'ticket_id': ticketId,
                  'row_name': row.rowName,
                  'numbers': row.numbers,
                  'rank': rank,
                  'prize': _getPrizeAmount(rank),
                  'draw_date': drawDate,
                });
              }
            }
          }
        }
      }

      return allResults;
    } catch (e) {
      print('모든 당첨 결과 가져오기 오류: $e');
      return [];
    }
  }

  // 당첨금 계산 (동적 계산)
  int _getPrizeAmount(int rank) {
    // 회차별 당첨금 정보가 없는 경우 새로 계산
    if (_currentRoundPrizes == null) {
      _currentRoundPrizes = _prizeCalculator.calculatePrizes();
    }

    // 현재 회차의 당첨금 반환
    return _currentRoundPrizes![rank] ?? 0;
  }
}
