import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  // ================= DATABASE GETTER =================
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // ================= INIT DATABASE =================
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'result_vault.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // ================= CREATE TABLES =================
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        semester INTEGER UNIQUE,
        pdf_path TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE backlogs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        semester INTEGER,
        pdf_path TEXT
      )
    ''');
  }

  // ================= RESULT =================
  Future<void> saveResult(int semester, String path) async {
    final db = await database;
    await db.insert(
      'results',
      {
        'semester': semester,
        'pdf_path': path,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getResult(int semester) async {
    final db = await database;
    final res = await db.query(
      'results',
      where: 'semester = ?',
      whereArgs: [semester],
    );

    if (res.isNotEmpty) {
      return res.first['pdf_path'] as String;
    }
    return null;
  }

  Future<void> deleteResult(int semester) async {
    final db = await database;
    await db.delete(
      'results',
      where: 'semester = ?',
      whereArgs: [semester],
    );
  }

  Future<void> updateResultPath(int semester, String newPath) async {
    final db = await database;
    await db.update(
      'results',
      {'pdf_path': newPath},
      where: 'semester = ?',
      whereArgs: [semester],
    );
  }

  // ================= BACKLOG =================
  Future<void> addBacklog(int semester, String path) async {
    final db = await database;
    await db.insert(
      'backlogs',
      {
        'semester': semester,
        'pdf_path': path,
      },
    );
  }

  Future<List<String>> getBacklogs(int semester) async {
    final db = await database;
    final res = await db.query(
      'backlogs',
      where: 'semester = ?',
      whereArgs: [semester],
    );

    return res.map((e) => e['pdf_path'] as String).toList();
  }

  Future<void> deleteBacklog(String path) async {
    final db = await database;
    await db.delete(
      'backlogs',
      where: 'pdf_path = ?',
      whereArgs: [path],
    );
  }

  Future<void> updateBacklogPath(
      String oldPath, String newPath) async {
    final db = await database;
    await db.update(
      'backlogs',
      {'pdf_path': newPath},
      where: 'pdf_path = ?',
      whereArgs: [oldPath],
    );
  }
}
