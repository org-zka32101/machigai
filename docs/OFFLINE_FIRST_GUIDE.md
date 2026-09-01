# 🌐 Offline-First Architecture Guide

**Phase 6 Session 1** - Comprehensive offline support and intelligent data prefetching

---

## 📋 Overview

This guide explains how to implement and use the offline-first architecture in the Machigai app. The system enables seamless offline workflows while automatically syncing data when connectivity is restored.

**Key Capabilities**:
- ✅ Full offline functionality with local persistence
- ✅ Automatic background synchronization
- ✅ Intelligent data prefetching
- ✅ Network-aware optimization
- ✅ Conflict-free operation queuing
- ✅ Comprehensive statistics tracking

---

## 🎯 Core Components

### 1. LocalStorageService

Handles all local data persistence using shared_preferences.

#### Initialization

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local storage
  final storage = LocalStorageService();
  await storage.initialize();
  
  runApp(const ProviderScope(child: MyApp()));
}
```

#### Managing Drafts (Offline Creation)

```dart
// Save a challenge draft while offline
Future<void> saveChallengeOffline(Map<String, dynamic> challengeData) async {
  final storage = LocalStorageService();
  
  await storage.saveDraft('challenge_${DateTime.now().millisecondsSinceEpoch}', {
    'title': challengeData['title'],
    'description': challengeData['description'],
    'difficulty': challengeData['difficulty'],
    'correctAnswers': challengeData['correctAnswers'],
  });
  
  // Show user feedback
  print('Challenge draft saved locally');
}

// Retrieve drafts when user re-opens editing screen
Future<List<Map<String, dynamic>>> loadDrafts() async {
  final storage = LocalStorageService();
  final drafts = storage.getAllDrafts();
  return drafts.values.toList();
}

// Delete a draft (user decided not to continue)
Future<void> discardDraft(String draftId) async {
  final storage = LocalStorageService();
  await storage.deleteDraft(draftId);
}
```

#### Caching User Preferences

```dart
// Save user's preferred difficulty
Future<void> setPreferredDifficulty(String difficulty) async {
  final storage = LocalStorageService();
  await storage.setPreferredDifficulty(difficulty);
}

// Retrieve saved preference
String? getDifficulty() {
  final storage = LocalStorageService();
  return storage.getPreferredDifficulty();
}

// Track recently viewed challenges
Future<void> recordChallengeView(String challengeId) async {
  final storage = LocalStorageService();
  await storage.saveRecentChallenge(challengeId);
}

// Get recent challenges (for offline browsing)
List<String> getRecentChallenges() {
  final storage = LocalStorageService();
  return storage.getRecentChallenges(limit: 20);
}
```

---

### 2. SyncManager

Orchestrates background synchronization of queued operations.

#### Initialization

```dart
void main() async {
  // Initialize sync manager
  final syncManager = SyncManager();
  await syncManager.initialize();
  
  // Register sync callbacks for each operation type
  syncManager.registerSyncCallback(
    SyncOperationType.createChallenge,
    (operation) async {
      try {
        final result = await challengeService.createChallenge(
          operation.data['title'],
          operation.data['description'],
          operation.data['difficulty'],
        );
        return result != null;
      } catch (e) {
        print('Error syncing create challenge: $e');
        return false;
      }
    },
  );
  
  syncManager.registerSyncCallback(
    SyncOperationType.updateChallenge,
    (operation) async {
      try {
        await challengeService.updateChallenge(
          operation.data['id'],
          operation.data,
        );
        return true;
      } catch (e) {
        print('Error syncing update challenge: $e');
        return false;
      }
    },
  );
  
  syncManager.registerSyncCallback(
    SyncOperationType.deleteChallenge,
    (operation) async {
      try {
        await challengeService.deleteChallenge(operation.data['id']);
        return true;
      } catch (e) {
        print('Error syncing delete challenge: $e');
        return false;
      }
    },
  );
  
  syncManager.registerSyncCallback(
    SyncOperationType.recordAttempt,
    (operation) async {
      try {
        await attemptService.recordAttempt(
          operation.data['challengeId'],
          operation.data['userId'],
          operation.data['isCorrect'],
        );
        return true;
      } catch (e) {
        print('Error syncing attempt: $e');
        return false;
      }
    },
  );
  
  syncManager.registerSyncCallback(
    SyncOperationType.updateUserProfile,
    (operation) async {
      try {
        await userService.updateProfile(
          operation.data['userId'],
          operation.data,
        );
        return true;
      } catch (e) {
        print('Error syncing profile update: $e');
        return false;
      }
    },
  );
  
  runApp(const ProviderScope(child: MyApp()));
}
```

#### Queuing Operations While Offline

```dart
// When a user creates a challenge while offline
Future<bool> createChallengeOffline(
  String title,
  String description,
  String difficulty,
) async {
  final syncManager = SyncManager();
  
  if (!syncManager.isOnline) {
    // Queue the operation for later sync
    return await syncManager.queueOperation(
      operationId: 'create_${DateTime.now().millisecondsSinceEpoch}',
      type: SyncOperationType.createChallenge,
      data: {
        'title': title,
        'description': description,
        'difficulty': difficulty,
      },
    );
  } else {
    // Perform immediately if online
    try {
      final result = await challengeService.createChallenge(
        title,
        description,
        difficulty,
      );
      return result != null;
    } catch (e) {
      // Fall back to queuing if immediate sync fails
      return await syncManager.queueOperation(
        operationId: 'create_${DateTime.now().millisecondsSinceEpoch}',
        type: SyncOperationType.createChallenge,
        data: {
          'title': title,
          'description': description,
          'difficulty': difficulty,
        },
      );
    }
  }
}

// Monitor sync status
void watchSyncStatus() {
  final syncManager = SyncManager();
  
  // Check if currently syncing
  if (syncManager.isSyncing) {
    print('Currently syncing...');
  }
  
  // Check pending operations
  int pending = syncManager.getPendingOperationsCount();
  print('Pending operations: $pending');
  
  // Get detailed stats
  var stats = syncManager.getSyncStats();
  print('Online: ${stats['isOnline']}');
  print('Synced: ${stats['totalSynced']}');
  print('Failed: ${stats['totalFailed']}');
  print('Time since last sync: ${stats['timeSinceLastSync']} minutes');
}
```

#### Monitoring Sync Progress

```dart
// Show sync status to user
Widget buildSyncStatusWidget() {
  final syncManager = SyncManager();
  
  return StreamBuilder<bool>(
    stream: Stream.periodic(
      Duration(seconds: 2),
      (_) => syncManager.isOnline,
    ),
    builder: (context, snapshot) {
      final isOnline = snapshot.data ?? true;
      final pending = syncManager.getPendingOperationsCount();
      
      if (pending > 0) {
        return Column(
          children: [
            Icon(
              isOnline ? Icons.cloud_upload : Icons.cloud_off,
              color: isOnline ? Colors.green : Colors.orange,
            ),
            Text('$pending pending operations'),
            if (isOnline)
              Text('Syncing...', style: TextStyle(color: Colors.blue)),
          ],
        );
      }
      
      return Icon(
        Icons.cloud_done,
        color: Colors.green,
      );
    },
  );
}
```

---

### 3. PrefetchService

Intelligently prefetches data to reduce perceived load times.

#### Basic Prefetching

```dart
// Prefetch challenges when user opens challenges screen
Future<void> prefetchChallenges() async {
  final prefetch = PrefetchService();
  
  int prefetched = await prefetch.prefetchNextChallenges(
    userId,
    difficulty: 'medium',
    limit: 10,
  );
  
  print('Prefetched $prefetched challenges');
}

// Prefetch rankings when user opens ranking screen
Future<void> prefetchRankings() async {
  final prefetch = PrefetchService();
  
  bool success = await prefetch.prefetchRankings(
    period: 'daily',
    limit: 50,
  );
  
  print('Rankings prefetch: ${success ? 'success' : 'failed'}');
}

// Prefetch user profile
Future<void> prefetchProfile(String userId) async {
  final prefetch = PrefetchService();
  
  bool success = await prefetch.prefetchUserProfile(userId);
  print('Profile prefetch: ${success ? 'success' : 'failed'}');
}
```

#### Behavior-Based Prefetching

```dart
// Analyze user behavior and prefetch accordingly
Future<void> intelligentPrefetch(String userId) async {
  final prefetch = PrefetchService();
  final storage = LocalStorageService();
  
  // Gather user behavior data
  final pattern = UserBehaviorPattern(
    userId: userId,
    challengesViewedToday: 5,
    averageChallengesPerSession: 8,
    preferredDifficulty: storage.getPreferredDifficulty() ?? 'medium',
    lastActiveTime: DateTime.now().subtract(Duration(minutes: 15)),
    recentChallengeIds: storage.getRecentChallenges(limit: 5),
  );
  
  // Get recommended prefetch actions
  final recommendations = prefetch.getRecommendedPrefetchActions(pattern);
  
  // Execute recommendations
  for (final action in recommendations) {
    if (action.startsWith('challenges_')) {
      final difficulty = action.split('_')[1];
      await prefetch.prefetchNextChallenges(
        userId,
        difficulty: difficulty,
        limit: 5,
      );
    } else if (action == 'ranking') {
      await prefetch.prefetchRankings();
    }
  }
}

// Predict next user action
String predictNextAction(UserBehaviorPattern pattern) {
  final prefetch = PrefetchService();
  return prefetch.predictNextUserAction(pattern);
  // Returns: 'challenges', 'ranking', or 'profile'
}
```

#### Network-Aware Prefetching

```dart
// Initialize prefetch strategy based on network conditions
Future<void> initializePrefetchStrategy(
  bool isHighBandwidth,
  bool isMetered,
) async {
  final prefetch = PrefetchService();
  
  // Customize strategy based on network
  final strategy = PrefetchStrategy(
    maxPrefetchItems: isHighBandwidth && !isMetered ? 10 : 5,
    prefetchTimeout: Duration(seconds: isHighBandwidth ? 5 : 3),
    enableSmartPrefetch: !isMetered,
    enableRankingPrefetch: isHighBandwidth && !isMetered,
    enableRelatedChallenges: !isMetered,
  );
  
  prefetch.initialize(strategy: strategy);
}

// Adapt prefetch strategy when network conditions change
void onConnectivityChanged(ConnectivityResult result) {
  final prefetch = PrefetchService();
  
  final isHighBandwidth = result != ConnectivityResult.mobile;
  final isMetered = result == ConnectivityResult.mobile;
  
  prefetch.optimizeForNetworkConditions(
    isHighBandwidth: isHighBandwidth,
    isMetered: isMetered,
  );
}
```

#### Screen-Based Prefetching

```dart
// Prefetch data when navigating to a specific screen
Future<void> prefetchForScreen(String screenName) async {
  final prefetch = PrefetchService();
  
  switch (screenName) {
    case 'challenges':
      await prefetch.prefetchScreenData('challenges');
      break;
    case 'ranking':
      await prefetch.prefetchScreenData('ranking');
      break;
    case 'profile':
      await prefetch.prefetchScreenData('profile');
      break;
  }
}
```

#### Monitoring Prefetch Statistics

```dart
// Check prefetch performance
void checkPrefetchStats() {
  final prefetch = PrefetchService();
  
  var stats = prefetch.getPrefetchStats();
  
  print('Successful prefetches: ${stats['successful']}');
  print('Failed prefetches: ${stats['failed']}');
  print('Success rate: ${stats['successRate']}%');
  print('Recent prefetches: ${stats['recentPrefetches']}');
  
  if (stats['lastPrefetchTime'] != null) {
    print('Last prefetch: ${stats['lastPrefetchTime']}');
  }
}
```

---

## 🔄 Complete Workflow Example

### Scenario: User Creates Challenge While Offline

```
1. User opens challenge creation screen
   ↓
2. Prefetch service predicts user might create challenges
   ↓
3. User enters challenge data and taps "Create"
   ↓
4. App detects no network connection
   ↓
5. App saves draft to LocalStorageService
   ↓
6. App queues create operation in SyncManager
   ↓
7. Show success message: "Saved offline - will sync when online"
   ↓
8. (Later) Connectivity restored
   ↓
9. SyncManager automatically triggers sync
   ↓
10. Sync callback executes queued operation
   ↓
11. Challenge created on Firestore
   ↓
12. Cache invalidated and refreshed
   ↓
13. Show notification: "Challenge synced successfully"
```

### Implementation

```dart
class CreateChallengeController extends StateNotifier<AsyncValue<void>> {
  final SyncManager _syncManager;
  final LocalStorageService _storage;
  final ChallengeService _challengeService;
  
  Future<void> createChallenge(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    
    try {
      if (_syncManager.isOnline) {
        // Online: create immediately
        await _challengeService.createChallenge(
          data['title'],
          data['description'],
          data['difficulty'],
        );
        state = const AsyncValue.data(null);
      } else {
        // Offline: queue operation
        await _storage.saveDraft('draft_${DateTime.now().millisecondsSinceEpoch}', data);
        await _syncManager.queueOperation(
          operationId: 'create_${DateTime.now().millisecondsSinceEpoch}',
          type: SyncOperationType.createChallenge,
          data: data,
        );
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      // Fallback to offline queue if online creation fails
      await _storage.saveDraft('draft_${DateTime.now().millisecondsSinceEpoch}', data);
      await _syncManager.queueOperation(
        operationId: 'create_${DateTime.now().millisecondsSinceEpoch}',
        type: SyncOperationType.createChallenge,
        data: data,
      );
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
```

---

## 📊 Storage Management

### Monitor Storage Usage

```dart
// Check how much storage is being used
void checkStorageUsage() {
  final storage = LocalStorageService();
  
  var stats = storage.getStorageStats();
  
  print('Drafts stored: ${stats['totalDrafts']}');
  print('Sync queue size: ${stats['syncQueueSize']}');
  print('Recent challenges: ${stats['recentChallengesCount']}');
  
  // Clean up if necessary
  if (stats['totalDrafts'] > 50) {
    print('Warning: Too many drafts stored');
  }
}

// Clear storage when needed
Future<void> clearLocalStorage() async {
  final storage = LocalStorageService();
  
  // Option 1: Clear only drafts
  await storage.clearAllDrafts();
  
  // Option 2: Clear everything
  await storage.clearAll();
}
```

---

## 🎯 Best Practices

### DO ✅

- ✅ Initialize storage and sync manager in main()
- ✅ Register all sync callbacks before app startup
- ✅ Queue operations immediately when offline
- ✅ Use prefetch strategically (not excessively)
- ✅ Monitor sync statistics periodically
- ✅ Adapt prefetch strategy to network conditions
- ✅ Show user feedback about offline status
- ✅ Clear expired data periodically

### DON'T ❌

- ❌ Create new LocalStorageService instances repeatedly
- ❌ Forget to dispose SyncManager resources
- ❌ Prefetch data unnecessarily (wastes bandwidth)
- ❌ Ignore network conditions when prefetching
- ❌ Cache sensitive user data locally
- ❌ Store unencrypted passwords or tokens
- ❌ Accumulate unlimited draft data
- ❌ Forget to handle sync errors

---

## 🔍 Debugging

### Enable Logging

```dart
// Add logging to sync operations
void setupSyncLogging() {
  final syncManager = SyncManager();
  
  // Monitor sync state
  Timer.periodic(Duration(seconds: 5), (_) {
    print('Online: ${syncManager.isOnline}');
    print('Syncing: ${syncManager.isSyncing}');
    print('Pending: ${syncManager.getPendingOperationsCount()}');
  });
}
```

### Inspect Stored Data

```dart
// Debug: Check what's stored locally
void debugStorageContents() {
  final storage = LocalStorageService();
  
  // Check drafts
  final drafts = storage.getAllDrafts();
  print('Drafts:');
  drafts.forEach((id, draft) {
    print('  $id: ${draft['title']} (${draft['difficulty']})');
  });
  
  // Check sync queue
  final queue = storage.getSyncQueue();
  print('Sync queue:');
  queue.forEach((id, op) {
    print('  $id: ${op['type']} (retry: ${op['retryCount']})');
  });
  
  // Check statistics
  final stats = storage.getStorageStats();
  print('Storage stats: $stats');
}
```

---

## 🚀 Advanced Topics

### Handling Offline Conflicts

When multiple edits occur offline, implement conflict resolution:

```dart
// Example: Last-write-wins strategy
Future<bool> syncWithConflictResolution(
  PendingSyncOperation operation,
) async {
  try {
    final existing = await challengeService.getChallenge(
      operation.data['id'],
    );
    
    if (existing != null &&
        existing.lastModified.isAfter(
          DateTime.parse(operation.data['timestamp']),
        )) {
      // Server version is newer - discard offline change
      print('Server version is newer, skipping sync');
      return false;
    }
    
    // Proceed with sync
    await challengeService.updateChallenge(
      operation.data['id'],
      operation.data,
    );
    return true;
  } catch (e) {
    return false;
  }
}
```

### Selective Sync

Allow users to control sync behavior:

```dart
// User configuration for sync
class SyncPreferences {
  bool autoSync = true;
  bool syncOnMetered = false;
  bool syncOnWiFiOnly = false;
  Duration syncInterval = Duration(minutes: 5);
}

// Apply preferences
void applySyncPreferences(SyncPreferences prefs) {
  final syncManager = SyncManager();
  
  if (prefs.syncOnWiFiOnly) {
    // Only sync on high bandwidth connections
    syncManager.optimizeForNetworkConditions(
      isHighBandwidth: true,
      isMetered: false,
    );
  }
}
```

---

## 📚 References

- **LocalStorageService**: Local data persistence
- **SyncManager**: Background synchronization
- **PrefetchService**: Intelligent prefetching
- **CacheService**: In-memory caching (Phase 5)
- **ChallengeService**: Challenge operations

---

**Status**: ✅ **Complete - Ready for implementation**

_For questions or issues, refer to the service files or implementation examples above._
