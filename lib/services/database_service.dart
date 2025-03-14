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
      onOpen: (db) async {
        // 데이터베이스가 열릴 때 게임 상태 테이블이 있는지 확인하고 없으면 생성
        await _ensureGameStateTableExists(db);
      },
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

    // 게임 상태 테이블
    await db.execute('''
      CREATE TABLE game_state(
        id INTEGER PRIMARY KEY CHECK (id = 1),
        current_date TEXT,
        seed_money INTEGER,
        tickets TEXT,
        is_draw_day INTEGER,
        draw_numbers TEXT,
        bonus_number INTEGER,
        total_spent INTEGER,
        current_round INTEGER DEFAULT 1,
        last_updated TEXT
      )
    ''');
  }

  // 게임 상태 테이블이 있는지 확인하고 없으면 생성
  Future<void> _ensureGameStateTableExists(Database db) async {
    try {
      // 테이블이 있는지 확인
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='game_state'");

      if (tables.isEmpty) {
        print('게임 상태 테이블이 없습니다. 새로 생성합니다.');
        // 게임 상태 테이블 생성
        await db.execute('''
          CREATE TABLE game_state(
            id INTEGER PRIMARY KEY CHECK (id = 1),
            current_date TEXT,
            seed_money INTEGER,
            tickets TEXT,
            is_draw_day INTEGER,
            draw_numbers TEXT,
            bonus_number INTEGER,
            total_spent INTEGER,
            current_round INTEGER DEFAULT 1,
            last_updated TEXT
          )
        ''');
        print('게임 상태 테이블이 생성되었습니다.');
      } else {
        // 테이블이 있지만 필요한 컬럼이 없는지 확인
        final columns = await db.rawQuery("PRAGMA table_info(game_state)");
        final hasTotalSpent =
            columns.any((column) => column['name'] == 'total_spent');
        final hasCurrentRound =
            columns.any((column) => column['name'] == 'current_round');

        if (!hasTotalSpent) {
          print('게임 상태 테이블에 total_spent 컬럼이 없습니다. 추가합니다.');
          await db.execute(
              'ALTER TABLE game_state ADD COLUMN total_spent INTEGER DEFAULT 0');
          print('total_spent 컬럼이 추가되었습니다.');
        }

        if (!hasCurrentRound) {
          print('게임 상태 테이블에 current_round 컬럼이 없습니다. 추가합니다.');
          await db.execute(
              'ALTER TABLE game_state ADD COLUMN current_round INTEGER DEFAULT 1');
          print('current_round 컬럼이 추가되었습니다.');
        }

        print('게임 상태 테이블이 이미 존재합니다.');
      }
    } catch (e) {
      print('게임 상태 테이블 확인/생성 오류: $e');
    }
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

  // 특정 날짜에 구매한 모든 티켓 맵 조회
  Future<List<Map<String, dynamic>>> getTicketsOnDate(DateTime date) async {
    final db = await database;

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    // 특정 날짜에 구매한 티켓 조회
    final List<Map<String, dynamic>> maps = await db.query(
      'purchased_tickets',
      where: 'purchase_date BETWEEN ? AND ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );

    return maps;
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

  // 모든 데이터 초기화
  Future<void> resetAllData() async {
    try {
      final db = await database;

      // 모든 테이블의 데이터 삭제
      await db.delete('purchased_tickets');
      await db.delete('draw_results');
      await db.delete('game_state');

      print('모든 데이터가 초기화되었습니다.');
    } catch (e) {
      print('데이터 초기화 오류: $e');
      throw e; // 오류를 상위로 전파하여 UI에서 처리할 수 있도록 함
    }
  }

  // 게임 상태 저장
  Future<void> saveGameState({
    required DateTime currentDate,
    required int seedMoney,
    required List<LottoTicket> tickets,
    required bool isDrawDay,
    required List<int> drawNumbers,
    required int bonusNumber,
    required int totalSpent,
    required int currentRound,
  }) async {
    final db = await database;

    // 티켓 데이터를 JSON으로 변환
    final ticketsJson = tickets.map((ticket) => ticket.toJson()).toList();

    final gameState = {
      'id': 1, // 항상 단일 레코드만 유지
      'current_date': currentDate.toIso8601String(),
      'seed_money': seedMoney,
      'tickets': jsonEncode(ticketsJson),
      'is_draw_day': isDrawDay ? 1 : 0,
      'draw_numbers': jsonEncode(drawNumbers),
      'bonus_number': bonusNumber,
      'total_spent': totalSpent,
      'current_round': currentRound,
      'last_updated': DateTime.now().toIso8601String(),
    };

    try {
      // 트랜잭션 사용으로 변경
      await db.transaction((txn) async {
        // 기존 레코드가 있는지 확인
        final List<Map<String, dynamic>> result = await txn.query(
          'game_state',
          where: 'id = 1',
        );

        if (result.isNotEmpty) {
          // 기존 레코드 업데이트
          await txn.update(
            'game_state',
            gameState,
            where: 'id = 1',
          );
          print('게임 상태 업데이트 완료');
        } else {
          // 새 레코드 삽입
          await txn.insert('game_state', gameState);
          print('게임 상태 새로 저장 완료');
        }
      });
    } catch (e) {
      print('게임 상태 저장 오류: $e');

      // 오류 발생 시 세부 정보 출력
      print(
          '저장 중인 데이터: currentDate=${currentDate.toIso8601String()}, seedMoney=$seedMoney, tickets 개수=${tickets.length}, currentRound=$currentRound');

      // 재시도 로직 - 오류가 발생해도 강제로 업데이트 시도
      try {
        print('재시도: 기존 데이터 삭제 후 저장 시도');
        await db.delete('game_state', where: 'id = 1');
        await db.insert('game_state', gameState);
        print('재시도 성공: 게임 상태 저장 완료');
      } catch (e2) {
        print('재시도 오류: $e2');
        throw e2;
      }
    }
  }

  // 게임 상태 로드
  Future<Map<String, dynamic>?> loadGameState() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> result = await db.query(
        'game_state',
        where: 'id = 1',
      );

      if (result.isNotEmpty) {
        final data = result.first;

        // 티켓 데이터 파싱
        final ticketsJson = jsonDecode(data['tickets'] as String) as List;
        final tickets =
            ticketsJson.map((json) => LottoTicket.fromJson(json)).toList();

        // 추첨 번호 파싱
        final drawNumbersJson =
            jsonDecode(data['draw_numbers'] as String) as List;
        final drawNumbers = drawNumbersJson.map((num) => num as int).toList();

        // total_spent 필드가 없는 경우 기본값 0 사용
        final totalSpent = data['total_spent'] ?? 0;

        // current_round 필드가 없는 경우 기본값 1 사용
        final currentRound = data['current_round'] ?? 1;

        return {
          'current_date': DateTime.parse(data['current_date'] as String),
          'seed_money': data['seed_money'] as int,
          'tickets': tickets,
          'is_draw_day': data['is_draw_day'] == 1,
          'draw_numbers': drawNumbers,
          'bonus_number': data['bonus_number'] as int,
          'total_spent': totalSpent,
          'current_round': currentRound,
          'last_updated': DateTime.parse(data['last_updated'] as String),
        };
      }

      return null; // 저장된 상태가 없음
    } catch (e) {
      print('게임 상태 로드 오류: $e');
      return null;
    }
  }

  // 게임 상태 존재 여부 확인
  Future<bool> hasGameState() async {
    try {
      final db = await database;
      final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM game_state WHERE id = 1'));
      return count != null && count > 0;
    } catch (e) {
      print('게임 상태 확인 오류: $e');
      return false;
    }
  }

  // 게임 상태 초기화
  Future<void> resetGameState() async {
    try {
      final db = await database;
      await db.delete('game_state');
      print('게임 상태가 초기화되었습니다.');
    } catch (e) {
      print('게임 상태 초기화 오류: $e');
      throw e;
    }
  }
}
