import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:machigai/models/index.dart';
import 'package:machigai/services/cache_service.dart';
import 'package:machigai/services/performance_service.dart';
import 'package:uuid/uuid.dart';

/// Optimized challenge service with caching and performance monitoring
///
/// This version improves upon the base ChallengeService by:
/// - Caching frequently accessed challenges and challenge lists
/// - Performance monitoring for slow operations
/// - Automatic cache invalidation on updates
/// - Better error handling and logging
class ChallengeServiceOptimized {
  static const String collectionName = 'challenges';
  static const String attemptsSubcollection = 'attempts';

  final FirebaseFirestore _firestore;
  final CacheService _cache;
  final PerformanceService _performance;

  ChallengeServiceOptimized({
    FirebaseFirestore? firestore,
    CacheService? cache,
    PerformanceService? performance,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _cache = cache ?? CacheService(),
        _performance = performance ?? PerformanceService();

  /// Create a new challenge with performance monitoring and cache handling
  Future<UserGeneratedChallenge> createChallenge({
    required String creatorId,
    required String videoUrl,
    required Map<String, dynamic> editedPoint,
    required String difficulty,
    double? aiScore,
  }) async {
    _performance.startMeasure('createChallenge');

    try {
      final id = const Uuid().v4();
      final shareToken = const Uuid().v4();
      final now = DateTime.now();

      final challenge = UserGeneratedChallenge(
        id: id,
        creatorId: creatorId,
        videoUrl: videoUrl,
        editedPoint: editedPoint,
        difficulty: difficulty,
        createdAt: now,
        shareToken: shareToken,
        moderationStatus: 'pending',
        aiScore: aiScore,
      );

      await _firestore
          .collection(collectionName)
          .doc(id)
          .set(challenge.toFirestore());

      // Cache the new challenge
      _cache.setChallenge(challenge);

      // Invalidate user's challenge list cache
      _cache.invalidateChallengeLists();

      return challenge;
    } catch (e) {
      _performance.endMeasure('createChallenge', isError: true);
      rethrow;
    } finally {
      _performance.endMeasure('createChallenge');
    }
  }

  /// Get challenge by ID with cache-first strategy
  Future<UserGeneratedChallenge?> getChallenge(String challengeId) async {
    _performance.startMeasure('getChallenge');

    try {
      // Check cache first
      var challenge = _cache.getChallenge(challengeId);
      if (challenge != null) {
        _performance.endMeasure('getChallenge', operation: 'cache_hit');
        return challenge;
      }

      // Cache miss - fetch from Firestore
      final doc = await _firestore
          .collection(collectionName)
          .doc(challengeId)
          .get();

      if (!doc.exists) {
        _performance.endMeasure('getChallenge', operation: 'not_found');
        return null;
      }

      challenge = UserGeneratedChallenge.fromFirestore(doc);

      // Cache for future access
      _cache.setChallenge(challenge);

      _performance.endMeasure('getChallenge', operation: 'firestore_hit');
      return challenge;
    } catch (e) {
      _performance.endMeasure('getChallenge', isError: true);
      rethrow;
    }
  }

  /// Get approved challenges with smart caching
  Future<List<UserGeneratedChallenge>> getApprovedChallenges({
    int limit = 20,
    String? difficulty,
  }) async {
    final cacheKey = 'approved_challenges_${difficulty ?? "all"}_$limit';
    _performance.startMeasure('getApprovedChallenges');

    try {
      // Check cache first
      var cached = _cache.getChallengeList(cacheKey);
      if (cached != null) {
        _performance.endMeasure('getApprovedChallenges',
            operation: 'cache_hit');
        return cached;
      }

      // Build query
      Query query = _firestore
          .collection(collectionName)
          .where('moderationStatus', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true);

      if (difficulty != null) {
        query = query.where('difficulty', isEqualTo: difficulty);
      }

      query = query.limit(limit);

      // Execute query with timeout
      final docs = await query.get().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Failed to fetch challenges'),
      );

      final challenges = docs.docs
          .map((doc) =>
              UserGeneratedChallenge.fromFirestore(doc as DocumentSnapshot))
          .toList();

      // Cache the results
      _cache.setChallengeList(cacheKey, challenges);

      _performance.endMeasure('getApprovedChallenges',
          operation: 'firestore_hit');
      return challenges;
    } catch (e) {
      _performance.endMeasure('getApprovedChallenges', isError: true);
      rethrow;
    }
  }

  /// Get user's challenges with cache optimization
  Future<List<UserGeneratedChallenge>> getUserChallenges(
    String userId, {
    int limit = 50,
  }) async {
    final cacheKey = 'user_challenges_$userId';
    _performance.startMeasure('getUserChallenges');

    try {
      // Check cache first
      var cached = _cache.getChallengeList(cacheKey);
      if (cached != null) {
        _performance.endMeasure('getUserChallenges', operation: 'cache_hit');
        return cached;
      }

      // Fetch from Firestore
      final docs = await _firestore
          .collection(collectionName)
          .where('creatorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final challenges = docs.docs
          .map((doc) =>
              UserGeneratedChallenge.fromFirestore(doc as DocumentSnapshot))
          .toList();

      // Cache for future access
      _cache.setChallengeList(cacheKey, challenges);

      _performance.endMeasure('getUserChallenges', operation: 'firestore_hit');
      return challenges;
    } catch (e) {
      _performance.endMeasure('getUserChallenges', isError: true);
      rethrow;
    }
  }

  /// Get challenge by share token with cache
  Future<UserGeneratedChallenge?> getChallengeByShareToken(
    String shareToken,
  ) async {
    final cacheKey = 'challenge_by_token_$shareToken';
    _performance.startMeasure('getChallengeByShareToken');

    try {
      // Try to get from challenge cache first
      var cached = _cache.getChallengeList(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        _performance.endMeasure('getChallengeByShareToken',
            operation: 'cache_hit');
        return cached.first;
      }

      // Query Firestore
      final docs = await _firestore
          .collection(collectionName)
          .where('shareToken', isEqualTo: shareToken)
          .limit(1)
          .get();

      if (docs.docs.isEmpty) {
        _performance.endMeasure('getChallengeByShareToken',
            operation: 'not_found');
        return null;
      }

      final challenge =
          UserGeneratedChallenge.fromFirestore(docs.docs.first);

      // Cache it
      _cache.setChallenge(challenge);

      _performance.endMeasure('getChallengeByShareToken',
          operation: 'firestore_hit');
      return challenge;
    } catch (e) {
      _performance.endMeasure('getChallengeByShareToken', isError: true);
      rethrow;
    }
  }

  /// Update challenge and invalidate relevant caches
  Future<void> updateChallenge(UserGeneratedChallenge challenge) async {
    _performance.startMeasure('updateChallenge');

    try {
      await _firestore
          .collection(collectionName)
          .doc(challenge.id)
          .set(challenge.toFirestore());

      // Invalidate related caches
      _cache.invalidateChallenge(challenge.id);
      _cache.invalidateChallengeLists();

      _performance.endMeasure('updateChallenge');
    } catch (e) {
      _performance.endMeasure('updateChallenge', isError: true);
      rethrow;
    }
  }

  /// Increment solve count with optimistic update
  Future<void> incrementSolveCount(String challengeId) async {
    _performance.startMeasure('incrementSolveCount');

    try {
      await _firestore.collection(collectionName).doc(challengeId).update({
        'solveCount': FieldValue.increment(1),
      });

      // Invalidate challenge cache to force refresh on next access
      _cache.invalidateChallenge(challengeId);

      _performance.endMeasure('incrementSolveCount');
    } catch (e) {
      _performance.endMeasure('incrementSolveCount', isError: true);
      rethrow;
    }
  }

  /// Delete challenge and clear caches
  Future<void> deleteChallenge(String challengeId) async {
    _performance.startMeasure('deleteChallenge');

    try {
      await _firestore.collection(collectionName).doc(challengeId).delete();

      // Clear related caches
      _cache.invalidateChallenge(challengeId);
      _cache.invalidateChallengeLists();

      _performance.endMeasure('deleteChallenge');
    } catch (e) {
      _performance.endMeasure('deleteChallenge', isError: true);
      rethrow;
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return _cache.getCacheStats();
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats(String operationName) {
    return _performance.getStats(operationName);
  }

  /// Clear all caches (useful for refresh)
  void clearCache() {
    _cache.clearAll();
  }
}

/// Exception for timeout operations
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
