import 'dart:math';

class PrizeCalculatorService {
  static final PrizeCalculatorService _instance =
      PrizeCalculatorService._internal();
  static PrizeCalculatorService get instance => _instance;

  PrizeCalculatorService._internal();

  final _random = Random();

  // 당첨금 분배 비율 (% 단위) - 1등, 2등, 3등만 동적 계산
  static const Map<int, double> prizeDistributionRatio = {
    1: 0.50, // 1등: 총 당첨금의 50%
    2: 0.125, // 2등: 총 당첨금의 12.5%
    3: 0.125, // 3등: 총 당첨금의 12.5%
  };

  // 고정 당첨금 (4등, 5등)
  static const Map<int, int> fixedPrizes = {
    4: 50000, // 4등: 50,000원 (고정)
    5: 5000, // 5등: 5,000원 (고정)
  };

  // 회차별 당첨자 수 범위 (대략적인 실제 통계 기반)
  static const Map<int, List<int>> winnerCountRange = {
    1: [0, 20], // 1등 당첨자 수 범위: 0~20명
    2: [10, 80], // 2등 당첨자 수 범위: 10~80명
    3: [1000, 3000], // 3등 당첨자 수 범위: 1,000~3,000명
    4: [50000, 100000], // 4등 당첨자 수 범위: 50,000~100,000명
    5: [1000000, 2000000], // 5등 당첨자 수 범위: 1,000,000~2,000,000명
  };

  // 회차별 총 판매액 범위 (단위: 원)
  static const int minTotalSales = 80000000000; // 최소 800억원
  static const int maxTotalSales = 120000000000; // 최대 1200억원

  // 기본 로또 1장 가격 (단위: 원)
  static const int lottoTicketPrice = 1000; // 1,000원

  // 회차별 당첨금 계산
  Map<int, int> calculatePrizes() {
    // 1. 총 판매액 계산 (정규분포 사용)
    final totalSales = _generateTotalSales();

    // 2. 총 당첨금액 계산 (판매액의 약 50%가 당첨금으로 사용)
    final totalPrizePool = (totalSales * 0.5).round();

    // 3. 각 등수별 당첨자 수 계산
    final winnerCounts = _generateWinnerCounts();

    // 4. 각 등수별 당첨금 계산
    final Map<int, int> prizes = {};

    // 4등과 5등은 고정 금액 설정
    prizes[4] = fixedPrizes[4]!;
    prizes[5] = fixedPrizes[5]!;

    // 4등과 5등의 총 당첨금 계산
    final int totalFixedPrizes =
        (prizes[4]! * winnerCounts[4]!) + (prizes[5]! * winnerCounts[5]!);

    // 동적 당첨금 풀 (1-3등 배분 금액)
    final int dynamicPrizePool = totalPrizePool - totalFixedPrizes;

    // 1등, 2등, 3등 당첨금 계산
    for (int rank = 1; rank <= 3; rank++) {
      final double ratio = prizeDistributionRatio[rank]!;
      final int winnerCount = winnerCounts[rank]!;

      // 해당 등수의 총 당첨금액
      final double totalPrizeForRank = dynamicPrizePool * ratio;

      // 당첨자가 있는 경우에만 1인당 당첨금 계산
      if (winnerCount > 0) {
        final int prizePerPerson = (totalPrizeForRank / winnerCount).round();
        prizes[rank] = prizePerPerson;
      } else {
        // 당첨자가 없는 경우 다음 회차로 이월 (시뮬레이션에서는 단순히 금액만 표시)
        prizes[rank] = totalPrizeForRank.round();
      }
    }

    return prizes;
  }

  // 정규분포를 사용하여 총 판매액 생성
  int _generateTotalSales() {
    // Box-Muller 변환을 사용하여 정규분포 값 생성
    final u1 = _random.nextDouble();
    final u2 = _random.nextDouble();
    final z = sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);

    // 평균과 표준편차를 설정하여 정규분포를 적용
    final mean = (minTotalSales + maxTotalSales) / 2;
    final stdDev = (maxTotalSales - minTotalSales) / 6; // 6시그마 규칙 적용

    // 정규분포 값에 평균과 표준편차를 적용하여 총 판매액 계산
    int sales = (mean + z * stdDev).round();

    // 최소 및 최대 판매액 범위 내로 제한
    return sales.clamp(minTotalSales, maxTotalSales);
  }

  // 각 등수별 당첨자 수 생성
  Map<int, int> _generateWinnerCounts() {
    final Map<int, int> counts = {};

    for (int rank = 1; rank <= 5; rank++) {
      final List<int> range = winnerCountRange[rank]!;
      final int min = range[0];
      final int max = range[1];

      // 1등과 2등은 좀 더 현실적인 분포를 위해 정규분포 사용
      if (rank <= 2) {
        // Box-Muller 변환을 사용하여 정규분포 값 생성
        final u1 = _random.nextDouble();
        final u2 = _random.nextDouble();
        final z = sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);

        // 평균 및 표준편차 설정
        final mean = (min + max) / 2;
        final stdDev = (max - min) / 6; // 6시그마 규칙 적용

        // 정규분포 값 계산 및 범위 내로 제한
        int count = (mean + z * stdDev).round();
        counts[rank] = count.clamp(min, max);
      } else {
        // 3등 이하는 범위 내에서 균일하게 분포
        counts[rank] = min + _random.nextInt(max - min + 1);
      }
    }

    return counts;
  }
}
