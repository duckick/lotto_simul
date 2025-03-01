import 'package:flutter/foundation.dart';

class LottoTicket {
  final int round;
  final DateTime issueDate;
  final DateTime drawDate;
  final List<LottoRow> lottoRows;
  final int amount;

  LottoTicket({
    required this.round,
    required this.issueDate,
    required this.drawDate,
    required this.lottoRows,
    required this.amount,
  });

  LottoTicket copyWith({
    int? round,
    DateTime? issueDate,
    DateTime? drawDate,
    List<LottoRow>? lottoRows,
    int? amount,
  }) {
    return LottoTicket(
      round: round ?? this.round,
      issueDate: issueDate ?? this.issueDate,
      drawDate: drawDate ?? this.drawDate,
      lottoRows: lottoRows ?? this.lottoRows,
      amount: amount ?? this.amount,
    );
  }
}

class LottoRow {
  final String rowName;
  final List<int> numbers;
  final bool isAuto;

  LottoRow({
    required this.rowName,
    required this.numbers,
    this.isAuto = false,
  });

  LottoRow copyWith({
    String? rowName,
    List<int>? numbers,
    bool? isAuto,
  }) {
    return LottoRow(
      rowName: rowName ?? this.rowName,
      numbers: numbers ?? this.numbers,
      isAuto: isAuto ?? this.isAuto,
    );
  }
}

class LottoResult {
  final int round;
  final DateTime drawDate;
  final List<int> winningNumbers;
  final int bonusNumber;

  LottoResult({
    required this.round,
    required this.drawDate,
    required this.winningNumbers,
    required this.bonusNumber,
  });
}
