import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:machigai/services/local_storage_service.dart';

/// Operation types for sync queue
enum SyncOperationType {
  createChallenge,
  updateChallenge,
  deleteChallenge,
  recordAttempt,
  updateUserProfile,
}

/// Represents a pending sync operation
class PendingSyncOperation {
  final String id;
  final SyncOperationType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  int retryCount;
  DateTime? lastAttemptAt;

  PendingSyncOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.lastAttemptAt,
  });

  factory PendingSyncOperation.fromMap(String id, Map<String, dynamic> map) {
    return PendingSyncOperation(
      id: id,
      type: SyncOperationType.values[map['type'] as int? ?? 0],
      data: map['data'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(map['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      retryCount: map['retryCount'] as int? ?? 0,
      lastAttemptAt: map['lastAttemptAt'] != null
          ? DateTime.parse(map['lastAttemptAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.index,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
      'lastAttemptAt': lastAttemptAt?.toIso8601String(),
    };
  }
}

/// Callback for sync operation completion
typedef SyncCallback = Future<bool> Function(PendingSyncOperation operation);

/// Sync manager for handling background synchronization
/// Manages offline queue and automatic sync when connectivity restored
class SyncManager {
  static final SyncManager _instance = SyncManager._internal();

  factory SyncManager() {
    return _instance;
  }

  SyncManager._internal();

  final LocalStorageService _localStorage = LocalStorageService();
  final Connectivity _connectivity = Connectivity();

  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  Timer? _syncTimer;

  bool _isOnline = true;
  bool _isSyncing = false;

  // Sync callbacks registered by services
  final Map<SyncOperationType, SyncCallback> _syncCallbacks = {};

  // Stats tracking
  int _totalSyncedOperations = 0;
  int _totalFailedOperations = 0;

  /// Initialize the sync manager
  Future<void> initialize() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (result) {
        final wasOnline = _isOnline;
        _isOnline = result != ConnectivityResult.none;

        // If came back online, trigger sync
        if (!wasOnline && _isOnline) {
          _triggerSync();
        }
      },
    );

    // Start periodic sync timer (every 5 minutes or when needed)
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _triggerSync();
    });
  }

  /// Register a sync callback for an operation type
  void registerSyncCallback(SyncOperationType type, SyncCallback callback) {
    _syncCallbacks[type] = callback;
  }

  /// Check if currently online
  bool get isOnline => _isOnline;

  /// Check if sync is in progress
  bool get isSyncing => _isSyncing;

  /// Add operation to sync queue
  Future<bool> queueOperation({
    required String operationId,
    required SyncOperationType type,
    required Map<String, dynamic> data,
  }) async {
    try {
      final operation = PendingSyncOperation(
        id: operationId,
        type: type,
        data: data,
        createdAt: DateTime.now(),
      );

      final stored = await _localStorage.addToSyncQueue(
        operationId,
        operation.toMap(),
      );

      if (stored && _isOnline && !_isSyncing) {
        _triggerSync();
      }

      return stored;
    } catch (e) {
      print('Error queuing operation: $e');
      return false;
    }
  }

  /// Manually trigger synchronization
  void _triggerSync() {
    if (_isSyncing || !_isOnline) return;
    syncPendingOperations();
  }

  /// Synchronize all pending operations
  Future<int> syncPendingOperations() async {
    if (_isSyncing || !_isOnline) return 0;

    _isSyncing = true;
    int syncedCount = 0;

    try {
      final queue = _localStorage.getSyncQueue();
      if (queue.isEmpty) {
        return 0;
      }

      // Sort by creation time (oldest first)
      final sortedOps = queue.entries.toList()
        ..sort((a, b) {
          final timeA = a.value['createdAt'] as String?;
          final timeB = b.value['createdAt'] as String?;
          if (timeA == null || timeB == null) return 0;
          return DateTime.parse(timeA).compareTo(DateTime.parse(timeB));
        });

      for (final entry in sortedOps) {
        final operation = PendingSyncOperation.fromMap(entry.key, entry.value);
        final callback = _syncCallbacks[operation.type];

        if (callback == null) {
          print('No callback registered for ${operation.type}');
          continue;
        }

        try {
          final success = await callback(operation);
          if (success) {
            await _localStorage.markAsSynced(operation.id);
            syncedCount++;
            _totalSyncedOperations++;
          } else {
            // Increment retry count and try again later
            await _localStorage.incrementRetryCount(operation.id);
            _totalFailedOperations++;
          }
        } catch (e) {
          print('Error syncing operation ${operation.id}: $e');
          await _localStorage.incrementRetryCount(operation.id);
          _totalFailedOperations++;
        }
      }

      // Update sync timestamp
      if (syncedCount > 0) {
        await _localStorage.updateLastSyncTime();
      }

      return syncedCount;
    } finally {
      _isSyncing = false;
    }
  }

  /// Get pending operations count
  int getPendingOperationsCount() {
    return _localStorage.getSyncQueue().length;
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStats() {
    return {
      'isOnline': _isOnline,
      'isSyncing': _isSyncing,
      'pendingOperations': getPendingOperationsCount(),
      'totalSynced': _totalSyncedOperations,
      'totalFailed': _totalFailedOperations,
      'lastSyncTime': _localStorage.getLastSyncTime(),
      'timeSinceLastSync': _localStorage.getTimeSinceLastSync().inMinutes,
    };
  }

  /// Clear sync queue (careful operation)
  Future<bool> clearSyncQueue() async {
    return await _localStorage.clearSyncQueue();
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription.cancel();
    _syncTimer?.cancel();
  }
}
