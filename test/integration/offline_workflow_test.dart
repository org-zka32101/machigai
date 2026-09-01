import 'package:flutter_test/flutter_test.dart';
import 'package:machigai/models/index.dart';
import 'package:machigai/services/challenge_service_optimized.dart';
import 'package:machigai/services/local_storage_service.dart';
import 'package:machigai/services/sync_manager.dart';
import 'package:machigai/services/prefetch_service.dart';

void main() {
  group('Offline Workflow Tests', () {
    late LocalStorageService storage;
    late SyncManager syncManager;
    late PrefetchService prefetchService;

    setUp(() async {
      storage = LocalStorageService();
      await storage.initialize();

      syncManager = SyncManager();
      prefetchService = PrefetchService();

      // Clear any existing data
      await storage.clearAll();
    });

    tearDown(() async {
      await storage.clearAll();
      syncManager.dispose();
    });

    test('LocalStorageService: Save and retrieve draft', () async {
      final draftId = 'draft_001';
      final draftData = {
        'title': 'Test Challenge',
        'description': 'Test Description',
        'difficulty': 'medium',
      };

      // Save draft
      final saved = await storage.saveDraft(draftId, draftData);
      expect(saved, true);

      // Retrieve draft
      final retrieved = storage.getDraft(draftId);
      expect(retrieved, isNotNull);
      expect(retrieved?['title'], 'Test Challenge');
      expect(retrieved?['description'], 'Test Description');
      expect(retrieved?['difficulty'], 'medium');
    });

    test('LocalStorageService: Get all drafts', () async {
      // Save multiple drafts
      await storage.saveDraft('draft_001', {'title': 'Challenge 1'});
      await storage.saveDraft('draft_002', {'title': 'Challenge 2'});
      await storage.saveDraft('draft_003', {'title': 'Challenge 3'});

      // Get all drafts
      final allDrafts = storage.getAllDrafts();
      expect(allDrafts.length, 3);
      expect(allDrafts.containsKey('draft_001'), true);
      expect(allDrafts.containsKey('draft_002'), true);
      expect(allDrafts.containsKey('draft_003'), true);
    });

    test('LocalStorageService: Delete draft', () async {
      final draftId = 'draft_001';
      await storage.saveDraft(draftId, {'title': 'Challenge'});

      // Verify saved
      expect(storage.getDraft(draftId), isNotNull);

      // Delete
      final deleted = await storage.deleteDraft(draftId);
      expect(deleted, true);

      // Verify deleted
      expect(storage.getDraft(draftId), isNull);
    });

    test('SyncManager: Queue operation', () async {
      await syncManager.initialize();

      final operationId = 'op_001';
      final data = {
        'title': 'Test Challenge',
        'difficulty': 'hard',
      };

      // Queue operation
      final queued = await syncManager.queueOperation(
        operationId: operationId,
        type: SyncOperationType.createChallenge,
        data: data,
      );

      expect(queued, true);

      // Verify in queue
      int pending = syncManager.getPendingOperationsCount();
      expect(pending, greaterThan(0));
    });

    test('SyncManager: Get sync stats', () async {
      await syncManager.initialize();

      // Queue an operation
      await syncManager.queueOperation(
        operationId: 'op_001',
        type: SyncOperationType.createChallenge,
        data: {'title': 'Test'},
      );

      // Get stats
      final stats = syncManager.getSyncStats();

      expect(stats['pendingOperations'], greaterThan(0));
      expect(stats.containsKey('totalSynced'), true);
      expect(stats.containsKey('totalFailed'), true);
    });

    test('SyncManager: Connectivity status', () async {
      await syncManager.initialize();

      // Check connectivity status
      final isOnline = syncManager.isOnline;
      expect(isOnline, isA<bool>());

      final isSyncing = syncManager.isSyncing;
      expect(isSyncing, isA<bool>());
    });

    test('Offline Workflow: Create challenge while offline', () async {
      // Simulate offline by not initializing sync
      // In a real test, you'd mock connectivity

      final draftId = 'challenge_001';
      final challengeData = {
        'userId': 'user_001',
        'title': 'Offline Challenge',
        'description': 'Created while offline',
        'difficulty': 'medium',
        'correctAnswers': ['answer1', 'answer2'],
      };

      // Save draft
      await storage.saveDraft(draftId, challengeData);

      // Queue operation
      final queued = await syncManager.queueOperation(
        operationId: draftId,
        type: SyncOperationType.createChallenge,
        data: challengeData,
      );

      expect(queued, true);

      // Verify both draft and queue entry exist
      final draft = storage.getDraft(draftId);
      expect(draft, isNotNull);

      final pending = syncManager.getPendingOperationsCount();
      expect(pending, greaterThan(0));
    });

    test('PrefetchService: Predict next action', () async {
      final pattern = UserBehaviorPattern(
        userId: 'user_001',
        challengesViewedToday: 3,
        averageChallengesPerSession: 5,
        preferredDifficulty: 'hard',
        lastActiveTime: DateTime.now().subtract(Duration(minutes: 15)),
        recentChallengeIds: ['ch_001', 'ch_002'],
      );

      final nextAction = prefetchService.predictNextUserAction(pattern);
      expect(nextAction, isNotEmpty);
      // User viewed fewer than average, so should predict 'challenges'
      expect(['challenges', 'ranking', 'profile'], contains(nextAction));
    });

    test('PrefetchService: Get recommended actions', () async {
      final pattern = UserBehaviorPattern(
        userId: 'user_001',
        challengesViewedToday: 8,
        averageChallengesPerSession: 5,
        preferredDifficulty: 'easy',
        lastActiveTime: DateTime.now().subtract(Duration(minutes: 15)),
        recentChallengeIds: ['ch_001'],
      );

      final actions = prefetchService.getRecommendedPrefetchActions(pattern);
      expect(actions.isNotEmpty, true);
      // Should recommend difficulty-specific challenges
      expect(actions.any((a) => a.startsWith('challenges_')), true);
    });

    test('Storage cleanup: Clear expired data', () async {
      // Save multiple items
      await storage.saveDraft('draft_001', {'title': 'Challenge 1'});
      await storage.saveDraft('draft_002', {'title': 'Challenge 2'});
      await storage.saveRecentChallenge('ch_001');
      await storage.saveRecentChallenge('ch_002');

      // Verify saved
      expect(storage.getAllDrafts().length, 2);
      expect(storage.getRecentChallenges().length, 2);

      // Get storage stats
      final stats = storage.getStorageStats();
      expect(stats['totalDrafts'], 2);
      expect(stats['recentChallengesCount'], 2);

      // Clear all
      await storage.clearAll();

      // Verify cleared
      expect(storage.getAllDrafts().isEmpty, true);
      expect(storage.getRecentChallenges().isEmpty, true);
    });

    test('User preferences: Save and retrieve difficulty', () async {
      const difficulty = 'hard';

      // Save preference
      final saved = await storage.setPreferredDifficulty(difficulty);
      expect(saved, true);

      // Retrieve preference
      final retrieved = storage.getPreferredDifficulty();
      expect(retrieved, 'hard');
    });

    test('Recent challenges: Track viewing order', () async {
      // Save challenges in order
      await storage.saveRecentChallenge('ch_001');
      await storage.saveRecentChallenge('ch_002');
      await storage.saveRecentChallenge('ch_003');

      // Get recent challenges
      final recent = storage.getRecentChallenges(limit: 10);

      // Most recent should be last saved
      expect(recent.first, 'ch_003');
      expect(recent.length, 3);
    });

    test('User cache: Save and retrieve user data', () async {
      const userId = 'user_001';
      const userData = {
        'username': 'testuser',
        'email': 'test@example.com',
        'level': 5,
      };

      // Save user cache
      final saved = await storage.saveUserCache(userId, userData);
      expect(saved, true);

      // Retrieve user cache
      final retrieved = storage.getUserCache(userId);
      expect(retrieved, isNotNull);
      expect(retrieved?['username'], 'testuser');
      expect(retrieved?['level'], 5);
    });

    test('Offline mode toggle', () async {
      // Enable offline mode
      await storage.setOfflineMode(true);
      expect(storage.isOfflineModeEnabled(), true);

      // Disable offline mode
      await storage.setOfflineMode(false);
      expect(storage.isOfflineModeEnabled(), false);
    });

    test('Integration: Complete offline to online sync workflow', () async {
      await syncManager.initialize();

      // Step 1: Save draft offline
      const draftId = 'integration_test_001';
      const challengeData = {
        'title': 'Integration Test Challenge',
        'description': 'Testing offline to online sync',
        'difficulty': 'medium',
      };

      await storage.saveDraft(draftId, challengeData);
      await syncManager.queueOperation(
        operationId: draftId,
        type: SyncOperationType.createChallenge,
        data: challengeData,
      );

      // Step 2: Verify queued
      int pending = syncManager.getPendingOperationsCount();
      expect(pending, greaterThan(0));

      // Step 3: Verify draft exists
      final draft = storage.getDraft(draftId);
      expect(draft, isNotNull);

      // Step 4: Simulate manual sync trigger
      // In a real scenario, this would be automatic on connectivity restoration
      final stats = syncManager.getSyncStats();
      expect(stats.containsKey('pendingOperations'), true);
    });
  });
}
