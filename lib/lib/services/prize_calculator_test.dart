import 'dart:io';
import 'prize_calculator_service.dart';

void main() {
  final prizeCalculator = PrizeCalculatorService.instance;

  print('로또 당첨금 시뮬레이션');
  print('====================');

  for (int round = 1; round <= 5; round++) {
    print('\n회차: $round');

    // 당첨금 계산
    final prizes = prizeCalculator.calculatePrizes();

    // 당첨금 출력
    print('1등 당첨금: ${_formatCurrency(prizes[1])}원');
    print('2등 당첨금: ${_formatCurrency(prizes[2])}원');
    print('3등 당첨금: ${_formatCurrency(prizes[3])}원');
    print('4등 당첨금: ${_formatCurrency(prizes[4])}원');
    print('5등 당첨금: ${_formatCurrency(prizes[5])}원');

    // 다음 회차로 넘어가기 전에 잠시 대기
    if (round < 5) {
      print('\n다음 회차로 넘어가려면 Enter 키를 누르세요...');
      stdin.readLineSync();
    }
  }
}

// 숫자를 통화 형식으로 포맷팅 (1,000,000 -> 1,000,000)
String _formatCurrency(int? value) {
  if (value == null) return '0';

  final buffer = StringBuffer();
  final String numStr = value.toString();
  int count = 0;

  for (int i = numStr.length - 1; i >= 0; i--) {
    if (count > 0 && count % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(numStr[i]);
    count++;
  }

  return buffer.toString().split('').reversed.join();
}
