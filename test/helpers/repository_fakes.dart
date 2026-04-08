import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:example/domain/models/auth_login_result.dart';
import 'package:example/domain/models/course.dart';
import 'package:example/domain/models/course_model.dart';
import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/models/group_category.dart';
import 'package:example/domain/models/peer_evaluation.dart';
import 'package:example/domain/models/student.dart';
import 'package:example/domain/models/student_home.dart';
import 'package:example/domain/models/teacher.dart';
import 'package:example/domain/models/teacher_data.dart';
import 'package:example/domain/repositories/i_auth_repository.dart';
import 'package:example/domain/repositories/i_connectivity_repository.dart';
import 'package:example/domain/repositories/i_course_repository.dart';
import 'package:example/domain/repositories/i_evaluation_repository.dart';
import 'package:example/domain/repositories/i_group_repository.dart';
import 'package:example/domain/repositories/i_teacher_auth_repository.dart';
import 'package:example/domain/repositories/i_unified_auth_repository.dart';

class FakeUnifiedAuthRepository implements IUnifiedAuthRepository {
  AuthLoginResult? nextResult;
  Object? nextError;
  String? lastEmail;
  String? lastPassword;

  @override
  Future<AuthLoginResult?> loginAndResolve(String email, String password) async {
    lastEmail = email;
    lastPassword = password;
    if (nextError != null) {
      throw nextError!;
    }
    return nextResult;
  }
}

class FakeAuthRepository implements IAuthRepository {
  Student? session;
  Student? loginResult;
  Student registerResult = const Student(
    id: '1',
    name: 'Student Test',
    email: 'student@test.com',
    initials: 'ST',
  );
  Object? loginError;
  Object? registerError;
  int logoutCalls = 0;

  @override
  Future<Student?> getCurrentSession() async => session;

  @override
  Future<Student?> login(String email, String password) async {
    if (loginError != null) {
      throw loginError!;
    }
    return loginResult;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    session = null;
  }

  @override
  Future<Student> register(String name, String email, String password) async {
    if (registerError != null) {
      throw registerError!;
    }
    session = registerResult;
    return registerResult;
  }
}

class FakeTeacherAuthRepository implements ITeacherAuthRepository {
  Teacher? session;
  Teacher? loginResult;
  Teacher registerResult = const Teacher(
    id: '10',
    name: 'Teacher Test',
    email: 'teacher@test.com',
    initials: 'TT',
  );
  Object? loginError;
  Object? registerError;
  int logoutCalls = 0;

  @override
  Future<Teacher?> getCurrentSession() async => session;

  @override
  Future<Teacher?> login(String email, String password) async {
    if (loginError != null) {
      throw loginError!;
    }
    return loginResult;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    session = null;
  }

  @override
  Future<Teacher> register(String name, String email, String password) async {
    if (registerError != null) {
      throw registerError!;
    }
    session = registerResult;
    return registerResult;
  }
}

class FakeEvaluationRepository implements IEvaluationRepository {
  List<Evaluation> evaluations = <Evaluation>[];
  List<Peer> peers = <Peer>[];
  List<CriterionResult> results = <CriterionResult>[];
  List<StudentHomeCourse> homeCourses = <StudentHomeCourse>[];
  List<GroupResult> groupResults = <GroupResult>[];
  String? groupName;

  Object? nextError;
  Object? renameError;
  Object? deleteError;
  bool completedAllPeers = false;
  bool hasEvaluatedValue = false;

  @override
  Future<Evaluation> create({
    required String name,
    required int categoryId,
    required int hours,
    required String visibility,
    required int teacherId,
  }) async {
    if (nextError != null) {
      throw nextError!;
    }

    final created = Evaluation(
      id: evaluations.length + 1,
      name: name,
      categoryId: categoryId,
      categoryName: 'Cat',
      hours: hours,
      visibility: visibility,
      createdAt: DateTime.now(),
      closesAt: DateTime.now().add(Duration(hours: hours)),
    );

    evaluations = <Evaluation>[created, ...evaluations];
    return created;
  }

  @override
  Future<void> delete(int evalId) async {
    if (deleteError != null) throw deleteError!;
    evaluations = evaluations.where((e) => e.id != evalId).toList();
  }

  @override
  Future<List<Evaluation>> getAll(int teacherId) async => evaluations;

  @override
  Future<List<Course>> getCoursesForStudent(String email) async =>
      const <Course>[];

  @override
  Future<List<Evaluation>> getEvaluationsForStudent(String email) async =>
      evaluations;

  @override
  Future<String?> getGroupNameForStudent(int evalId, String email) async =>
      groupName;

  @override
  Future<List<GroupResult>> getGroupResults(int evalId) async => groupResults;

  @override
  Future<Evaluation?> getLatestForStudent(String email) async =>
      evaluations.isEmpty ? null : evaluations.first;

  @override
  Future<List<CriterionResult>> getMyResults(int evalId, String email) async =>
      results;

  @override
  Future<List<Peer>> getPeersForStudent(int evalId, String email) async =>
      peers;

  @override
  Future<List<StudentHomeCourse>> getStudentHomeCourses(String email) async =>
      homeCourses;

  @override
  Future<bool> hasCompletedAllPeers({
    required int evalId,
    required String email,
    required int studentId,
  }) async => completedAllPeers;

  @override
  Future<bool> hasEvaluated({
    required int evalId,
    required int evaluatorStudentId,
    required int evaluatedMemberId,
  }) async => hasEvaluatedValue;

  @override
  Future<void> rename(int evalId, String newName, int teacherId) async {
    if (renameError != null) throw renameError!;
    final index = evaluations.indexWhere((e) => e.id == evalId);
    if (index == -1) {
      return;
    }

    final old = evaluations[index];
    evaluations[index] = Evaluation(
      id: old.id,
      name: newName,
      categoryId: old.categoryId,
      categoryName: old.categoryName,
      courseName: old.courseName,
      hours: old.hours,
      visibility: old.visibility,
      createdAt: old.createdAt,
      closesAt: old.closesAt,
    );
  }

  @override
  Future<void> saveResponses({
    required int evalId,
    required int evaluatorStudentId,
    required int evaluatedMemberId,
    required Map<String, int> scores,
  }) async {}

  @override
  Future<void> testSaveSubmit({
    required String evaluatorEmail,
    required Map<String, Map<String, int>> scoresByPeerName,
  }) async {}

  @override
  Future<List<Map<String, dynamic>>> readTestTable() async => [];
}

class FakeGroupRepository implements IGroupRepository {
  List<GroupCategory> categories = <GroupCategory>[];

  @override
  Future<void> delete(int categoryId) async {
    categories = categories.where((c) => c.id != categoryId).toList();
  }

  @override
  Future<List<GroupCategory>> getAll(int teacherId) async => categories;

  @override
  Future<GroupCategory> importCsv(
    String csvContent,
    String categoryName,
    int teacherId,
    int courseId,
  ) async {
    final category = GroupCategory(
      id: categories.length + 1,
      name: categoryName,
      importedAt: DateTime.now(),
      groups: const <CourseGroup>[],
      courseId: courseId,
    );

    categories = <GroupCategory>[category, ...categories];
    return category;
  }
}

class FakeCourseRepository implements ICourseRepository {
  List<CourseModel> courses = <CourseModel>[];
  final Map<int, List<GroupCategory>> categoriesByCourse =
      <int, List<GroupCategory>>{};

  @override
  Future<CourseModel> create({
    required String name,
    required String code,
    required int teacherId,
  }) async {
    final created = CourseModel(
      id: courses.length + 1,
      teacherId: teacherId,
      name: name,
      code: code,
      createdAt: DateTime.now(),
    );

    courses = <CourseModel>[created, ...courses];
    return created;
  }

  @override
  Future<void> delete(int courseId) async {
    courses = courses.where((c) => c.id != courseId).toList();
  }

  @override
  Future<List<CourseModel>> getAll(int teacherId) async => courses;

  @override
  Future<List<GroupCategory>> getCategoriesForCourse(int courseId) async =>
      categoriesByCourse[courseId] ?? const <GroupCategory>[];
}

class FakeConnectivityRepository implements IConnectivityRepository {
  bool connected;
  final StreamController<bool> _connectionCtrl =
      StreamController<bool>.broadcast();
  final StreamController<List<ConnectivityResult>> _typesCtrl =
      StreamController<List<ConnectivityResult>>.broadcast();

  FakeConnectivityRepository({this.connected = true});

  void emit(bool value) {
    connected = value;
    _connectionCtrl.add(value);
    _typesCtrl.add(
      value
          ? const <ConnectivityResult>[ConnectivityResult.wifi]
          : const <ConnectivityResult>[ConnectivityResult.none],
    );
  }

  @override
  Future<bool> hasNetworkConnection() async => connected;

  @override
  Stream<bool> watchNetworkConnection() => _connectionCtrl.stream;

  @override
  Stream<List<ConnectivityResult>> watchConnectivityTypes() =>
      _typesCtrl.stream;

  Future<void> close() async {
    await _connectionCtrl.close();
    await _typesCtrl.close();
  }
}
