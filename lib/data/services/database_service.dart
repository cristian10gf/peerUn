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
      version: 2,
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
        await db.execute('''
          CREATE TABLE teachers (
            id       INTEGER PRIMARY KEY AUTOINCREMENT,
            name     TEXT    NOT NULL,
            email    TEXT    NOT NULL UNIQUE,
            password TEXT    NOT NULL,
            initials TEXT    NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE teacher_sessions (
            id         INTEGER PRIMARY KEY,
            teacher_id INTEGER,
            FOREIGN KEY (teacher_id) REFERENCES teachers(id)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS teachers (
              id       INTEGER PRIMARY KEY AUTOINCREMENT,
              name     TEXT    NOT NULL,
              email    TEXT    NOT NULL UNIQUE,
              password TEXT    NOT NULL,
              initials TEXT    NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS teacher_sessions (
              id         INTEGER PRIMARY KEY,
              teacher_id INTEGER,
              FOREIGN KEY (teacher_id) REFERENCES teachers(id)
            )
          ''');
        }
      },
    );
  }
}
