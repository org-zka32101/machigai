import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:machigai/services/sync_manager.dart';

/// Sync status state class
class SyncStatus {
  final bool isOnline;
  final bool isSyncing;
  final int pendingOperations;
  final int totalSynced;
  final int totalFailed;
  final DateTime? lastSyncTime;
  final int timeSinceLastSyncMinutes;

  SyncStatus({
    required this.isOnline,
    required this.isSyncing,
    required this.pendingOperations,
    required this.totalSynced,
    required this.totalFailed,
    this.lastSyncTime,
    required this.timeSinceLastSyncMinutes,
  });

  /// Get sync status message for UI display
  String get statusMessage {
    if (!isOnline) {
      return pendingOperations > 0
          ? 'Offline · $pendingOperations pending'
          : 'Offline';
    }

    if (isSyncing) {
      return 'Syncing...';
    }

    if (pendingOperations > 0) {
      return 'Pending sync ($pendingOperations)';
    }

    if (totalFailed > 0) {
      return 'Sync error ($totalFailed failed)';
    }

    return 'All synced';
  }

  /// Get status color indicator
  SyncStatusIndicator get indicator {
    if (!isOnline) {
      return SyncStatusIndicator.offline;
    }

    if (isSyncing) {
      return SyncStatusIndicator.syncing;
    }

    if (pendingOperations > 0) {
      return SyncStatusIndicator.pending;
    }

    if (totalFailed > 0) {
      return SyncStatusIndicator.error;
    }

    return SyncStatusIndicator.synced;
  }

  /// Whether user should be notified of sync state
  bool get requiresAttention => !isOnline || totalFailed > 0 || pendingOperations > 0;
}

/// Sync status indicator enum
enum SyncStatusIndicator {
  offline,
  syncing,
  pending,
  error,
  synced,
}

/// Sync status notifier - manages sync state
class SyncStatusNotifier extends StateNotifier<SyncStatus> {
  final SyncManager _syncManager;

  SyncStatusNotifier(this._syncManager)
      : super(
          SyncStatus(
            isOnline: _syncManager.isOnline,
            isSyncing: _syncManager.isSyncing,
            pendingOperations: _syncManager.getPendingOperationsCount(),
            totalSynced: 0,
            totalFailed: 0,
            lastSyncTime: null,
            timeSinceLastSyncMinutes: 0,
          ),
        ) {
    _refreshStatus();
  }

  /// Refresh sync status from SyncManager
  void _refreshStatus() {
    final stats = _syncManager.getSyncStats();

    state = SyncStatus(
      isOnline: _syncManager.isOnline,
      isSyncing: _syncManager.isSyncing,
      pendingOperations: _syncManager.getPendingOperationsCount(),
      totalSynced: stats['totalSynced'] as int? ?? 0,
      totalFailed: stats['totalFailed'] as int? ?? 0,
      lastSyncTime: stats['lastSyncTime'] as DateTime?,
      timeSinceLastSyncMinutes: stats['timeSinceLastSync'] as int? ?? 0,
    );
  }

  /// Manually refresh status
  void refresh() {
    _refreshStatus();
  }

  /// Clear failed operations counter
  void clearFailures() {
    _refreshStatus();
  }
}

/// Sync status provider
final syncStatusProvider =
    StateNotifierProvider.autoDispose<SyncStatusNotifier, SyncStatus>((ref) {
  final syncManager = SyncManager();
  return SyncStatusNotifier(syncManager);
});

/// Refresh sync status - trigger manual refresh
final syncStatusRefreshProvider = Provider.autoDispose<Function>((ref) {
  return () {
    ref.read(syncStatusProvider.notifier).refresh();
  };
});

/// Sync status periodic listener - auto-refresh sync status
final syncStatusListenerProvider = FutureProvider.autoDispose<void>((ref) async {
  // This provider periodically checks sync status
  // In a real app, this would listen to connectivity changes and sync events
  await Future.delayed(const Duration(seconds: 5));
  ref.read(syncStatusProvider.notifier).refresh();

  // Refresh again after this completes (creates a periodic loop)
  ref.watch(syncStatusListenerProvider);
});
