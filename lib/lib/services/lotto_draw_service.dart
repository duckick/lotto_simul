import 'dart:math';
import '../models/lotto_models.dart';
import 'database_service.dart';

class LottoDrawService {
  static final LottoDrawService _instance = LottoDrawService._internal();
  static LottoDrawService get instance => _instance;

  LottoDrawService._internal();

  final _random = Random();
  final _dbService = DatabaseService.instance;

  // 로또 번호 추첨 (6개 번호 + 보너스 번호 1개)
  Future<Map<String, dynamic>> drawLottoNumbers(DateTime drawDate) async {
    // 이미 추첨된 결과가 있는지 확인
    final existingResult = await _dbService.getDrawResult(drawDate);
    if (existingResult != null) {
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

    // 추첨 결과 저장
    await _dbService.saveDrawResult(drawDate, selectedNumbers, bonusNumber);

    return {
      'draw_date': drawDate,
      'draw_numbers': selectedNumbers,
      'bonus_number': bonusNumber,
    };
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

  // 당첨금 계산 (실제 로또 당첨금은 회차마다 다르지만, 시뮬레이션을 위한 고정 금액)
  int _getPrizeAmount(int rank) {
    switch (rank) {
      case 1:
        return 2000000000; // 20억원
      case 2:
        return 100000000; // 1억원
      case 3:
        return 1500000; // 150만원
      case 4:
        return 50000; // 5만원
      case 5:
        return 5000; // 5천원
      default:
        return 0;
    }
  }
}
