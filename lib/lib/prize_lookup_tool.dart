import 'dart:io';
import 'services/lotto_draw_service.dart';
import 'services/prize_info_service.dart';

/// 특정 날짜의 로또 당첨금을 조회하는 도구
/// 사용자가 원하는 날짜의 로또 추첨 결과와 당첨금을 조회할 수 있습니다.
void main() async {
  print('===== 로또 당첨금 조회 도구 =====');
  print('특정 날짜의 로또 추첨 결과와 당첨금을 조회할 수 있습니다.');

  final lottoDrawService = LottoDrawService.instance;

  while (true) {
    print('\n1. 특정 날짜 당첨금 조회');
    print('2. 오늘 추첨 결과 시뮬레이션');
    print('3. 종료');

    stdout.write('\n선택하세요 (1-3): ');
    final input = stdin.readLineSync() ?? '';

    switch (input) {
      case '1':
        await _lookupSpecificDate(lottoDrawService);
        break;
      case '2':
        await _simulateTodayDraw(lottoDrawService);
        break;
      case '3':
        print('\n프로그램을 종료합니다.');
        return;
      default:
        print('\n잘못된 선택입니다. 다시 시도하세요.');
    }
  }
}

/// 특정 날짜의 당첨금 조회
Future<void> _lookupSpecificDate(LottoDrawService lottoDrawService) async {
  try {
    final now = DateTime.now();
    int year, month, day;

    stdout.write('\n조회할 연도 (예: ${now.year}): ');
    year = int.parse(stdin.readLineSync() ?? '${now.year}');

    stdout.write('조회할 월 (1-12): ');
    month = int.parse(stdin.readLineSync() ?? '${now.month}');

    stdout.write('조회할 일 (1-31): ');
    day = int.parse(stdin.readLineSync() ?? '${now.day}');

    // 입력 유효성 검사
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      print('\n유효하지 않은 날짜입니다.');
      return;
    }

    final date = DateTime(year, month, day, 20, 0, 0);
    print('\n${_formatDate(date)} 추첨 결과를 조회합니다...');

    // 해당 날짜의 로또 번호 및 당첨금 조회/생성
    await lottoDrawService.drawLottoNumbers(date);
  } catch (e) {
    print('\n오류가 발생했습니다: $e');
  }
}

/// 오늘의 추첨 결과 시뮬레이션
Future<void> _simulateTodayDraw(LottoDrawService lottoDrawService) async {
  final today = DateTime.now();
  final drawTime = DateTime(today.year, today.month, today.day, 20, 0, 0);

  print('\n${_formatDate(drawTime)} 오늘의 추첨 결과 시뮬레이션:');

  // 오늘 날짜의 로또 번호 및 당첨금 조회/생성
  await lottoDrawService.drawLottoNumbers(drawTime);
}

/// 날짜 형식화 (YYYY년 MM월 DD일)
String _formatDate(DateTime date) {
  return '${date.year}년 ${date.month}월 ${date.day}일';
}
