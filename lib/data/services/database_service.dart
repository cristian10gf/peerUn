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
      version: 3,
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
        await _createGroupTables(db);
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
        if (oldVersion < 3) {
          await _createGroupTables(db);
        }
      },
    );
  }

  static Future<void> _createGroupTables(dynamic db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS group_categories (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT    NOT NULL,
        imported_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS groups (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        name        TEXT    NOT NULL,
        FOREIGN KEY (category_id) REFERENCES group_categories(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS group_members (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        name     TEXT    NOT NULL,
        username TEXT    NOT NULL,
        FOREIGN KEY (group_id) REFERENCES groups(id)
      )
    ''');
  }
}
