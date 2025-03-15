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
      DateTime drawDate,
      {int? currentRound,
      List<LottoTicket>? includeTickets}) async {
    // 디버그 로그 추가
    print(
        'LottoDrawService::checkAllTicketsForDrawDate - 날짜: $drawDate, 회차: $currentRound');

    final drawResult = await drawLottoNumbers(drawDate);
    final drawNumbers = List<int>.from(drawResult['draw_numbers']);
    final bonusNumber = drawResult['bonus_number'] as int;

    print('추첨 번호: $drawNumbers, 보너스: $bonusNumber');

    // 당첨금 정보 업데이트
    if (drawResult.containsKey('prizes')) {
      _currentRoundPrizes = Map<int, int>.from(drawResult['prizes'] as Map);
    } else {
      // 기존 데이터에 당첨금 정보가 없는 경우 새로 계산
      _currentRoundPrizes = _prizeCalculator.calculatePrizes();
      // 당첨금 정보 로그 출력
      _logPrizeAmounts(drawDate);
    }

    // 해당 추첨일과 회차에 대한 미확인 티켓 가져오기
    final uncheckedTickets = await _dbService
        .getUncheckedTicketsForDrawDate(drawDate, currentRound: currentRound);

    print('DB에서 미확인 티켓 조회: ${uncheckedTickets.length}장');

    final results = <Map<String, dynamic>>[];

    // 이미 처리한 티켓 ID를 추적하기 위한 Set
    final processedTicketIds = <int>{};

    // 데이터베이스에서 가져온 티켓 처리
    for (var ticketMap in uncheckedTickets) {
      final ticketId = ticketMap['id'] as int;

      // 이미 처리한 티켓은 건너뜀
      if (processedTicketIds.contains(ticketId)) {
        print('이미 처리된 티켓 ID: $ticketId - 건너뜀');
        continue;
      }

      final ticketData = ticketMap['ticket_data'];

      // 티켓 데이터 파싱
      final ticket = LottoTicket.fromJson(ticketData);

      print(
          '티켓 확인 (DB) - ID: $ticketId, 회차: ${ticket.round}, 추첨일: ${ticket.drawDate}');

      // 회차 확인 - 현재 회차와 일치하는지 확인
      if (currentRound != null && ticket.round != currentRound) {
        print('회차 불일치: 티켓 회차 ${ticket.round}, 현재 회차 $currentRound - 건너뜀');
        continue;
      }

      // 각 로또 행에 대해 당첨 여부 확인
      for (var row in ticket.lottoRows) {
        // 선택된 번호가 있는 경우에만 확인
        if (row.numbers.any((num) => num > 0)) {
          final rank = checkWinningRank(row.numbers, drawNumbers, bonusNumber);

          if (rank > 0) {
            print('당첨! 행: ${row.rowName}, 번호: ${row.numbers}, 등수: $rank');
            results.add({
              'ticket_id': ticketId,
              'row_name': row.rowName,
              'numbers': row.numbers,
              'rank': rank,
              'prize': _getPrizeAmount(rank),
              'round': ticket.round, // 회차 정보 추가
            });
          }
        }
      }

      // 티켓을 확인했음으로 표시
      await _dbService.updateTicketCheckedStatus(ticketId, true);

      // 처리한 티켓 ID 추가
      processedTicketIds.add(ticketId);
    }

    // 메모리에서 방금 구매한 티켓도 당첨 확인에 포함
    if (includeTickets != null && includeTickets.isNotEmpty) {
      print('방금 구매한 티켓 포함: ${includeTickets.length}장');

      for (var ticket in includeTickets) {
        print('티켓 확인 (메모리) - 회차: ${ticket.round}, 추첨일: ${ticket.drawDate}');

        // 회차 확인 - 현재 회차와 일치하는지 확인
        if (currentRound != null && ticket.round != currentRound) {
          print('회차 불일치: 티켓 회차 ${ticket.round}, 현재 회차 $currentRound - 건너뜀');
          continue;
        }

        // 각 로또 행에 대해 당첨 여부 확인
        for (var row in ticket.lottoRows) {
          // 선택된 번호가 있는 경우에만 확인
          if (row.numbers.any((num) => num > 0)) {
            final rank =
                checkWinningRank(row.numbers, drawNumbers, bonusNumber);

            if (rank > 0) {
              print('당첨! 행: ${row.rowName}, 번호: ${row.numbers}, 등수: $rank');
              results.add({
                'ticket_id': -1, // 메모리에 있는 티켓이므로 임시 ID
                'row_name': row.rowName,
                'numbers': row.numbers,
                'rank': rank,
                'prize': _getPrizeAmount(rank),
                'round': ticket.round, // 회차 정보 추가
              });
            }
          }
        }
      }
    }

    print('최종 당첨 결과: ${results.length}개');

    return results;
  }

  // 모든 당첨 결과 가져오기
  Future<List<Map<String, dynamic>>> getAllWinningResults() async {
    try {
      // 모든 추첨 결과 가져오기
      final allDrawResults = await _dbService.getAllDrawResults();
      final allResults = <Map<String, dynamic>>[];

      // 이미 처리한 티켓 ID와 행 이름 조합을 추적하기 위한 Set
      final processedKeys = <String>{};

      print('==== 모든 당첨 결과 조회 시작 ====');
      print('추첨 결과 수: ${allDrawResults.length}');

      // 각 추첨 결과에 대해 당첨된 티켓 확인
      for (var drawResult in allDrawResults) {
        final drawDate = drawResult['draw_date'] as DateTime;
        final drawNumbers = List<int>.from(drawResult['draw_numbers']);
        final bonusNumber = drawResult['bonus_number'] as int;

        print('추첨일: $drawDate, 번호: $drawNumbers, 보너스: $bonusNumber');

        // 현재 회차의 당첨금 정보 설정
        if (drawResult.containsKey('prizes')) {
          _currentRoundPrizes = Map<int, int>.from(drawResult['prizes'] as Map);
        } else {
          // 기존 데이터에 당첨금 정보가 없는 경우 새로 계산
          _currentRoundPrizes = _prizeCalculator.calculatePrizes();
        }

        // 이 추첨일에 해당하는 모든 티켓 조회 (확인 여부 상관없이)
        final tickets = await _dbService.getAllTicketsForDrawDate(drawDate);
        print('추첨일 ${drawDate}에 대한 티켓 수: ${tickets.length}');

        // 각 티켓에 대해 당첨 여부 확인
        for (var ticketMap in tickets) {
          final ticketId = ticketMap['id'] as int;
          final ticketData = ticketMap['ticket_data'];

          // 티켓 데이터 파싱
          final ticket = LottoTicket.fromJson(ticketData);

          // 각 로또 행에 대해 당첨 여부 확인
          for (var row in ticket.lottoRows) {
            // 선택된 번호가 있는 경우에만 확인
            if (row.numbers.any((num) => num > 0)) {
              // 중복 확인을 위한 키 생성
              final key = '$ticketId-${row.rowName}';

              // 이미 처리한 티켓+행 조합이면 건너뜀
              if (processedKeys.contains(key)) {
                print('중복 티켓 건너뜀: $key');
                continue;
              }

              final rank =
                  checkWinningRank(row.numbers, drawNumbers, bonusNumber);

              if (rank > 0) {
                print('당첨 발견: 티켓 ID $ticketId, 행 ${row.rowName}, 등수 $rank');
                allResults.add({
                  'ticket_id': ticketId,
                  'row_name': row.rowName,
                  'numbers': row.numbers,
                  'rank': rank,
                  'prize': _getPrizeAmount(rank),
                  'draw_date': drawDate,
                  'round': ticket.round,
                });

                // 처리한 티켓+행 조합 기록
                processedKeys.add(key);
              }
            }
          }
        }
      }

      print('총 당첨 결과: ${allResults.length}개');
      print('==== 모든 당첨 결과 조회 완료 ====');

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
