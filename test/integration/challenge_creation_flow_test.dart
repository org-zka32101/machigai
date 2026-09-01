import 'package:flutter_test/flutter_test.dart';
import 'package:machigai/models/index.dart';
import 'package:machigai/services/ai_generation_service.dart';
import 'package:machigai/services/challenge_service.dart';

void main() {
  group('Challenge Creation Flow Integration Tests', () {
    late AIGenerationService aiService;
    late ChallengeService challengeService;

    setUp(() {
      aiService = AIGenerationService();
      challengeService = ChallengeService();
    });

    group('Complete Challenge Workflow', () {
      test('user creates challenge with AI quality feedback', () async {
        // Step 1: User selects template (mocked)
        const templateId = 'template_001';

        // Step 2: User edits video and gets real-time feedback
        final editedPoint = {
          'brightness': 0.4,
          'colorHue': 0.3,
          'positionX': 0.2,
        };
        const userDifficulty = 'medium';

        // Get AI feedback
        final aiScore = aiService.diagnoseChallenge(editedPoint, userDifficulty);
        expect(aiScore, inInclusiveRange(0.0, 100.0));

        // Step 3: Auto-difficulty recommendation
        final suggestedDifficulty = aiService.calculateDifficulty(editedPoint);
        expect(suggestedDifficulty, isIn(['easy', 'medium', 'hard']));

        // Step 4: User accepts suggestion or keeps original
        final finalDifficulty = suggestedDifficulty; // Accept auto suggestion

        // Step 5: User publishes challenge
        final challenge = await challengeService.createChallenge(
          creatorId: 'user_123',
          videoUrl: 'gs://bucket/video_001.mp4',
          editedPoint: editedPoint,
          difficulty: finalDifficulty,
          aiScore: aiScore,
        );

        // Verify challenge created successfully
        expect(challenge.id, isNotEmpty);
        expect(challenge.creatorId, equals('user_123'));
        expect(challenge.difficulty, equals(finalDifficulty));
        expect(challenge.aiScore, equals(aiScore));
        expect(challenge.moderationStatus, equals('pending'));
      });

      test('high quality challenge gets good score and is immediately publishable', () async {
        final editedPoint = {
          'brightness': 0.5,
          'colorHue': 0.5,
          'positionX': 0.4,
          'positionY': 0.3,
          'crop': 0.25,
        };

        final aiScore = aiService.diagnoseChallenge(editedPoint, 'hard');
        final label = aiService.getQualityLabel(aiScore);

        // High quality should meet publication standards
        expect(aiScore, greaterThan(70.0));
        expect(label, isIn(['優秀', '良好']));

        // Publish challenge
        final challenge = await challengeService.createChallenge(
          creatorId: 'user_456',
          videoUrl: 'gs://bucket/video_002.mp4',
          editedPoint: editedPoint,
          difficulty: 'hard',
          aiScore: aiScore,
        );

        // Challenge should be creatable (would need moderation)
        expect(challenge.aiScore, equals(aiScore));
      });

      test('low quality challenge gets improvement suggestions', () async {
        final editedPoint = {'brightness': 0.05};

        final aiScore = aiService.diagnoseChallenge(editedPoint, 'hard');
        final label = aiService.getQualityLabel(aiScore);
        final difficulty = aiService.calculateDifficulty(editedPoint);

        // Low quality should trigger suggestions
        expect(aiScore, lessThan(40.0));
        expect(label, isIn(['要改善', '不適格']));
        expect(difficulty, equals('easy')); // Difficulty corrected

        // User can still publish but gets warning
        final challenge = await challengeService.createChallenge(
          creatorId: 'user_789',
          videoUrl: 'gs://bucket/video_003.mp4',
          editedPoint: editedPoint,
          difficulty: difficulty,
          aiScore: aiScore,
        );

        // Challenge stores low score for later moderation
        expect(challenge.aiScore, equals(aiScore));
        expect(challenge.aiScore, lessThan(40.0));
      });
    });

    group('Difficulty Alignment Scenarios', () {
      test('easy difficulty with simple edits (aligned)', () async {
        final editedPoint = {'brightness': 0.2};

        final aiScore = aiService.diagnoseChallenge(editedPoint, 'easy');
        final suggestedDifficulty = aiService.calculateDifficulty(editedPoint);

        // Should be aligned and get decent score
        expect(suggestedDifficulty, equals('easy'));
        expect(aiScore, greaterThan(40.0));
      });

      test('medium difficulty with moderate edits (aligned)', () async {
        final editedPoint = {
          'brightness': 0.3,
          'colorHue': 0.25,
        };

        final aiScore = aiService.diagnoseChallenge(editedPoint, 'medium');
        final suggestedDifficulty = aiService.calculateDifficulty(editedPoint);

        // Should be aligned
        expect(suggestedDifficulty, isIn(['medium', 'easy']));
        expect(aiScore, greaterThan(45.0));
      });

      test('hard difficulty with complex edits (aligned)', () async {
        final editedPoint = {
          'brightness': 0.5,
          'colorHue': 0.4,
          'positionX': 0.35,
          'positionY': 0.2,
        };

        final aiScore = aiService.diagnoseChallenge(editedPoint, 'hard');
        final suggestedDifficulty = aiService.calculateDifficulty(editedPoint);

        // Should be aligned and get good score
        expect(suggestedDifficulty, equals('hard'));
        expect(aiScore, greaterThan(60.0));
      });

      test('hard difficulty with simple edits (misaligned)', () async {
        final editedPoint = {'brightness': 0.1};

        final aiScore = aiService.diagnoseChallenge(editedPoint, 'hard');
        final suggestedDifficulty = aiService.calculateDifficulty(editedPoint);

        // Should be misaligned and get lower score
        expect(suggestedDifficulty, equals('easy'));
        expect(aiScore, lessThan(40.0));

        // User gets suggestion to use easy instead
        final correctedScore = aiService.diagnoseChallenge(editedPoint, 'easy');
        expect(correctedScore, greaterThan(aiScore));
      });
    });

    group('Quality Score Progression', () {
      test('score increases as edits become more complex', () async {
        final score1 = aiService.diagnoseChallenge({'brightness': 0.2}, 'easy');

        final score2 = aiService.diagnoseChallenge({
          'brightness': 0.3,
          'colorHue': 0.2,
        }, 'medium');

        final score3 = aiService.diagnoseChallenge({
          'brightness': 0.4,
          'colorHue': 0.3,
          'positionX': 0.2,
        }, 'hard');

        expect(score2, greaterThan(score1));
        expect(score3, greaterThan(score2));
      });

      test('score consistency across multiple calculations', () async {
        final editedPoint = {
          'brightness': 0.4,
          'colorHue': 0.3,
          'positionX': 0.2,
        };

        final score1 = aiService.diagnoseChallenge(editedPoint, 'medium');
        final score2 = aiService.diagnoseChallenge(editedPoint, 'medium');
        final score3 = aiService.diagnoseChallenge(editedPoint, 'medium');

        // Scores should be identical (deterministic)
        expect(score1, equals(score2));
        expect(score2, equals(score3));
      });
    });

    group('Challenge Persistence', () {
      test('created challenge contains all required fields', () async {
        final editedPoint = {'brightness': 0.5, 'colorHue': 0.3};
        final aiScore = aiService.diagnoseChallenge(editedPoint, 'medium');

        final challenge = await challengeService.createChallenge(
          creatorId: 'test_user',
          videoUrl: 'gs://bucket/test.mp4',
          editedPoint: editedPoint,
          difficulty: 'medium',
          aiScore: aiScore,
        );

        // Verify all fields
        expect(challenge.id, isNotEmpty);
        expect(challenge.creatorId, equals('test_user'));
        expect(challenge.videoUrl, equals('gs://bucket/test.mp4'));
        expect(challenge.editedPoint, equals(editedPoint));
        expect(challenge.difficulty, equals('medium'));
        expect(challenge.aiScore, equals(aiScore));
        expect(challenge.moderationStatus, equals('pending'));
        expect(challenge.shareToken, isNotEmpty);
        expect(challenge.createdAt, isNotNull);
        expect(challenge.solveCount, equals(0));
      });

      test('can retrieve created challenge by ID', () async {
        final editedPoint = {'brightness': 0.4};
        final aiScore = aiService.diagnoseChallenge(editedPoint, 'easy');

        final created = await challengeService.createChallenge(
          creatorId: 'test_user_2',
          videoUrl: 'gs://bucket/test2.mp4',
          editedPoint: editedPoint,
          difficulty: 'easy',
          aiScore: aiScore,
        );

        // Attempt to retrieve
        final retrieved = await challengeService.getChallenge(created.id);

        expect(retrieved, isNotNull);
        expect(retrieved?.id, equals(created.id));
        expect(retrieved?.aiScore, equals(aiScore));
      });

      test('aiScore is properly persisted and retrieved', () async {
        final editedPoint = {
          'brightness': 0.6,
          'colorHue': 0.5,
          'positionX': 0.3,
        };
        final aiScore = aiService.diagnoseChallenge(editedPoint, 'hard');

        final challenge = await challengeService.createChallenge(
          creatorId: 'test_persistence',
          videoUrl: 'gs://bucket/persist.mp4',
          editedPoint: editedPoint,
          difficulty: 'hard',
          aiScore: aiScore,
        );

        // Verify aiScore is in the model
        expect(challenge.aiScore, equals(aiScore));

        // Verify it would be persisted (would need real Firebase for full test)
        final model = challenge;
        final firestoreData = model.toFirestore();
        expect(firestoreData['aiScore'], equals(aiScore));
      });
    });

    group('Edge Cases', () {
      test('can create challenge with null aiScore (backward compatibility)', () async {
        final challenge = await challengeService.createChallenge(
          creatorId: 'legacy_user',
          videoUrl: 'gs://bucket/legacy.mp4',
          editedPoint: {'brightness': 0.3},
          difficulty: 'medium',
          // No aiScore provided
        );

        expect(challenge.aiScore, isNull);
      });

      test('handles maximum complexity challenges', () async {
        final editedPoint = {
          'brightness': 0.7,
          'colorHue': 0.6,
          'positionX': 0.5,
          'positionY': 0.4,
          'crop': 0.3,
          'rotation': 0.2,
          'saturation': 0.25,
        };

        final aiScore = aiService.diagnoseChallenge(editedPoint, 'hard');
        expect(aiScore, inInclusiveRange(0.0, 100.0));

        final challenge = await challengeService.createChallenge(
          creatorId: 'power_user',
          videoUrl: 'gs://bucket/complex.mp4',
          editedPoint: editedPoint,
          difficulty: 'hard',
          aiScore: aiScore,
        );

        expect(challenge.id, isNotEmpty);
      });

      test('handles minimal edits gracefully', () async {
        final editedPoint = {'brightness': 0.01};

        final aiScore = aiService.diagnoseChallenge(editedPoint, 'easy');
        expect(aiScore, inInclusiveRange(0.0, 100.0));

        final challenge = await challengeService.createChallenge(
          creatorId: 'minimal_user',
          videoUrl: 'gs://bucket/minimal.mp4',
          editedPoint: editedPoint,
          difficulty: 'easy',
          aiScore: aiScore,
        );

        expect(challenge.aiScore, equals(aiScore));
      });
    });

    group('Quality Feedback Loop', () {
      test('user can iterate on edits based on feedback', () async {
        // First attempt: basic edits
        var editedPoint = {'brightness': 0.2};
        var aiScore = aiService.diagnoseChallenge(editedPoint, 'medium');
        var label = aiService.getQualityLabel(aiScore);

        expect(label, isIn(['普通', '要改善', '不適格']));

        // User sees suggestion to add more edits
        // Second attempt: add more parameter variations
        editedPoint = {
          'brightness': 0.3,
          'colorHue': 0.25,
          'positionX': 0.15,
        };
        aiScore = aiService.diagnoseChallenge(editedPoint, 'medium');
        label = aiService.getQualityLabel(aiScore);

        // Score should improve
        expect(label, isIn(['良好', '優秀']));

        // User publishes with improved score
        final challenge = await challengeService.createChallenge(
          creatorId: 'iterative_user',
          videoUrl: 'gs://bucket/iterated.mp4',
          editedPoint: editedPoint,
          difficulty: 'medium',
          aiScore: aiScore,
        );

        expect(challenge.aiScore, greaterThan(50.0));
      });
    });
  });
}
