import 'dart:io';
import 'services/prize_calculator_service.dart';
import 'services/prize_info_service.dart';

void main() {
  final prizeCalculator = PrizeCalculatorService.instance;
  final prizeInfoService = PrizeInfoService.instance;

  print('===== 로또 당첨금 계산 데모 =====');
  print('');

  // 초기화
  prizeInfoService.initialize();

  while (true) {
    print('\n메뉴를 선택하세요:');
    print('1. 현재 회차 당첨금 정보 보기');
    print('2. 새 회차 당첨금 계산하기');
    print('3. 종료');

    stdout.write('선택 (1-3): ');
    final input = stdin.readLineSync() ?? '';

    switch (input) {
      case '1':
        _showCurrentPrizes(prizeInfoService);
        break;
      case '2':
        _calculateNewRound(prizeInfoService);
        break;
      case '3':
        print('\n프로그램을 종료합니다.');
        return;
      default:
        print('\n잘못된 선택입니다. 다시 시도하세요.');
    }
  }
}

// 현재 회차의 당첨금 정보 출력
void _showCurrentPrizes(PrizeInfoService prizeInfoService) {
  final prizes = prizeInfoService.getPrizes();

  print('\n===== 현재 회차 당첨금 정보 =====');

  // 1-3등은 동적 계산된 금액 출력
  for (int rank = 1; rank <= 3; rank++) {
    final prize = prizes[rank] ?? 0;
    print('$rank등 당첨금: ${PrizeInfoService.formatCurrency(prize)}원');
  }

  // 4등과 5등은 고정 금액 표시
  print('4등 당첨금: 50,000원');
  print('5등 당첨금: 5,000원');
}

// 새 회차 당첨금 계산
void _calculateNewRound(PrizeInfoService prizeInfoService) {
  print('\n새로운 회차의 당첨금을 계산합니다...');
  prizeInfoService.refreshPrizes();
  print('계산 완료!');

  // 새로 계산된 당첨금 정보 출력
  _showCurrentPrizes(prizeInfoService);
}
