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
      'users',
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
      'groups',
    ],
    RobleTables.userCourse: [
      RobleTables.userCourse,
      'user_courses',
    ],
    RobleTables.userGroup: [
      RobleTables.userGroup,
      'group_members',
    ],
    RobleTables.evaluation: [
      RobleTables.evaluation,
      'evaluations',
    ],
    RobleTables.criterium: [
      RobleTables.criterium,
      'criteria',
    ],
    RobleTables.evaluationCriterium: [
      RobleTables.evaluationCriterium,
      'evaluation_responses',
    ],
    RobleTables.resultEvaluation: [
      RobleTables.resultEvaluation,
      'result_evaluation',
    ],
    RobleTables.resultCriterium: [
      RobleTables.resultCriterium,
      'result_criteria',
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
    'criteria': [
      'criteria',
      RobleTables.criterium,
    ],
    'users': [
      'users',
      RobleTables.users,
    ],
    'groups': [
      'groups',
      RobleTables.groups,
    ],
    'user_courses': [
      'user_courses',
      RobleTables.userCourse,
    ],
    'result_evaluation': [
      'result_evaluation',
      RobleTables.resultEvaluation,
    ],
    'result_criteria': [
      'result_criteria',
      RobleTables.resultCriterium,
    ],
  };

  // Canonical primary key by logical table name.
  static const Map<String, String> tablePrimaryKeys = {
    RobleTables.users: RobleFields.userId,
    RobleTables.course: RobleFields.courseId,
    RobleTables.category: RobleFields.categoryId,
    RobleTables.groups: RobleFields.groupId,
    RobleTables.userCourse: RobleFields.rowId,
    RobleTables.userGroup: RobleFields.rowId,
    RobleTables.evaluation: RobleFields.evaluationId,
    RobleTables.criterium: RobleFields.criteriumId,
    RobleTables.evaluationCriterium: RobleFields.rowId,
    RobleTables.resultEvaluation: RobleFields.resultEvaluationId,
    RobleTables.resultCriterium: RobleFields.rowId,
  };

  // Canonical field -> accepted aliases by logical table name.
  static const Map<String, Map<String, List<String>>> fieldAliasesByTable = {
    RobleTables.evaluation: {
      RobleFields.evaluationId: [RobleFields.evalId],
    },
    RobleTables.criterium: {
      RobleFields.criteriumId: [RobleFields.criterionId],
    },
    RobleTables.evaluationCriterium: {
      RobleFields.evaluationId: [RobleFields.evalId],
      RobleFields.criteriumId: [RobleFields.criterionId],
    },
    RobleTables.resultEvaluation: {
      RobleFields.resultEvaluationId: [
        'result_evaluation_id',
        'resultevaluation_id',
      ],
    },
    RobleTables.resultCriterium: {
      RobleFields.criteriumId: [RobleFields.criterionId],
    },
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
  static const String nrc = 'nrc';
  static const String email = 'email';
  static const String role = 'role';
  static const String createdAt = 'created_at';
  static const String importedAt = 'imported_at';
  static const String evalId = 'eval_id';
  static const String evaluationId = 'evaluation_id';
  static const String startDate = 'start_date';
  static const String endDate = 'end_date';
  static const String evaluatorId = 'evaluator_id';
  static const String evaluatedMemberId = 'evaluated_member_id';
  static const String criteriumId = 'criterium_id';
  static const String criterionId = 'criterion_id';
  static const String resultId = 'result_id';
  static const String resultEvaluationId = 'resultEvaluation_id';
  static const String comment = 'comment';
  static const String maxScore = 'max_score';
  static const String score = 'score';
}