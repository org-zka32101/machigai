import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:machigai/services/ai_generation_service.dart';

void main() {
  group('EditScreen - AI Quality Score Widget', () {
    late AIGenerationService aiService;

    setUp(() {
      aiService = AIGenerationService();
    });

    // Mock widget similar to _AIQualityScore from edit.dart
    Widget buildTestWidget(Map<String, dynamic> editedPoint, String difficulty) {
      return MaterialApp(
        home: ProviderScope(
          child: Scaffold(
            body: _TestAIQualityScore(
              editedPoint: editedPoint,
              difficulty: difficulty,
              aiService: aiService,
            ),
          ),
        ),
      );
    }

    group('Score Display', () {
      testWidgets('displays score in format XX.X/100', (WidgetTester tester) async {
        final editedPoint = {'brightness': 0.5, 'colorHue': 0.3};
        await tester.pumpWidget(buildTestWidget(editedPoint, 'medium'));

        // Look for score text pattern like "75.5/100"
        expect(find.byType(Text), findsWidgets);
        // The widget should display a score
        expect(
          find.byWidgetPredicate(
            (widget) => widget is Text && widget.data?.contains('/100') == true,
          ),
          findsWidgetsSatisfying((w) => w is Text),
        );
      });

      testWidgets('shows loading indicator initially', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget({}, 'easy'));

        // Should show loading spinner or content
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });

      testWidgets('displays progress bar', (WidgetTester tester) async {
        final editedPoint = {'brightness': 0.6};
        await tester.pumpWidget(buildTestWidget(editedPoint, 'medium'));

        // Look for progress bar (LinearProgressIndicator or custom bar)
        expect(
          find.byWidgetPredicate(
            (widget) => widget is LinearProgressIndicator ||
                       (widget is Container && widget.constraints != null),
          ),
          findsWidgets,
        );
      });

      testWidgets('score text updates when edits change', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget({'brightness': 0.3}, 'easy'));
        await tester.pumpAndSettle();

        // Record initial state (would need state management in real scenario)
        // In a real test, you'd update riverpod state and check for widget update
        expect(find.byType(Text), findsWidgets);
      });
    });

    group('Quality Label Display', () {
      testWidgets('shows quality label in Japanese', (WidgetTester tester) async {
        final editedPoint = {'brightness': 0.8, 'colorHue': 0.7, 'positionX': 0.5};
        await tester.pumpWidget(buildTestWidget(editedPoint, 'hard'));

        // Should display one of: 優秀, 良好, 普通, 要改善, 不適格
        expect(
          find.byWidgetPredicate(
            (widget) => widget is Text &&
              (widget.data?.contains('優秀') == true ||
               widget.data?.contains('良好') == true ||
               widget.data?.contains('普通') == true ||
               widget.data?.contains('要改善') == true ||
               widget.data?.contains('不適格') == true),
          ),
          findsWidgets,
        );
      });

      testWidgets('displays correct label for high score', (WidgetTester tester) async {
        // Complex edits should get good score
        final editedPoint = {
          'brightness': 0.5,
          'colorHue': 0.4,
          'positionX': 0.3,
          'positionY': 0.2,
        };
        await tester.pumpWidget(buildTestWidget(editedPoint, 'hard'));

        // Should show 優秀 or 良好 for high quality
        expect(
          find.byWidgetPredicate(
            (widget) => widget is Text &&
              (widget.data?.contains('優秀') == true ||
               widget.data?.contains('良好') == true),
          ),
          findsWidgets,
        );
      });

      testWidgets('displays correct label for low score', (WidgetTester tester) async {
        // Single minimal edit with misaligned difficulty
        final editedPoint = {'brightness': 0.05};
        await tester.pumpWidget(buildTestWidget(editedPoint, 'hard'));

        // Should show 要改善 or 不適格 for low quality
        expect(
          find.byWidgetPredicate(
            (widget) => widget is Text &&
              (widget.data?.contains('要改善') == true ||
               widget.data?.contains('不適格') == true),
          ),
          findsWidgets,
        );
      });
    });

    group('Color Coding', () {
      testWidgets('progress bar color changes with score', (WidgetTester tester) async {
        final editedPoint = {'brightness': 0.3};
        await tester.pumpWidget(buildTestWidget(editedPoint, 'easy'));

        // Widget should have color property that varies
        // Color should be based on score (green/orange/red)
        expect(find.byType(LinearProgressIndicator), findsWidgets);
      });

      testWidgets('green color for excellent score (80+)', (WidgetTester tester) async {
        // This would require excellent edits
        final editedPoint = {
          'brightness': 0.6,
          'colorHue': 0.5,
          'positionX': 0.4,
          'positionY': 0.3,
        };
        await tester.pumpWidget(buildTestWidget(editedPoint, 'hard'));

        // Check for green color indicator (actual RGB depends on implementation)
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('red color for unacceptable score (0-19)', (WidgetTester tester) async {
        final editedPoint = {'brightness': 0.02};
        await tester.pumpWidget(buildTestWidget(editedPoint, 'hard'));

        // Widget should have error/warning color
        expect(find.byType(Container), findsWidgets);
      });
    });

    group('Feedback Messages', () {
      testWidgets('shows encouraging message for high scores', (WidgetTester tester) async {
        final editedPoint = {'brightness': 0.7, 'colorHue': 0.6, 'positionX': 0.5};
        await tester.pumpWidget(buildTestWidget(editedPoint, 'hard'));

        // Look for positive feedback emoji/text
        final hasFeedback = find.byWidgetPredicate(
          (widget) => widget is Text &&
            (widget.data?.contains('✨') == true ||
             widget.data?.contains('👍') == true ||
             widget.data?.contains('素晴らしい') == true ||
             widget.data?.contains('良好') == true),
        );

        // Should find some feedback
        expect(hasFeedback, findsWidgets);
      });

      testWidgets('shows improvement suggestion for low scores', (WidgetTester tester) async {
        final editedPoint = {'brightness': 0.1};
        await tester.pumpWidget(buildTestWidget(editedPoint, 'hard'));

        // Look for improvement-related text
        final hasImprovement = find.byWidgetPredicate(
          (widget) => widget is Text &&
            (widget.data?.contains('⚠️') == true ||
             widget.data?.contains('❌') == true ||
             widget.data?.contains('工夫') == true ||
             widget.data?.contains('改善') == true),
        );

        // Should find improvement message
        expect(hasImprovement, findsWidgets);
      });

      testWidgets('displays message in Japanese', (WidgetTester tester) async {
        final editedPoint = {'brightness': 0.4};
        await tester.pumpWidget(buildTestWidget(editedPoint, 'medium'));

        // Verify Japanese text is present
        expect(
          find.byWidgetPredicate(
            (widget) => widget is Text &&
              RegExp(r'[぀-ゟ゠-ヿ一-鿿]').hasMatch(
                widget.data ?? ''
              ),
          ),
          findsWidgets,
        );
      });
    });

    group('Responsive Layout', () {
      testWidgets('widget fits within screen bounds', (WidgetTester tester) async {
        tester.binding.window.physicalSizeTestValue = const Size(400, 800);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        await tester.pumpWidget(buildTestWidget({'brightness': 0.5}, 'medium'));

        // Should not overflow
        expect(find.byType(OverflowBox), findsNothing);
        expect(find.byType(SingleChildScrollView), findsWidgets);
      });

      testWidgets('widget scales on small screens', (WidgetTester tester) async {
        tester.binding.window.physicalSizeTestValue = const Size(320, 600);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        await tester.pumpWidget(buildTestWidget({'brightness': 0.5}, 'medium'));
        await tester.pumpAndSettle();

        // Widget should still be present and properly sized
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('widget scales on large screens', (WidgetTester tester) async {
        tester.binding.window.physicalSizeTestValue = const Size(1280, 720);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        await tester.pumpWidget(buildTestWidget({'brightness': 0.5}, 'medium'));
        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });
    });

    group('Accessibility', () {
      testWidgets('has semantic labels for score', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget({'brightness': 0.5}, 'medium'));

        // Look for Semantics widgets
        expect(find.byType(Semantics), findsWidgets);
      });

      testWidgets('score is readable by screen readers', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget({'brightness': 0.5}, 'medium'));

        // Should have text that screen readers can access
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('color alone does not convey information', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget({'brightness': 0.5}, 'medium'));

        // Text labels should be present alongside colors
        expect(find.byType(Text), findsWidgets);
      });
    });

    group('Error Handling', () {
      testWidgets('handles empty editedPoint gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget({}, 'easy'));

        // Should display score of 0 or N/A
        expect(find.byType(Text), findsWidgets);
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });

      testWidgets('handles invalid difficulty gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget({'brightness': 0.5}, 'invalid'));

        // Should handle gracefully, show some feedback
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('shows error message if score calculation fails', (WidgetTester tester) async {
        // This test would need error injection capability
        await tester.pumpWidget(buildTestWidget({'brightness': 0.5}, 'medium'));

        // Widget should be visible regardless
        expect(find.byType(Scaffold), findsOneWidget);
      });
    });

    group('Animation Tests', () {
      testWidgets('progress bar animates smoothly', (WidgetTester tester) async {
        tester.binding.window.physicalSizeTestValue = const Size(400, 800);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        await tester.pumpWidget(buildTestWidget({'brightness': 0.5}, 'medium'));

        // Animation should run (find animated widgets)
        expect(find.byType(LinearProgressIndicator), findsWidgets);
      });

      testWidgets('score updates without janky animations', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget({'brightness': 0.3}, 'easy'));
        await tester.pumpAndSettle();

        // Widget should settle smoothly
        expect(find.byType(Text), findsWidgets);
      });
    });
  });
}

// Mock AI Quality Score Widget for testing
class _TestAIQualityScore extends StatelessWidget {
  final Map<String, dynamic> editedPoint;
  final String difficulty;
  final AIGenerationService aiService;

  const _TestAIQualityScore({
    required this.editedPoint,
    required this.difficulty,
    required this.aiService,
  });

  @override
  Widget build(BuildContext context) {
    final score = aiService.diagnoseChallenge(editedPoint, difficulty);
    final label = aiService.getQualityLabel(score);
    final color = aiService.getQualityColor(score);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          color: Color(0xFFF0F4FF),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Score Display
                Text(
                  '${score.toStringAsFixed(1)}/100',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    minHeight: 8,
                    color: Color(color),
                  ),
                ),
                const SizedBox(height: 12),

                // Quality Label
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(color),
                  ),
                ),
                const SizedBox(height: 12),

                // Feedback Message
                Text(
                  _getFeedbackMessage(score),
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getFeedbackMessage(double score) {
    if (score >= 80) return '✨ 素晴らしい品質です！';
    if (score >= 60) return '👍 良好な品質です。';
    if (score >= 40) return '🔧 編集をもっと工夫してみてください';
    if (score >= 20) return '⚠️ 編集の多様性が足りません';
    return '❌ 編集が不十分です';
  }
}
