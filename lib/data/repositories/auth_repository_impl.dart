import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:example/data/services/database_service.dart';
import 'package:example/domain/models/student.dart';
import 'package:example/domain/repositories/i_auth_repository.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final DatabaseService _db;
  AuthRepositoryImpl(this._db);

  static String _buildInitials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static String _hash(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  Future<void> _saveSession(int studentId) async {
    final db = await _db.database;
    await db.delete('sessions');
    await db.insert('sessions', {'id': 1, 'student_id': studentId});
  }

  @override
  Future<Student?> login(String email, String password) async {
    final db = await _db.database;
    final rows = await db.query(
      'students',
      where: 'email = ? AND password = ?',
      whereArgs: [email.trim().toLowerCase(), _hash(password)],
    );
    if (rows.isEmpty) return null;
    await _saveSession(rows.first['id'] as int);
    return Student.fromMap(rows.first);
  }

  @override
  Future<Student> register(String name, String email, String password) async {
    final db = await _db.database;
    final initials = _buildInitials(name);
    final id = await db.insert('students', {
      'name':     name.trim(),
      'email':    email.trim().toLowerCase(),
      'password': _hash(password),
      'initials': initials,
    });
    await _saveSession(id);
    return Student(
      id: id.toString(),
      name: name.trim(),
      email: email.trim().toLowerCase(),
      initials: initials,
    );
  }

  @override
  Future<void> logout() async {
    final db = await _db.database;
    await db.delete('sessions');
  }

  @override
  Future<Student?> getCurrentSession() async {
    final db = await _db.database;
    final sessions = await db.query('sessions', where: 'id = 1');
    if (sessions.isEmpty) return null;
    final sid = sessions.first['student_id'];
    final rows =
        await db.query('students', where: 'id = ?', whereArgs: [sid]);
    if (rows.isEmpty) return null;
    return Student.fromMap(rows.first);
  }
}
