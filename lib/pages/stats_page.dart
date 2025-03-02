import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/lotto_ticket_controller.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LottoTicketController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('당첨 통계'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        // 당첨 통계 계산
        final stats = _calculateStats(
            controller.allWinningResults, controller.totalSpent.value);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 총 통계 요약
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '총 당첨 통계',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatRow('총 구매 금액',
                          '₩${NumberFormat('#,###').format(stats['totalSpent'])}'),
                      const SizedBox(height: 8),
                      _buildStatRow('총 당첨 금액',
                          '₩${NumberFormat('#,###').format(stats['totalWon'])}'),
                      const SizedBox(height: 8),
                      _buildStatRow(
                        '수익률',
                        '${(stats['totalSpent'] > 0 ? (stats['totalWon'] / stats['totalSpent'] * 100).toStringAsFixed(1) : '0.0')}%',
                        valueColor: stats['totalWon'] >= stats['totalSpent']
                            ? Colors.blue
                            : Colors.red,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 등수별 당첨 통계
              const Text(
                '등수별 당첨 횟수',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // 1등 ~ 5등 통계
              _buildRankCard(
                  1,
                  stats['rank1Count'],
                  '₩${NumberFormat('#,###').format(2000000000)}',
                  stats['rank1Total']),
              _buildRankCard(
                  2,
                  stats['rank2Count'],
                  '₩${NumberFormat('#,###').format(100000000)}',
                  stats['rank2Total']),
              _buildRankCard(
                  3,
                  stats['rank3Count'],
                  '₩${NumberFormat('#,###').format(1500000)}',
                  stats['rank3Total']),
              _buildRankCard(
                  4,
                  stats['rank4Count'],
                  '₩${NumberFormat('#,###').format(50000)}',
                  stats['rank4Total']),
              _buildRankCard(
                  5,
                  stats['rank5Count'],
                  '₩${NumberFormat('#,###').format(5000)}',
                  stats['rank5Total']),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildRankCard(
      int rank, int count, String prizePerWin, int totalPrize) {
    Color rankColor;
    switch (rank) {
      case 1:
        rankColor = Colors.red.shade700;
        break;
      case 2:
        rankColor = Colors.orange.shade700;
        break;
      case 3:
        rankColor = Colors.amber.shade700;
        break;
      case 4:
        rankColor = Colors.green.shade700;
        break;
      case 5:
        rankColor = Colors.blue.shade700;
        break;
      default:
        rankColor = Colors.grey.shade700;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: rankColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$rank등',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '당첨 횟수: $count회',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '1회 당첨금: $prizePerWin',
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '₩${NumberFormat('#,###').format(totalPrize)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _calculateStats(
      List<Map<String, dynamic>> allResults, int totalSpentAmount) {
    int totalWon = 0;
    int rank1Count = 0;
    int rank2Count = 0;
    int rank3Count = 0;
    int rank4Count = 0;
    int rank5Count = 0;

    for (var result in allResults) {
      final rank = result['rank'] as int;
      final prize = result['prize'] as int;

      totalWon += prize;

      switch (rank) {
        case 1:
          rank1Count++;
          break;
        case 2:
          rank2Count++;
          break;
        case 3:
          rank3Count++;
          break;
        case 4:
          rank4Count++;
          break;
        case 5:
          rank5Count++;
          break;
      }
    }

    return {
      'totalSpent': totalSpentAmount,
      'totalWon': totalWon,
      'rank1Count': rank1Count,
      'rank2Count': rank2Count,
      'rank3Count': rank3Count,
      'rank4Count': rank4Count,
      'rank5Count': rank5Count,
      'rank1Total': rank1Count * 2000000000,
      'rank2Total': rank2Count * 100000000,
      'rank3Total': rank3Count * 1500000,
      'rank4Total': rank4Count * 50000,
      'rank5Total': rank5Count * 5000,
    };
  }
}
