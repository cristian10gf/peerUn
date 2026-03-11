import 'package:sqflite/sqflite.dart';

class DatabaseService {
  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      '$dir/peereval.db',
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE students (
            id       INTEGER PRIMARY KEY AUTOINCREMENT,
            name     TEXT    NOT NULL,
            email    TEXT    NOT NULL UNIQUE,
            password TEXT    NOT NULL,
            initials TEXT    NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE sessions (
            id         INTEGER PRIMARY KEY,
            student_id INTEGER,
            FOREIGN KEY (student_id) REFERENCES students(id)
          )
        ''');
      },
    );
  }
}
