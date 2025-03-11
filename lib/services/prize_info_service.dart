import 'dart:async';
import 'prize_calculator_service.dart';

class PrizeInfoService {
  static final PrizeInfoService _instance = PrizeInfoService._internal();
  static PrizeInfoService get instance => _instance;

  PrizeInfoService._internal();

  final _prizeCalculator = PrizeCalculatorService.instance;

  // 현재 회차의 당첨금 정보
  Map<int, int>? _currentPrizes;

  // 스트림 컨트롤러 (당첨금 정보가 변경될 때마다 알림)
  final _prizeStreamController = StreamController<Map<int, int>>.broadcast();

  // 당첨금 정보 스트림 (UI에서 구독 가능)
  Stream<Map<int, int>> get prizeStream => _prizeStreamController.stream;

  // 당첨금 정보 초기화
  void initialize() {
    _calculateNewPrizes();
  }

  // 최신 당첨금 정보 가져오기
  Map<int, int> getPrizes() {
    if (_currentPrizes == null) {
      _calculateNewPrizes();
    }
    return _currentPrizes!;
  }

  // 특정 등수의 당첨금 가져오기
  int getPrizeForRank(int rank) {
    if (_currentPrizes == null) {
      _calculateNewPrizes();
    }
    return _currentPrizes![rank] ?? 0;
  }

  // 새로운 회차의 당첨금 계산
  void _calculateNewPrizes() {
    _currentPrizes = _prizeCalculator.calculatePrizes();
    _prizeStreamController.add(_currentPrizes!);
  }

  // 새 회차로 갱신
  void refreshPrizes() {
    _calculateNewPrizes();
  }

  // 서비스 종료 시 리소스 해제
  void dispose() {
    _prizeStreamController.close();
  }

  // 당첨금 형식화 (숫자 -> 1,000,000 형식)
  static String formatCurrency(int value) {
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
}
