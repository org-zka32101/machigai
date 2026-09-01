import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:machigai/models/index.dart';
import 'package:machigai/services/challenge_service_optimized.dart';
import 'package:machigai/services/local_storage_service.dart';
import 'package:machigai/services/sync_manager.dart';

/// Challenge creation state
class ChallengeCreationState {
  final bool isLoading;
  final bool isOffline;
  final bool isSyncing;
  final String? error;
  final String? successMessage;
  final UserGeneratedChallenge? createdChallenge;
  final List<String> draftIds;

  ChallengeCreationState({
    this.isLoading = false,
    this.isOffline = false,
    this.isSyncing = false,
    this.error,
    this.successMessage,
    this.createdChallenge,
    this.draftIds = const [],
  });

  ChallengeCreationState copyWith({
    bool? isLoading,
    bool? isOffline,
    bool? isSyncing,
    String? error,
    String? successMessage,
    UserGeneratedChallenge? createdChallenge,
    List<String>? draftIds,
  }) {
    return ChallengeCreationState(
      isLoading: isLoading ?? this.isLoading,
      isOffline: isOffline ?? this.isOffline,
      isSyncing: isSyncing ?? this.isSyncing,
      error: error,
      successMessage: successMessage,
      createdChallenge: createdChallenge ?? this.createdChallenge,
      draftIds: draftIds ?? this.draftIds,
    );
  }
}

/// Challenge creation notifier
class ChallengeCreationNotifier extends StateNotifier<ChallengeCreationState> {
  final ChallengeServiceOptimized _challengeService;
  final LocalStorageService _storage;
  final SyncManager _syncManager;

  ChallengeCreationNotifier(
    this._challengeService,
    this._storage,
    this._syncManager,
  ) : super(ChallengeCreationState(isOffline: !_syncManager.isOnline)) {
    _loadDrafts();
  }

  /// Load saved drafts from local storage
  Future<void> _loadDrafts() async {
    try {
      final drafts = _storage.getAllDrafts();
      state = state.copyWith(draftIds: drafts.keys.toList());
    } catch (e) {
      print('Error loading drafts: $e');
    }
  }

  /// Create a challenge (online or offline)
  Future<void> createChallenge({
    required String userId,
    required String title,
    required String description,
    required String difficulty,
    required List<String> correctAnswers,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      if (_syncManager.isOnline) {
        // Online: Create immediately
        final challenge = await _challengeService.createChallenge(
          title,
          description,
          difficulty,
          userId,
        );

        if (challenge != null) {
          state = state.copyWith(
            isLoading: false,
            createdChallenge: challenge,
            successMessage: 'Challenge created successfully!',
          );
        } else {
          throw Exception('Failed to create challenge');
        }
      } else {
        // Offline: Queue for later sync
        await _saveDraftAndQueue(
          userId: userId,
          title: title,
          description: description,
          difficulty: difficulty,
          correctAnswers: correctAnswers,
        );

        state = state.copyWith(
          isLoading: false,
          successMessage: 'Challenge saved offline - will sync when online',
        );
      }
    } catch (e) {
      print('Error creating challenge: $e');

      // Fallback to offline queue if online creation fails
      try {
        await _saveDraftAndQueue(
          userId: userId,
          title: title,
          description: description,
          difficulty: difficulty,
          correctAnswers: correctAnswers,
        );

        state = state.copyWith(
          isLoading: false,
          successMessage: 'Challenge saved offline - will sync when online',
        );
      } catch (fallbackError) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to save challenge: $fallbackError',
        );
      }
    }
  }

  /// Save draft and queue for sync
  Future<void> _saveDraftAndQueue({
    required String userId,
    required String title,
    required String description,
    required String difficulty,
    required List<String> correctAnswers,
  }) async {
    final draftId = 'draft_${DateTime.now().millisecondsSinceEpoch}';

    final data = {
      'userId': userId,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'correctAnswers': correctAnswers,
      'createdAt': DateTime.now().toIso8601String(),
    };

    // Save draft
    await _storage.saveDraft(draftId, data);

    // Queue for sync
    await _syncManager.queueOperation(
      operationId: draftId,
      type: SyncOperationType.createChallenge,
      data: data,
    );

    await _loadDrafts();
  }

  /// Get a saved draft
  Future<Map<String, dynamic>?> getDraft(String draftId) async {
    return _storage.getDraft(draftId);
  }

  /// Delete a draft
  Future<void> deleteDraft(String draftId) async {
    try {
      await _storage.deleteDraft(draftId);
      await _loadDrafts();
    } catch (e) {
      print('Error deleting draft: $e');
    }
  }

  /// Retry syncing a draft
  Future<void> retrySyncDraft(String draftId) async {
    state = state.copyWith(isSyncing: true);

    try {
      if (_syncManager.isOnline) {
        // Manually trigger sync
        final synced = await _syncManager.syncPendingOperations();
        state = state.copyWith(
          isSyncing: false,
          successMessage: '$synced operations synced',
        );
      } else {
        state = state.copyWith(
          isSyncing: false,
          error: 'Cannot sync while offline',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: 'Failed to sync: $e',
      );
    }
  }

  /// Clear all drafts
  Future<void> clearAllDrafts() async {
    try {
      await _storage.clearAllDrafts();
      await _loadDrafts();
    } catch (e) {
      print('Error clearing drafts: $e');
    }
  }
}

/// Challenge creation provider
final challengeCreationProvider =
    StateNotifierProvider.autoDispose<ChallengeCreationNotifier, ChallengeCreationState>(
  (ref) {
    return ChallengeCreationNotifier(
      ChallengeServiceOptimized(),
      LocalStorageService(),
      SyncManager(),
    );
  },
);

/// Get list of saved drafts
final challengeDraftsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final storage = LocalStorageService();
  await storage.initialize();
  final drafts = storage.getAllDrafts();
  return drafts.keys.toList();
});

/// Get a specific draft by ID
final challengeDraftProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, draftId) async {
  final storage = LocalStorageService();
  await storage.initialize();
  return storage.getDraft(draftId);
});
