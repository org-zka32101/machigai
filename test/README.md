# Phase 5 Session 4: Comprehensive Testing Suite

## Overview

This directory contains comprehensive unit, widget, and integration tests for the machigai application's Phase 5 implementation (Firebase integration, AI scoring, and Lottie animations).

---

## Test Structure

```
test/
├── unit/
│   └── services/
│       └── ai_generation_service_test.dart    # AIGenerationService unit tests
├── widget/
│   └── edit_screen_ai_widget_test.dart        # EditScreen AI quality widget tests
├── integration/
│   └── challenge_creation_flow_test.dart      # End-to-end challenge creation tests
├── mocks/
│   └── mock_firestore.dart                    # Mock Firestore for testing
└── README.md                                  # This file
```

---

## Unit Tests

### `ai_generation_service_test.dart` (50+ test cases)

Tests for the AI scoring algorithm, difficulty calculation, and quality labels.

#### Scoring Algorithm Tests
- ✅ Empty/null input handling
- ✅ Single edit scoring (50-70 range)
- ✅ Multiple edits score higher
- ✅ Three edits score highest
- ✅ Parameter type rewards
- ✅ Extreme value penalties
- ✅ Difficulty alignment effects
- ✅ Score range validation (0-100)
- ✅ Complex edit maximization
- ✅ Deterministic scoring

#### Auto-Difficulty Calculation Tests
- ✅ Easy difficulty for minimal edits
- ✅ Medium difficulty for moderate edits
- ✅ Hard difficulty for complex edits
- ✅ High variation recognition
- ✅ All difficulty levels recognized

#### Quality Label Tests
- ✅ 優秀 (Excellent) for 80-100
- ✅ 良好 (Good) for 60-79
- ✅ 普通 (Fair) for 40-59
- ✅ 要改善 (Needs Improvement) for 20-39
- ✅ 不適格 (Unacceptable) for 0-19
- ✅ Boundary condition accuracy

#### Quality Color Tests
- ✅ Green color for excellent
- ✅ Light green for good
- ✅ Orange for fair
- ✅ Deep orange for needs improvement
- ✅ Red for unacceptable
- ✅ Valid hex color values

#### Integration Tests
- ✅ Complete quality assessment workflow
- ✅ High quality scenario
- ✅ Low quality scenario

#### Edge Cases
- ✅ Very small values near zero
- ✅ Maximum values near one
- ✅ Many parameter variations
- ✅ Null value handling

**Run:** `flutter test test/unit/services/ai_generation_service_test.dart`

---

## Widget Tests

### `edit_screen_ai_widget_test.dart` (40+ test cases)

Tests for the EditScreen AI quality score widget UI and functionality.

#### Score Display Tests
- ✅ Score format (XX.X/100)
- ✅ Loading indicator display
- ✅ Progress bar rendering
- ✅ Score updates on edit changes

#### Quality Label Display
- ✅ Japanese label rendering
- ✅ Correct label for high scores
- ✅ Correct label for low scores

#### Color Coding Tests
- ✅ Progress bar color changes with score
- ✅ Green for excellent
- ✅ Red for unacceptable

#### Feedback Message Tests
- ✅ Encouraging message for high scores
- ✅ Improvement suggestions for low scores
- ✅ Japanese text verification

#### Responsive Layout Tests
- ✅ Fits within screen bounds
- ✅ Scales on small screens (320px)
- ✅ Scales on large screens (1280px)

#### Accessibility Tests
- ✅ Semantic labels present
- ✅ Screen reader compatibility
- ✅ Non-color-dependent information

#### Error Handling Tests
- ✅ Empty editedPoint handling
- ✅ Invalid difficulty handling
- ✅ Calculation failure handling

#### Animation Tests
- ✅ Progress bar animation
- ✅ Smooth score updates

**Run:** `flutter test test/widget/edit_screen_ai_widget_test.dart`

---

## Integration Tests

### `challenge_creation_flow_test.dart` (30+ test cases)

End-to-end tests for the complete challenge creation workflow.

#### Complete Workflow Tests
- ✅ User creates challenge with AI feedback
- ✅ High quality challenge scoring and publishing
- ✅ Low quality challenge with suggestions

#### Difficulty Alignment Tests
- ✅ Easy difficulty with simple edits (aligned)
- ✅ Medium difficulty with moderate edits (aligned)
- ✅ Hard difficulty with complex edits (aligned)
- ✅ Hard difficulty with simple edits (misaligned)

#### Quality Score Progression
- ✅ Score increases with complexity
- ✅ Deterministic scoring across runs

#### Challenge Persistence Tests
- ✅ All required fields present
- ✅ Retrieve challenge by ID
- ✅ aiScore persistence and retrieval

#### Edge Cases
- ✅ Null aiScore (backward compatibility)
- ✅ Maximum complexity challenges
- ✅ Minimal edits handling

#### Quality Feedback Loop
- ✅ User can iterate based on feedback
- ✅ Score improvements on iteration

**Run:** `flutter test test/integration/challenge_creation_flow_test.dart`

---

## Mock Firestore

### `mock_firestore.dart`

Complete mock implementation of Firestore for testing without Firebase connection.

#### Components
- `MockFirebaseFirestore` - Main Firestore mock
- `MockCollectionReference` - Collection operations
- `MockDocumentReference` - Document CRUD operations
- `MockQuerySnapshot` - Query results
- `MockQuery` - Query filtering and ordering
- `MockTimestamp` - Timestamp mock
- `MockFieldValue` - Field increment operations

#### Usage Example

```dart
void main() {
  test('challenge creation with mock firestore', () async {
    final mockFirestore = MockFirebaseFirestore();
    
    // Use in ChallengeService
    final challengeService = ChallengeService(firestore: mockFirestore);
    
    // Test operations
    final challenge = await challengeService.createChallenge(
      creatorId: 'test_user',
      videoUrl: 'gs://bucket/test.mp4',
      editedPoint: {'brightness': 0.5},
      difficulty: 'medium',
    );
    
    expect(challenge.id, isNotEmpty);
  });
}
```

---

## Running Tests

### All Tests
```bash
flutter test
```

### Unit Tests Only
```bash
flutter test test/unit/
```

### Widget Tests Only
```bash
flutter test test/widget/
```

### Integration Tests Only
```bash
flutter test test/integration/
```

### Specific Test File
```bash
flutter test test/unit/services/ai_generation_service_test.dart
```

### With Coverage
```bash
flutter test --coverage
lcov --list coverage/lcov.info
```

---

## Test Coverage Goals

| Component | Target | Status |
|-----------|--------|--------|
| AIGenerationService | 95%+ | ✅ 50+ tests |
| EditScreen AI Widget | 90%+ | ✅ 40+ tests |
| Challenge Creation Flow | 85%+ | ✅ 30+ tests |
| Model Serialization | 90%+ | ✅ Integrated tests |
| **Total** | **90%+** | ✅ 120+ tests |

---

## Key Testing Patterns

### 1. Unit Testing AI Service
```dart
test('scores single edit correctly', () {
  final service = AIGenerationService();
  final score = service.diagnoseChallenge({'brightness': 0.5}, 'easy');
  expect(score, inInclusiveRange(50.0, 100.0));
});
```

### 2. Widget Testing with Mock Service
```dart
testWidgets('displays quality label', (WidgetTester tester) async {
  final aiService = AIGenerationService();
  await tester.pumpWidget(buildTestWidget(editedPoint, 'medium'));
  expect(find.byType(Text), findsWidgets);
});
```

### 3. Integration Testing with Mock Firestore
```dart
test('challenge persists with aiScore', () async {
  final mockFirestore = MockFirebaseFirestore();
  final service = ChallengeService(firestore: mockFirestore);
  final challenge = await service.createChallenge(...);
  expect(challenge.aiScore, equals(score));
});
```

---

## Continuous Integration

All tests should pass before merging:

```bash
# Local validation
flutter test --coverage

# Check coverage
lcov --list coverage/lcov.info | grep Total
```

### GitHub Actions Integration

Add to `.github/workflows/test.yml`:

```yaml
- name: Run tests
  run: flutter test --coverage

- name: Upload coverage
  uses: codecov/codecov-action@v3
  with:
    files: ./coverage/lcov.info
```

---

## Future Enhancements

- [ ] Add performance benchmarks for scoring algorithm
- [ ] Add visual regression tests for UI
- [ ] Add real Firebase integration tests (separate suite)
- [ ] Add E2E tests with Riverpod state management
- [ ] Add mutation testing for algorithm robustness
- [ ] Add accessibility audit tests

---

## Troubleshooting

### Tests fail with "No Firebase app configured"
- Use MockFirebaseFirestore instead of real Firebase
- Check that services accept firestore parameter injection

### Widget tests timeout
- Increase timeout: `tester.pumpAndSettle(Duration(seconds: 5))`
- Use `tester.pumpAndSettle()` instead of `tester.pump()`

### Coverage data not generated
- Run with `--coverage` flag
- Install `lcov` if needed: `brew install lcov`

---

## Test Maintenance

- Review and update tests when adding features
- Keep mock implementations synchronized with real classes
- Monitor test execution time (goal: < 2 minutes total)
- Maintain > 85% coverage on critical paths

---

**Phase 5 Session 4**: 120+ comprehensive tests covering AI scoring, widget rendering, and complete workflow integration.

Status: ✅ **Complete**
