import 'dart:async';
import 'package:machigai/models/index.dart';

/// Cache entry with timestamp and TTL
class CacheEntry<T> {
  final T data;
  final DateTime createdAt;
  final Duration ttl;

  CacheEntry({
    required this.data,
    required this.ttl,
  }) : createdAt = DateTime.now();

  bool get isExpired => DateTime.now().difference(createdAt) > ttl;
}

/// In-memory cache service for improved performance
/// Reduces Firebase reads by caching frequently accessed data
class CacheService {
  static final CacheService _instance = CacheService._internal();

  factory CacheService() {
    return _instance;
  }

  CacheService._internal();

  // Separate caches for different data types
  final Map<String, CacheEntry<User>> _userCache = {};
  final Map<String, CacheEntry<UserGeneratedChallenge>> _challengeCache = {};
  final Map<String, CacheEntry<List<Ranking>>> _rankingCache = {};
  final Map<String, CacheEntry<List<UserGeneratedChallenge>>>
      _challengeListCache = {};

  // Cache configuration with sensible defaults
  static const Duration userCacheTTL = Duration(minutes: 10);
  static const Duration challengeCacheTTL = Duration(minutes: 15);
  static const Duration rankingCacheTTL = Duration(minutes: 5); // Rankings change frequently
  static const Duration challengeListCacheTTL = Duration(minutes: 10);

  // Cache statistics for monitoring
  int _totalCacheHits = 0;
  int _totalCacheMisses = 0;

  int get totalCacheHits => _totalCacheHits;
  int get totalCacheMisses => _totalCacheMisses;

  double get cacheHitRate {
    final total = _totalCacheHits + _totalCacheMisses;
    return total == 0 ? 0.0 : _totalCacheHits / total;
  }

  /// Set user in cache
  void setUser(User user) {
    _userCache[user.uid] = CacheEntry(
      data: user,
      ttl: userCacheTTL,
    );
  }

  /// Get user from cache (returns null if expired or not found)
  User? getUser(String userId) {
    final entry = _userCache[userId];
    if (entry == null) {
      _totalCacheMisses++;
      return null;
    }
    if (entry.isExpired) {
      _userCache.remove(userId);
      _totalCacheMisses++;
      return null;
    }
    _totalCacheHits++;
    return entry.data;
  }

  /// Set challenge in cache
  void setChallenge(UserGeneratedChallenge challenge) {
    _challengeCache[challenge.id] = CacheEntry(
      data: challenge,
      ttl: challengeCacheTTL,
    );
  }

  /// Get challenge from cache
  UserGeneratedChallenge? getChallenge(String challengeId) {
    final entry = _challengeCache[challengeId];
    if (entry == null) {
      _totalCacheMisses++;
      return null;
    }
    if (entry.isExpired) {
      _challengeCache.remove(challengeId);
      _totalCacheMisses++;
      return null;
    }
    _totalCacheHits++;
    return entry.data;
  }

  /// Set ranking list in cache
  void setRankings(String key, List<Ranking> rankings) {
    _rankingCache[key] = CacheEntry(
      data: rankings,
      ttl: rankingCacheTTL,
    );
  }

  /// Get ranking list from cache
  List<Ranking>? getRankings(String key) {
    final entry = _rankingCache[key];
    if (entry == null) {
      _totalCacheMisses++;
      return null;
    }
    if (entry.isExpired) {
      _rankingCache.remove(key);
      _totalCacheMisses++;
      return null;
    }
    _totalCacheHits++;
    return entry.data;
  }

  /// Set challenge list in cache
  void setChallengeList(String key, List<UserGeneratedChallenge> challenges) {
    _challengeListCache[key] = CacheEntry(
      data: challenges,
      ttl: challengeListCacheTTL,
    );
  }

  /// Get challenge list from cache
  List<UserGeneratedChallenge>? getChallengeList(String key) {
    final entry = _challengeListCache[key];
    if (entry == null) {
      _totalCacheMisses++;
      return null;
    }
    if (entry.isExpired) {
      _challengeListCache.remove(key);
      _totalCacheMisses++;
      return null;
    }
    _totalCacheHits++;
    return entry.data;
  }

  /// Invalidate all caches
  void clearAll() {
    _userCache.clear();
    _challengeCache.clear();
    _rankingCache.clear();
    _challengeListCache.clear();
  }

  /// Invalidate user cache
  void invalidateUser(String userId) {
    _userCache.remove(userId);
  }

  /// Invalidate challenge cache
  void invalidateChallenge(String challengeId) {
    _challengeCache.remove(challengeId);
  }

  /// Invalidate challenge list caches
  void invalidateChallengeLists() {
    _challengeListCache.clear();
  }

  /// Invalidate ranking caches
  void invalidateRankings() {
    _rankingCache.clear();
  }

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    return {
      'userCacheSize': _userCache.length,
      'challengeCacheSize': _challengeCache.length,
      'rankingCacheSize': _rankingCache.length,
      'challengeListCacheSize': _challengeListCache.length,
      'totalHits': _totalCacheHits,
      'totalMisses': _totalCacheMisses,
    };
  }

  /// Cleanup expired entries periodically
  Future<void> cleanupExpiredEntries() async {
    _userCache.removeWhere((_, entry) => entry.isExpired);
    _challengeCache.removeWhere((_, entry) => entry.isExpired);
    _rankingCache.removeWhere((_, entry) => entry.isExpired);
    _challengeListCache.removeWhere((_, entry) => entry.isExpired);
  }

  /// Schedule periodic cleanup (call once at app startup)
  void startPeriodicCleanup({Duration interval = const Duration(minutes: 5)}) {
    Timer.periodic(interval, (_) {
      cleanupExpiredEntries();
    });
  }
}
