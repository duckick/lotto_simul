import 'package:flutter/foundation.dart';
import 'dart:convert';

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

  // JSON 문자열에서 LottoTicket 객체 생성
  factory LottoTicket.fromJson(String jsonString) {
    final Map<String, dynamic> data = json.decode(jsonString);
    return LottoTicket(
      round: data['round'],
      issueDate: DateTime.parse(data['issueDate']),
      drawDate: DateTime.parse(data['drawDate']),
      amount: data['amount'],
      lottoRows: List<LottoRow>.from(
        data['lottoRows'].map((rowData) => LottoRow.fromMap(rowData)),
      ),
    );
  }

  // Map에서 LottoTicket 객체 생성
  factory LottoTicket.fromMap(Map<String, dynamic> data) {
    return LottoTicket(
      round: data['round'],
      issueDate: DateTime.parse(data['issueDate']),
      drawDate: DateTime.parse(data['drawDate']),
      amount: data['amount'],
      lottoRows: List<LottoRow>.from(
        data['lottoRows'].map((rowData) => LottoRow.fromMap(rowData)),
      ),
    );
  }

  // LottoTicket 객체를 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'round': round,
      'issueDate': issueDate.toIso8601String(),
      'drawDate': drawDate.toIso8601String(),
      'amount': amount,
      'lottoRows': lottoRows.map((row) => row.toMap()).toList(),
    };
  }

  // LottoTicket 객체를 JSON 문자열로 변환
  String toJson() => json.encode(toMap());
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

  // Map에서 LottoRow 객체 생성
  factory LottoRow.fromMap(Map<String, dynamic> data) {
    return LottoRow(
      rowName: data['rowName'],
      numbers: List<int>.from(data['numbers']),
      isAuto: data['isAuto'] ?? false,
    );
  }

  // LottoRow 객체를 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'rowName': rowName,
      'numbers': numbers,
      'isAuto': isAuto,
    };
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
