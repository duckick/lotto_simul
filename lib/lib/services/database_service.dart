import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/lotto_models.dart';
import 'dart:convert';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;

  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'lotto_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // 구매한 로또 티켓 테이블
    await db.execute('''
      CREATE TABLE purchased_tickets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_date TEXT,
        ticket_data TEXT,
        is_checked INTEGER DEFAULT 0
      )
    ''');

    // 추첨 결과 테이블
    await db.execute('''
      CREATE TABLE draw_results(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        draw_date TEXT,
        draw_numbers TEXT,
        bonus_number INTEGER
      )
    ''');
  }

  // 로또 티켓 저장
  Future<int> savePurchasedTicket(
      DateTime purchaseDate, LottoTicket ticket) async {
    final db = await database;

    // LottoTicket 객체를 JSON으로 변환
    final ticketJson = jsonEncode({
      'round': ticket.round,
      'issueDate': ticket.issueDate.toIso8601String(),
      'drawDate': ticket.drawDate.toIso8601String(),
      'amount': ticket.amount,
      'lottoRows': ticket.lottoRows
          .map((row) => {
                'rowName': row.rowName,
                'numbers': row.numbers,
                'isAuto': row.isAuto,
              })
          .toList(),
    });

    return await db.insert(
      'purchased_tickets',
      {
        'purchase_date': purchaseDate.toIso8601String(),
        'ticket_data': ticketJson,
        'is_checked': 0,
      },
    );
  }

  // 특정 날짜에 구매한 모든 티켓 조회
  Future<List<LottoTicket>> getPurchasedTickets(DateTime date) async {
    final db = await database;

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final List<Map<String, dynamic>> maps = await db.query(
      'purchased_tickets',
      where: 'purchase_date BETWEEN ? AND ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );

    return List.generate(maps.length, (i) {
      final ticketData = jsonDecode(maps[i]['ticket_data']);

      return LottoTicket(
        round: ticketData['round'],
        issueDate: DateTime.parse(ticketData['issueDate']),
        drawDate: DateTime.parse(ticketData['drawDate']),
        amount: ticketData['amount'],
        lottoRows: List<LottoRow>.from(
          ticketData['lottoRows'].map((row) => LottoRow(
                rowName: row['rowName'],
                numbers: List<int>.from(row['numbers']),
                isAuto: row['isAuto'] ?? false,
              )),
        ),
      );
    });
  }

  // 추첨 결과 저장
  Future<int> saveDrawResult(
      DateTime drawDate, List<int> numbers, int bonusNumber) async {
    final db = await database;

    return await db.insert(
      'draw_results',
      {
        'draw_date': drawDate.toIso8601String(),
        'draw_numbers': jsonEncode(numbers),
        'bonus_number': bonusNumber,
      },
    );
  }

  // 특정 날짜의 추첨 결과 조회
  Future<Map<String, dynamic>?> getDrawResult(DateTime drawDate) async {
    final db = await database;

    final startOfDay = DateTime(drawDate.year, drawDate.month, drawDate.day);
    final endOfDay =
        DateTime(drawDate.year, drawDate.month, drawDate.day, 23, 59, 59);

    final List<Map<String, dynamic>> maps = await db.query(
      'draw_results',
      where: 'draw_date BETWEEN ? AND ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );

    if (maps.isEmpty) {
      return null;
    }

    return {
      'draw_date': DateTime.parse(maps[0]['draw_date']),
      'draw_numbers': jsonDecode(maps[0]['draw_numbers']),
      'bonus_number': maps[0]['bonus_number'],
    };
  }

  // 아직 확인하지 않은 티켓 중 특정 추첨일에 해당하는 티켓 조회
  Future<List<Map<String, dynamic>>> getUncheckedTicketsForDrawDate(
      DateTime drawDate) async {
    final db = await database;

    // 먼저 확인하지 않은 모든 티켓을 가져옵니다
    final List<Map<String, dynamic>> maps = await db.query(
      'purchased_tickets',
      where: 'is_checked = 0',
    );

    // Dart에서 추첨일이 일치하는 티켓만 필터링합니다
    final targetDrawDateStr = drawDate.toIso8601String();
    final filteredMaps = maps.where((ticketMap) {
      try {
        final ticketData = jsonDecode(ticketMap['ticket_data'] as String);
        final ticketDrawDate = ticketData['drawDate'] as String;
        // 날짜가 동일한 날인지 확인 (시간은 무시하고 날짜만 비교)
        return ticketDrawDate.split('T')[0] == targetDrawDateStr.split('T')[0];
      } catch (e) {
        print('티켓 데이터 파싱 오류: $e');
        return false;
      }
    }).toList();

    return filteredMaps;
  }

  // 티켓 확인 상태 업데이트
  Future<int> updateTicketCheckedStatus(int ticketId, bool isChecked) async {
    final db = await database;

    return await db.update(
      'purchased_tickets',
      {'is_checked': isChecked ? 1 : 0},
      where: 'id = ?',
      whereArgs: [ticketId],
    );
  }

  // 모든 추첨 결과 조회
  Future<List<Map<String, dynamic>>> getAllDrawResults() async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query('draw_results');

    return List.generate(maps.length, (i) {
      return {
        'draw_date': DateTime.parse(maps[i]['draw_date']),
        'draw_numbers': jsonDecode(maps[i]['draw_numbers']),
        'bonus_number': maps[i]['bonus_number'],
      };
    });
  }

  // 특정 추첨일에 해당하는 모든 티켓 조회 (확인 여부 상관없이)
  Future<List<Map<String, dynamic>>> getAllTicketsForDrawDate(
      DateTime drawDate) async {
    final db = await database;

    // 모든 티켓을 가져옵니다
    final List<Map<String, dynamic>> maps = await db.query('purchased_tickets');

    // Dart에서 추첨일이 일치하는 티켓만 필터링합니다
    final targetDrawDateStr = drawDate.toIso8601String();
    final filteredMaps = maps.where((ticketMap) {
      try {
        final ticketData = jsonDecode(ticketMap['ticket_data'] as String);
        final ticketDrawDate = ticketData['drawDate'] as String;
        // 날짜가 동일한 날인지 확인 (시간은 무시하고 날짜만 비교)
        return ticketDrawDate.split('T')[0] == targetDrawDateStr.split('T')[0];
      } catch (e) {
        print('티켓 데이터 파싱 오류: $e');
        return false;
      }
    }).toList();

    return filteredMaps;
  }
}
