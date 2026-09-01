import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local storage service for offline-first support
/// Persists data locally for offline access and sync queue management
class LocalStorageService {
  static final LocalStorageService _instance =
      LocalStorageService._internal();

  factory LocalStorageService() {
    return _instance;
  }

  LocalStorageService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  // Storage keys
  static const String _userCacheKey = 'user_cache';
  static const String _challengeDraftsKey = 'challenge_drafts';
  static const String _syncQueueKey = 'sync_queue';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _offlineModeKey = 'offline_mode_enabled';
  static const String _preferredDifficultyKey = 'preferred_difficulty';
  static const String _recentChallengesKey = 'recent_challenges';

  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  // ============================================================================
  // User Cache Management
  // ============================================================================

  /// Save user data to local cache
  Future<bool> saveUserCache(String userId, Map<String, dynamic> userData) async {
    try {
      final data = {
        'userId': userId,
        'data': userData,
        'timestamp': DateTime.now().toIso8601String(),
      };
      return await _prefs.setString(_userCacheKey, jsonEncode(data));
    } catch (e) {
      print('Error saving user cache: $e');
      return false;
    }
  }

  /// Get cached user data
  Map<String, dynamic>? getUserCache(String userId) {
    try {
      final cached = _prefs.getString(_userCacheKey);
      if (cached == null) return null;

      final data = jsonDecode(cached) as Map<String, dynamic>;
      if (data['userId'] != userId) return null;

      return data['data'] as Map<String, dynamic>;
    } catch (e) {
      print('Error reading user cache: $e');
      return null;
    }
  }

  /// Clear user cache
  Future<bool> clearUserCache() async {
    return await _prefs.remove(_userCacheKey);
  }

  // ============================================================================
  // Challenge Drafts Management
  // ============================================================================

  /// Save a challenge draft locally
  Future<bool> saveDraft(String draftId, Map<String, dynamic> draftData) async {
    try {
      final drafts = _getDrafts();
      drafts[draftId] = {
        ...draftData,
        'savedAt': DateTime.now().toIso8601String(),
      };
      return await _prefs.setString(_challengeDraftsKey, jsonEncode(drafts));
    } catch (e) {
      print('Error saving draft: $e');
      return false;
    }
  }

  /// Get a specific draft
  Map<String, dynamic>? getDraft(String draftId) {
    try {
      final drafts = _getDrafts();
      return drafts[draftId] as Map<String, dynamic>?;
    } catch (e) {
      print('Error getting draft: $e');
      return null;
    }
  }

  /// Get all drafts
  Map<String, Map<String, dynamic>> getAllDrafts() {
    return _getDrafts();
  }

  /// Delete a specific draft
  Future<bool> deleteDraft(String draftId) async {
    try {
      final drafts = _getDrafts();
      drafts.remove(draftId);
      if (drafts.isEmpty) {
        return await _prefs.remove(_challengeDraftsKey);
      }
      return await _prefs.setString(_challengeDraftsKey, jsonEncode(drafts));
    } catch (e) {
      print('Error deleting draft: $e');
      return false;
    }
  }

  /// Clear all drafts
  Future<bool> clearAllDrafts() async {
    return await _prefs.remove(_challengeDraftsKey);
  }

  Map<String, Map<String, dynamic>> _getDrafts() {
    final cached = _prefs.getString(_challengeDraftsKey);
    if (cached == null) return {};

    try {
      final data = jsonDecode(cached) as Map<String, dynamic>;
      final result = <String, Map<String, dynamic>>{};
      data.forEach((key, value) {
        result[key] = value as Map<String, dynamic>;
      });
      return result;
    } catch (e) {
      return {};
    }
  }

  // ============================================================================
  // Sync Queue Management
  // ============================================================================

  /// Add an operation to the sync queue
  Future<bool> addToSyncQueue(String operationId, Map<String, dynamic> operation) async {
    try {
      final queue = _getSyncQueue();
      queue[operationId] = {
        ...operation,
        'createdAt': DateTime.now().toIso8601String(),
        'retryCount': 0,
      };
      return await _prefs.setString(_syncQueueKey, jsonEncode(queue));
    } catch (e) {
      print('Error adding to sync queue: $e');
      return false;
    }
  }

  /// Get all pending operations
  Map<String, Map<String, dynamic>> getSyncQueue() {
    return _getSyncQueue();
  }

  /// Mark operation as synced (remove from queue)
  Future<bool> markAsSynced(String operationId) async {
    try {
      final queue = _getSyncQueue();
      queue.remove(operationId);
      if (queue.isEmpty) {
        return await _prefs.remove(_syncQueueKey);
      }
      return await _prefs.setString(_syncQueueKey, jsonEncode(queue));
    } catch (e) {
      print('Error marking as synced: $e');
      return false;
    }
  }

  /// Increment retry count for an operation
  Future<bool> incrementRetryCount(String operationId) async {
    try {
      final queue = _getSyncQueue();
      final op = queue[operationId];
      if (op != null) {
        op['retryCount'] = (op['retryCount'] as int? ?? 0) + 1;
        return await _prefs.setString(_syncQueueKey, jsonEncode(queue));
      }
      return false;
    } catch (e) {
      print('Error incrementing retry: $e');
      return false;
    }
  }

  /// Clear sync queue
  Future<bool> clearSyncQueue() async {
    return await _prefs.remove(_syncQueueKey);
  }

  Map<String, Map<String, dynamic>> _getSyncQueue() {
    final cached = _prefs.getString(_syncQueueKey);
    if (cached == null) return {};

    try {
      final data = jsonDecode(cached) as Map<String, dynamic>;
      final result = <String, Map<String, dynamic>>{};
      data.forEach((key, value) {
        result[key] = value as Map<String, dynamic>;
      });
      return result;
    } catch (e) {
      return {};
    }
  }

  // ============================================================================
  // Sync Metadata
  // ============================================================================

  /// Get last successful sync timestamp
  DateTime? getLastSyncTime() {
    try {
      final timestamp = _prefs.getString(_lastSyncKey);
      if (timestamp == null) return null;
      return DateTime.parse(timestamp);
    } catch (e) {
      return null;
    }
  }

  /// Update last sync timestamp
  Future<bool> updateLastSyncTime() async {
    try {
      return await _prefs.setString(
        _lastSyncKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      print('Error updating sync time: $e');
      return false;
    }
  }

  /// Get time since last sync
  Duration getTimeSinceLastSync() {
    final lastSync = getLastSyncTime();
    if (lastSync == null) return Duration.zero;
    return DateTime.now().difference(lastSync);
  }

  // ============================================================================
  // Offline Mode
  // ============================================================================

  /// Check if offline mode is enabled
  bool isOfflineModeEnabled() {
    return _prefs.getBool(_offlineModeKey) ?? false;
  }

  /// Enable/disable offline mode
  Future<bool> setOfflineMode(bool enabled) async {
    return await _prefs.setBool(_offlineModeKey, enabled);
  }

  // ============================================================================
  // User Preferences
  // ============================================================================

  /// Save preferred difficulty
  Future<bool> setPreferredDifficulty(String difficulty) async {
    return await _prefs.setString(_preferredDifficultyKey, difficulty);
  }

  /// Get preferred difficulty
  String? getPreferredDifficulty() {
    return _prefs.getString(_preferredDifficultyKey);
  }

  /// Save recently viewed challenges
  Future<bool> saveRecentChallenge(String challengeId) async {
    try {
      final recent = _prefs.getStringList(_recentChallengesKey) ?? [];
      recent.remove(challengeId); // Remove if already exists
      recent.insert(0, challengeId); // Add to front
      if (recent.length > 20) {
        recent.removeRange(20, recent.length); // Keep only 20 recent
      }
      return await _prefs.setStringList(_recentChallengesKey, recent);
    } catch (e) {
      print('Error saving recent challenge: $e');
      return false;
    }
  }

  /// Get recent challenges
  List<String> getRecentChallenges({int limit = 10}) {
    final recent = _prefs.getStringList(_recentChallengesKey) ?? [];
    return recent.take(limit).toList();
  }

  // ============================================================================
  // Storage Statistics
  // ============================================================================

  /// Get storage statistics
  Map<String, int> getStorageStats() {
    return {
      'totalDrafts': _getDrafts().length,
      'syncQueueSize': _getSyncQueue().length,
      'recentChallengesCount':
          (_prefs.getStringList(_recentChallengesKey) ?? []).length,
    };
  }

  /// Clear all local storage
  Future<bool> clearAll() async {
    try {
      return await _prefs.clear();
    } catch (e) {
      print('Error clearing all: $e');
      return false;
    }
  }
}
