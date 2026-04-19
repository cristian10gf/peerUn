# Teacher Data Insights Design

## Goal
Build a new teacher-only DATOS experience that shows global coevaluation insights across all evaluations owned by the logged-in teacher, replacing the current single-evaluation focus in the DATOS navbar path.

## Current State
- DATOS currently points to the results detail flow and is centered on one selected evaluation.
- Current files involved:
  - `lib/presentation/pages/teacher/t_results_page.dart`
  - `lib/presentation/controllers/teacher/teacher_results_controller.dart`
  - `lib/domain/repositories/i_evaluation_repository.dart`
  - `lib/data/repositories/evaluation_repository_impl.dart`
- Existing query-budget discipline for group results already exists in tests and must be preserved/extended.

## Scope
In scope:
- New global insights page for teachers at navbar DATOS.
- Fetch and aggregate real ROBLE data only.
- Metrics:
  - average by course
  - average by category
  - best group per course
  - top students
  - at-risk students
  - evaluations considered (transparency block)
- Strict teacher data isolation.
- Componentized UI, clean separation of responsibilities, explicit DI.
- Repository, domain service, controller, mapper, widget, and query-budget tests.

Out of scope:
- Demo/fake datasets in production UI.
- New backend endpoint creation.
- Changes to student flows.
- Replacing existing detailed results page (`/teacher/results`).

## Non-Negotiable Data Isolation Rule
All analytics must be computed only from evaluations owned by the authenticated teacher.

Enforcement rule:
1. Start from evaluations filtered by `created_by`/`teacher_id == currentTeacherId`.
2. Derive all related categories, courses, groups, members, and results only from that evaluation set.
3. Ignore any row that cannot be linked to that teacher-owned evaluation set.

This prevents cross-professor leakage even when data shares tables.

## Architecture

### High-Level Design
1. Repository fetches ROBLE data in bounded roundtrips and builds a normalized input dataset for one teacher.
2. Domain service computes aggregate insights from normalized input.
3. Presentation mapper converts domain aggregates to UI view models.
4. New insights controller orchestrates loading/error/empty/data states.
5. New DATOS page renders componentized KPI sections.

### Layers and Responsibilities
- Data layer: fetch + normalize raw ROBLE rows, enforce teacher scoping.
- Domain service: deterministic aggregation rules and ranking logic.
- Presentation service: formatting and UI-facing model mapping.
- Controller (GetX): screen state, refresh behavior, error propagation.
- UI components: pure rendering by section.

## Component Plan

### Domain Models
Create `lib/domain/models/teacher_insights.dart` with two model groups:

Input models (from repository normalization):
- `TeacherInsightsInput`
- `TeacherInsightsScorePoint`
- `TeacherInsightsEvaluationCoverage`

Computed models (from domain service):
- `TeacherInsightsAggregate`
- `TeacherCourseAverage`
- `TeacherCategoryAverage`
- `TeacherBestGroup`
- `TeacherStudentAverage`

### Domain Service
Create `lib/domain/services/teacher_insights_domain_service.dart`.

Responsibilities:
- Validate score range (use only `2 <= score <= 5`).
- Compute weighted averages by category and by course.
- Compute best group per course using tie-breaks.
- Compute top and at-risk student rankings.
- Enforce minimum sample thresholds.

### Repository Contract
Extend `lib/domain/repositories/i_evaluation_repository.dart`:
- Add `Future<TeacherInsightsInput> getTeacherInsightsInput(int teacherId);`

Implementation in `lib/data/repositories/evaluation_repository_impl.dart`:
- Add `getTeacherInsightsInput` using bounded table reads.
- Normalize all IDs safely with existing varchar/id mapping rules.
- Build teacher-scoped `TeacherInsightsScorePoint` rows with resolved:
  - evaluation
  - course
  - category
  - group
  - student
  - score

### Presentation Models and Mapper
Create:
- `lib/presentation/models/teacher_data_insights_view_model.dart`
- `lib/presentation/services/teacher_insights_view_mapper.dart`

Mapper responsibilities:
- Convert aggregate domain output to render-ready VM sections.
- Apply display ordering and labels.
- Build empty section flags per block.

### Controller
Create `lib/presentation/controllers/teacher/teacher_insights_controller.dart`.

Dependencies:
- `IEvaluationRepository`
- `TeacherInsightsDomainService`
- `TeacherInsightsViewMapper`
- `TeacherSessionController`

State:
- `isLoading`
- `loadError`
- `overviewVm`
- `lastUpdatedAt`

Actions:
- `loadInsights()`
- `refreshInsights()`
- `resetState()`

### UI Pages and Widgets
Create page:
- `lib/presentation/pages/teacher/t_data_insights_page.dart`

Create componentized widgets:
- `lib/presentation/pages/teacher/widgets/insights/teacher_insights_header.dart`
- `lib/presentation/pages/teacher/widgets/insights/teacher_course_average_section.dart`
- `lib/presentation/pages/teacher/widgets/insights/teacher_category_average_section.dart`
- `lib/presentation/pages/teacher/widgets/insights/teacher_best_group_section.dart`
- `lib/presentation/pages/teacher/widgets/insights/teacher_student_rank_section.dart`
- `lib/presentation/pages/teacher/widgets/insights/teacher_insights_state_cards.dart`

Navbar behavior:
- DATOS should route to `/teacher/data-insights`.
- Keep `/teacher/results` for per-evaluation detail flow.

## ROBLE Data Fetch Strategy

### Target Query Budget
Hard target: maximum 10 `robleRead` calls per full load.

Expected read set (8-9 total):
1. `evaluation`
2. `category`
3. `course`
4. `group`
5. `user_group`
6. `user`
7. `resultEvaluation`
8. `result_criterium`
9. optional `criterium` only if required for labels

### Performance Rules
- No per-evaluation N+1 loops.
- No per-group nested read loops.
- Use in-memory maps for joins after base reads.
- All aggregation must run in-memory on normalized rows.

## Business Rules

### Valid Scores
Use only scores in inclusive range [2, 5].

### Averages
- Category average: weighted mean of valid scores in category.
- Course average: weighted mean of valid scores in course.
- Group average: weighted mean of valid scores in group.

### Best Group per Course
Pick group with highest average in each course.
Tie-break sequence:
1. Higher number of valid scores.
2. Lexicographically smaller group name.

### Student Rankings
- Top students: descending by received average.
- At-risk students: received average < 3.0.

Minimum sample thresholds:
- Student ranking eligibility: at least 4 valid scores.
- Best-group eligibility: at least 4 valid scores for that group.

### No-Data Behavior
- If teacher has no evaluations: global empty state + CTA to create evaluation.
- If evaluations exist but no responses: global empty state + guidance CTA.
- If only one block lacks data, show that block empty while rendering other blocks.
- No synthetic demo data in production UI.

## Error Handling
- Repository and controller should parse errors using existing `parseApiError` style.
- Page-level error card should include user-safe message and retry action.
- If base ROBLE fetch fails, show a global page error state.
- If fetch succeeds but one KPI block lacks enough valid samples, keep page data and render only that block as empty.

## DI and Routing Changes
- Update `lib/presentation/bindings/teacher_module_binding.dart` to register:
  - `TeacherInsightsDomainService`
  - `TeacherInsightsViewMapper`
  - `TeacherInsightsController`
- Update routes in `lib/main.dart`:
  - Add `/teacher/data-insights`.
- Update teacher bottom nav DATOS item destination to `/teacher/data-insights`.

## Testing Strategy

### Domain Service Tests
Create `test/domain/services/teacher_insights_domain_service_test.dart`:
- averages by course/category
- best-group tie-break
- ranking thresholds
- at-risk cutoff

### Repository Tests
Create `test/data/repositories/evaluation_repository_teacher_insights_test.dart`:
- teacher-only scoping correctness
- ID normalization correctness for varchar IDs
- robust mapping from ROBLE-like rows to input dataset

Create `test/data/repositories/evaluation_repository_teacher_insights_query_budget_test.dart`:
- assert total read calls <= 10
- assert no nested N+1 read behavior

### Controller Tests
Create `test/presentation/controllers/teacher_insights_controller_test.dart`:
- loading success -> vm available
- empty dataset -> empty vm state
- error path -> user-safe message
- refresh behavior

### Widget/Page Tests
Create `test/presentation/pages/teacher/t_data_insights_page_widget_test.dart`:
- loading state
- empty state
- error state
- full data render with all KPI blocks

### Integration Guard for Multi-Tenancy
Add fixture with two teachers and shared tables; assert analytics output includes only rows linked to current teacher evaluations.

## Acceptance Criteria
1. DATOS navbar opens global teacher insights page, not single-evaluation detail page.
2. All displayed metrics are scoped to authenticated teacher only.
3. KPIs include course average, category average, best group per course, top students, at-risk students.
4. Page supports loading/empty/error/data states with reusable components.
5. Query budget test passes with <= 10 reads for full load.
6. Multi-tenant isolation tests pass.
7. Existing `/teacher/results` detail flow remains functional.

## Risks and Mitigations
- Risk: cross-professor leakage due to broad joins.
  - Mitigation: teacher-owned evaluation set as first-class filter and dedicated isolation tests.
- Risk: performance regression from nested reads.
  - Mitigation: query-budget test and map-based in-memory joins.
- Risk: inconsistent ranking due to low sample counts.
  - Mitigation: explicit minimum-sample thresholds and tests.

## Rollout Notes
- Ship in one feature branch with additive route.
- Keep old detail page intact for fallback.
- If needed, feature flag DATOS route switch for staged rollout.
