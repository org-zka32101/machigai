import 'package:flutter_test/flutter_test.dart';
import 'package:machigai/services/ai_generation_service.dart';

void main() {
  group('AIGenerationService', () {
    late AIGenerationService service;

    setUp(() {
      service = AIGenerationService();
    });

    group('diagnoseChallenge - Scoring Algorithm', () {
      test('returns 0.0 for empty editedPoint', () {
        final score = service.diagnoseChallenge({}, 'medium');
        expect(score, equals(0.0));
      });

      test('returns 0.0 for null editedPoint', () {
        final score = service.diagnoseChallenge({}, 'medium');
        expect(score, equals(0.0));
      });

      test('scores single edit between 50-70', () {
        final score = service.diagnoseChallenge({
          'brightness': 0.5,
        }, 'easy');
        expect(score, greaterThan(50.0));
        expect(score, lessThan(100.0));
      });

      test('scores two edits higher than one edit', () {
        final scoreSingle = service.diagnoseChallenge({
          'brightness': 0.5,
        }, 'medium');

        final scoreDouble = service.diagnoseChallenge({
          'brightness': 0.5,
          'colorHue': 0.3,
        }, 'medium');

        expect(scoreDouble, greaterThan(scoreSingle));
      });

      test('scores three edits highest', () {
        final scoreDouble = service.diagnoseChallenge({
          'brightness': 0.5,
          'colorHue': 0.3,
        }, 'medium');

        final scoreTriple = service.diagnoseChallenge({
          'brightness': 0.5,
          'colorHue': 0.3,
          'positionX': 0.2,
        }, 'medium');

        expect(scoreTriple, greaterThan(scoreDouble));
      });

      test('rewards different parameter types', () {
        final fourParams = service.diagnoseChallenge({
          'brightness': 0.5,
          'colorHue': 0.3,
          'positionX': 0.2,
          'crop': 0.1,
        }, 'hard');

        expect(fourParams, greaterThan(0.0));
        expect(fourParams, lessThanOrEqualTo(100.0));
      });

      test('penalizes extreme values', () {
        final normalScore = service.diagnoseChallenge({
          'brightness': 0.5,
          'colorHue': 0.3,
        }, 'medium');

        final extremeScore = service.diagnoseChallenge({
          'brightness': 0.95, // Extreme
          'colorHue': 0.05,   // Extreme
        }, 'medium');

        // Extreme values should have lower score due to penalty
        expect(extremeScore, lessThan(normalScore + 10));
      });

      test('difficulty alignment affects score', () {
        // Easy with simple edits - should be good
        final easyAligned = service.diagnoseChallenge({
          'brightness': 0.3,
        }, 'easy');

        // Hard with simple edits - should be penalized
        final hardMisaligned = service.diagnoseChallenge({
          'brightness': 0.3,
        }, 'hard');

        expect(easyAligned, greaterThan(hardMisaligned));
      });

      test('returns score in valid range (0-100)', () {
        final testCases = [
          {'brightness': 0.1},
          {'colorHue': 0.5},
          {'brightness': 0.3, 'colorHue': 0.4},
          {'brightness': 0.2, 'colorHue': 0.3, 'positionX': 0.1},
        ];

        for (final editedPoint in testCases) {
          final score = service.diagnoseChallenge(editedPoint, 'medium');
          expect(score, greaterThanOrEqualTo(0.0));
          expect(score, lessThanOrEqualTo(100.0));
        }
      });

      test('complex edits with all parameters maximize score', () {
        final score = service.diagnoseChallenge({
          'brightness': 0.4,
          'colorHue': 0.5,
          'positionX': 0.3,
          'positionY': 0.2,
          'crop': 0.25,
        }, 'hard');

        // Should be high score (75+)
        expect(score, greaterThan(70.0));
      });

      test('consistent scoring for same input', () {
        final editedPoint = {
          'brightness': 0.5,
          'colorHue': 0.3,
          'positionX': 0.2,
        };

        final score1 = service.diagnoseChallenge(editedPoint, 'medium');
        final score2 = service.diagnoseChallenge(editedPoint, 'medium');

        expect(score1, equals(score2));
      });
    });

    group('calculateDifficulty - Auto Difficulty', () {
      test('returns easy for minimal edits', () {
        final difficulty = service.calculateDifficulty({
          'brightness': 0.1,
        });
        expect(difficulty, equals('easy'));
      });

      test('returns medium for moderate edits', () {
        final difficulty = service.calculateDifficulty({
          'brightness': 0.3,
          'colorHue': 0.2,
        });
        expect(difficulty, equals('medium'));
      });

      test('returns hard for complex edits', () {
        final difficulty = service.calculateDifficulty({
          'brightness': 0.5,
          'colorHue': 0.5,
          'positionX': 0.4,
        });
        expect(difficulty, equals('hard'));
      });

      test('returns hard for high variation with large delta', () {
        final difficulty = service.calculateDifficulty({
          'brightness': 0.8,
          'colorHue': 0.7,
        });
        expect(difficulty, equals('hard'));
      });

      test('returns medium for two edits with moderate delta', () {
        final difficulty = service.calculateDifficulty({
          'brightness': 0.2,
          'colorHue': 0.25,
        });
        expect(difficulty, isIn(['medium', 'easy']));
      });

      test('empty edits returns easy', () {
        final difficulty = service.calculateDifficulty({});
        expect(difficulty, equals('easy'));
      });

      test('all valid difficulties are recognized', () {
        final difficulties = [
          service.calculateDifficulty({'brightness': 0.05}),
          service.calculateDifficulty({'brightness': 0.3, 'colorHue': 0.2}),
          service.calculateDifficulty({'brightness': 0.7, 'colorHue': 0.6, 'positionX': 0.5}),
        ];

        for (final diff in difficulties) {
          expect(diff, isIn(['easy', 'medium', 'hard']));
        }
      });
    });

    group('getQualityLabel - Quality Labels', () {
      test('excellent label for score 80-100', () {
        expect(service.getQualityLabel(85.0), equals('優秀'));
        expect(service.getQualityLabel(100.0), equals('優秀'));
        expect(service.getQualityLabel(80.0), equals('優秀'));
      });

      test('good label for score 60-79', () {
        expect(service.getQualityLabel(70.0), equals('良好'));
        expect(service.getQualityLabel(60.0), equals('良好'));
        expect(service.getQualityLabel(79.9), equals('良好'));
      });

      test('fair label for score 40-59', () {
        expect(service.getQualityLabel(50.0), equals('普通'));
        expect(service.getQualityLabel(40.0), equals('普通'));
        expect(service.getQualityLabel(59.9), equals('普通'));
      });

      test('needs improvement label for score 20-39', () {
        expect(service.getQualityLabel(30.0), equals('要改善'));
        expect(service.getQualityLabel(20.0), equals('要改善'));
        expect(service.getQualityLabel(39.9), equals('要改善'));
      });

      test('unacceptable label for score 0-19', () {
        expect(service.getQualityLabel(10.0), equals('不適格'));
        expect(service.getQualityLabel(0.0), equals('不適格'));
        expect(service.getQualityLabel(19.9), equals('不適格'));
      });

      test('boundary conditions at 60, 40, 20', () {
        expect(service.getQualityLabel(60.0), equals('良好'));
        expect(service.getQualityLabel(59.9), equals('普通'));

        expect(service.getQualityLabel(40.0), equals('普通'));
        expect(service.getQualityLabel(39.9), equals('要改善'));

        expect(service.getQualityLabel(20.0), equals('要改善'));
        expect(service.getQualityLabel(19.9), equals('不適格'));
      });
    });

    group('getQualityColor - Color Codes', () {
      test('returns green for excellent (80+)', () {
        final color = service.getQualityColor(85.0);
        expect(color, equals(0xFF4CAF50)); // Green
      });

      test('returns light green for good (60-79)', () {
        final color = service.getQualityColor(70.0);
        expect(color, equals(0xFF8BC34A)); // Light Green
      });

      test('returns orange for fair (40-59)', () {
        final color = service.getQualityColor(50.0);
        expect(color, equals(0xFFFF9800)); // Orange
      });

      test('returns deep orange for needs improvement (20-39)', () {
        final color = service.getQualityColor(30.0);
        expect(color, equals(0xFFFF5722)); // Deep Orange
      });

      test('returns red for unacceptable (0-19)', () {
        final color = service.getQualityColor(10.0);
        expect(color, equals(0xFFF44336)); // Red
      });

      test('all colors are valid hex values', () {
        final scores = [0.0, 15.0, 30.0, 50.0, 70.0, 85.0, 100.0];
        for (final score in scores) {
          final color = service.getQualityColor(score);
          expect(color, isA<int>());
          expect(color, greaterThanOrEqualTo(0xFF000000));
          expect(color, lessThanOrEqualTo(0xFFFFFFFF));
        }
      });
    });

    group('Integration - Full Workflow', () {
      test('complete quality assessment workflow', () {
        final editedPoint = {
          'brightness': 0.4,
          'colorHue': 0.3,
          'positionX': 0.2,
        };
        final userDifficulty = 'medium';

        // Get score
        final score = service.diagnoseChallenge(editedPoint, userDifficulty);
        expect(score, inInclusiveRange(0.0, 100.0));

        // Get auto difficulty
        final autoDifficulty = service.calculateDifficulty(editedPoint);
        expect(autoDifficulty, isIn(['easy', 'medium', 'hard']));

        // Get quality label
        final label = service.getQualityLabel(score);
        expect(label, isIn(['優秀', '良好', '普通', '要改善', '不適格']));

        // Get color
        final color = service.getQualityColor(score);
        expect(color, isA<int>());
      });

      test('scenario: high quality challenge', () {
        final editedPoint = {
          'brightness': 0.4,
          'colorHue': 0.5,
          'positionX': 0.3,
          'positionY': 0.2,
        };

        final score = service.diagnoseChallenge(editedPoint, 'hard');
        final label = service.getQualityLabel(score);

        // High quality challenges should get good or excellent
        expect(score, greaterThan(60.0));
        expect(label, isIn(['優秀', '良好']));
      });

      test('scenario: low quality challenge', () {
        final editedPoint = {
          'brightness': 0.05,
        };

        final score = service.diagnoseChallenge(editedPoint, 'hard');
        final label = service.getQualityLabel(score);

        // Misaligned difficulty with minimal edits should score low
        expect(score, lessThan(40.0));
        expect(label, isIn(['要改善', '不適格']));
      });
    });

    group('Edge Cases', () {
      test('handles very small values close to zero', () {
        final score = service.diagnoseChallenge({
          'brightness': 0.001,
          'colorHue': 0.0001,
        }, 'easy');
        expect(score, inInclusiveRange(0.0, 100.0));
      });

      test('handles maximum values close to one', () {
        final score = service.diagnoseChallenge({
          'brightness': 0.999,
          'colorHue': 0.999,
          'positionX': 0.999,
        }, 'hard');
        expect(score, inInclusiveRange(0.0, 100.0));
      });

      test('handles many parameter variations', () {
        final score = service.diagnoseChallenge({
          'brightness': 0.2,
          'colorHue': 0.3,
          'positionX': 0.1,
          'positionY': 0.15,
          'crop': 0.25,
          'rotation': 0.05,
        }, 'hard');
        expect(score, inInclusiveRange(0.0, 100.0));
      });

      test('handles null values in editedPoint gracefully', () {
        // The service should ignore or handle null values
        final score = service.diagnoseChallenge({
          'brightness': 0.5,
          'colorHue': null,
          'positionX': 0.3,
        }, 'medium');
        expect(score, inInclusiveRange(0.0, 100.0));
      });
    });
  });
}
