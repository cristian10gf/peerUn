import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:example/data/services/database_service.dart';
import 'package:example/domain/models/teacher.dart';
import 'package:example/domain/repositories/i_teacher_auth_repository.dart';

class TeacherAuthRepositoryImpl implements ITeacherAuthRepository {
  final DatabaseService _db;
  TeacherAuthRepositoryImpl(this._db);

  static String _buildInitials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static String _hash(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  Future<void> _saveSession(int teacherId) async {
    final db = await _db.database;
    await db.delete('teacher_sessions');
    await db.insert('teacher_sessions', {'id': 1, 'teacher_id': teacherId});
  }

  @override
  Future<Teacher?> login(String email, String password) async {
    final db = await _db.database;
    final rows = await db.query(
      'teachers',
      where: 'email = ? AND password = ?',
      whereArgs: [email.trim().toLowerCase(), _hash(password)],
    );
    if (rows.isEmpty) return null;
    await _saveSession(rows.first['id'] as int);
    return Teacher.fromMap(rows.first);
  }

  @override
  Future<Teacher> register(String name, String email, String password) async {
    final db = await _db.database;
    final initials = _buildInitials(name);
    final id = await db.insert('teachers', {
      'name':     name.trim(),
      'email':    email.trim().toLowerCase(),
      'password': _hash(password),
      'initials': initials,
    });
    await _saveSession(id);
    return Teacher(
      id:       id.toString(),
      name:     name.trim(),
      email:    email.trim().toLowerCase(),
      initials: initials,
    );
  }

  @override
  Future<void> logout() async {
    final db = await _db.database;
    await db.delete('teacher_sessions');
  }

  @override
  Future<Teacher?> getCurrentSession() async {
    final db = await _db.database;
    final sessions = await db.query('teacher_sessions', where: 'id = 1');
    if (sessions.isEmpty) return null;
    final tid = sessions.first['teacher_id'];
    final rows =
        await db.query('teachers', where: 'id = ?', whereArgs: [tid]);
    if (rows.isEmpty) return null;
    return Teacher.fromMap(rows.first);
  }
}
