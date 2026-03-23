class RobleTables {
  const RobleTables._();

  static const String users = 'user';
  static const String course = 'course';
  static const String category = 'category';
  static const String groups = 'group';
  static const String userCourse = 'user_course';
  static const String userGroup = 'user_group';
  static const String evaluation = 'evaluation';
  static const String criterium = 'criterium';
  static const String evaluationCriterium = 'evaluation_criterium';
  static const String resultEvaluation = 'resultEvaluation';
  static const String resultCriterium = 'result_criterium';
}

class RobleSchema {
  const RobleSchema._();

  // Logical table names -> known aliases in different schema versions.
  static const Map<String, List<String>> tableAliases = {
    RobleTables.users: [
      RobleTables.users,
    ],
    RobleTables.course: [
      RobleTables.course,
      'courses',
    ],
    RobleTables.category: [
      RobleTables.category,
      'categories',
      'group_categories',
    ],
    RobleTables.groups: [
      RobleTables.groups,
    ],
    RobleTables.userCourse: [
      RobleTables.userCourse,
    ],
    RobleTables.userGroup: [
      RobleTables.userGroup,
      'group_members',
    ],
    RobleTables.evaluation: [
      RobleTables.evaluation,
      'evaluations',
    ],
    RobleTables.evaluationCriterium: [
      RobleTables.evaluationCriterium,
      'evaluation_responses',
    ],
    RobleTables.resultEvaluation: [
      RobleTables.resultEvaluation,
    ],
    RobleTables.resultCriterium: [
      RobleTables.resultCriterium,
    ],
    // Backward-compatible keys used in older repository code.
    'courses': [
      'courses',
      RobleTables.course,
    ],
    'categories': [
      'categories',
      RobleTables.category,
      'group_categories',
    ],
    'group_categories': [
      'group_categories',
      'categories',
      RobleTables.category,
    ],
    'evaluations': [
      'evaluations',
      RobleTables.evaluation,
    ],
    'group_members': [
      'group_members',
      RobleTables.userGroup,
    ],
    'evaluation_responses': [
      'evaluation_responses',
      RobleTables.evaluationCriterium,
    ],
  };
}

class RobleFields {
  const RobleFields._();

  static const String id = 'id';
  static const String rowId = '_id';
  static const String userId = 'user_id';
  static const String courseId = 'course_id';
  static const String categoryId = 'category_id';
  static const String groupId = 'group_id';
  static const String createdBy = 'created_by';
  static const String teacherId = 'teacher_id';
  static const String name = 'name';
  static const String title = 'title';
  static const String description = 'description';
  static const String email = 'email';
  static const String role = 'role';
  static const String createdAt = 'created_at';
  static const String importedAt = 'imported_at';
  static const String evalId = 'eval_id';
  static const String evaluationId = 'evaluation_id';
  static const String evaluatorId = 'evaluator_id';
  static const String evaluatedMemberId = 'evaluated_member_id';
  static const String criterionId = 'criterion_id';
  static const String score = 'score';
}