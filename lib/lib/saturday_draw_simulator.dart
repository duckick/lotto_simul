import 'dart:io';
import 'dart:async';
import 'services/lotto_draw_service.dart';
import 'services/prize_info_service.dart';

/// 토요일 로또 추첨 시뮬레이션 앱
/// 매 주 토요일 추첨 결과를 시뮬레이션하고 1등, 2등, 3등 당첨금을 로그로 출력합니다.
void main() async {
  print('===== 토요일 로또 추첨 시뮬레이터 =====');
  print('매 주 토요일 로또 추첨 결과와 당첨금을 시뮬레이션합니다.');
  print('아무 키나 누르면 다음 회차로 진행합니다. q를 누르면 종료합니다.');
  print('=========================================\n');

  final lottoDrawService = LottoDrawService.instance;
  final prizeInfoService = PrizeInfoService.instance;

  // 현재 날짜부터 시작
  DateTime currentDate = DateTime.now();

  // 가장 가까운 토요일로 설정
  currentDate = _getNextSaturday(currentDate);

  int roundNumber = 1;

  // 사용자 입력을 위한 컨트롤러
  StreamSubscription? subscription;
  bool running = true;

  subscription = stdin.listen((List<int> event) {
    String input = String.fromCharCodes(event).trim();
    if (input.toLowerCase() == 'q') {
      print('\n프로그램을 종료합니다.');
      running = false;
      subscription?.cancel();
      exit(0);
    }
  });

  while (running) {
    print('\n====== ${roundNumber}회차 추첨 ======');
    print('추첨일: ${_formatDate(currentDate)} (토요일)');

    // 로또 번호 추첨
    await lottoDrawService.drawLottoNumbers(currentDate);

    // 다음 추첨일 계산 (다음 토요일)
    currentDate = _getNextSaturday(currentDate.add(Duration(days: 1)));
    roundNumber++;

    // 사용자 입력 대기
    print('\n아무 키나 누르면 다음 회차로 진행합니다. (q: 종료)');
    stdin.readLineSync();
  }
}

/// 다음 토요일 날짜 계산
DateTime _getNextSaturday(DateTime date) {
  // 토요일은 dart에서 6 (월요일은 1, 일요일은 7)
  int daysUntilSaturday = DateTime.saturday - date.weekday;

  // 이미 토요일이면 다음 주 토요일로
  if (daysUntilSaturday <= 0) {
    daysUntilSaturday += 7;
  }

  return DateTime(date.year, date.month, date.day + daysUntilSaturday, 20, 0,
      0 // 토요일 저녁 8시(20:00)
      );
}

/// 날짜 형식화 (YYYY년 MM월 DD일)
String _formatDate(DateTime date) {
  return '${date.year}년 ${date.month}월 ${date.day}일';
}
