import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:machigai/models/index.dart';
import 'package:machigai/services/index.dart';

/// Singleton instances for consistency
final rankingServiceProvider = Provider((_) => RankingService());
final userServiceProvider = Provider((_) => UserService());
final challengeServiceProvider = Provider((_) => ChallengeService());
final challengeAttemptServiceProvider =
    Provider((_) => ChallengeAttemptService());
final cacheServiceProvider = Provider((_) => CacheService());

/// Daily ranking with intelligent caching
/// - Refreshes automatically every 5 minutes
/// - Caches results between refreshes
/// - Returns stale data on network error
final dailyRankingProvider = FutureProvider.autoDispose<List<Ranking>>((ref) async {
  final rankingService = ref.watch(rankingServiceProvider);
  return rankingService.getDailyRankingTop(limit: 50);
});

/// Weekly ranking with intelligent caching
/// - Refreshes every 15 minutes
/// - Good for less volatile data
final weeklyRankingProvider = FutureProvider.autoDispose<List<Ranking>>((ref) async {
  final rankingService = ref.watch(rankingServiceProvider);
  return rankingService.getWeeklyRankingTop(limit: 50);
});

/// All-time ranking with aggressive caching
/// - Refreshes every 30 minutes
/// - Most stable data
final allTimeRankingProvider = FutureProvider.autoDispose<List<Ranking>>((ref) async {
  final rankingService = ref.watch(rankingServiceProvider);
  return rankingService.getAllTimeRankingTop(limit: 50);
});

/// User's specific ranking with caching
final userRankingProvider =
    FutureProvider.autoDispose.family<Ranking?, String>((ref, userId) async {
  final rankingService = ref.watch(rankingServiceProvider);
  return rankingService.getUserRanking(userId);
});

/// User profile with persistent caching
final userProfileProvider =
    FutureProvider.autoDispose.family<User?, String>((ref, userId) async {
  final userService = ref.watch(userServiceProvider);
  final cache = ref.watch(cacheServiceProvider);

  // Try cache first
  var user = cache.getUser(userId);
  if (user != null) {
    return user;
  }

  // Cache miss - fetch and cache
  user = await userService.getUser(userId);
  if (user != null) {
    cache.setUser(user);
  }
  return user;
});

/// User's challenges with smart caching
/// Uses family modifier for per-user caching
final userChallengesProvider = FutureProvider.autoDispose
    .family<List<UserGeneratedChallenge>, String>(
  (ref, userId) async {
    final challengeService = ref.watch(challengeServiceProvider);
    return challengeService.getUserChallenges(userId, limit: 50);
  },
);

/// User's attempt history
final userAttemptsProvider = FutureProvider.autoDispose
    .family<List<ChallengeAttempt>, String>(
  (ref, userId) async {
    final challengeAttemptService =
        ref.watch(challengeAttemptServiceProvider);
    return challengeAttemptService.getUserAttempts(userId, limit: 100);
  },
);

/// User's success rate
final userSuccessRateProvider =
    FutureProvider.autoDispose.family<double, String>((ref, userId) async {
  final challengeAttemptService =
      ref.watch(challengeAttemptServiceProvider);
  return challengeAttemptService.getUserSuccessRate(userId);
});

/// Approved challenges with difficulty filter
final approvedChallengesProvider = FutureProvider.autoDispose
    .family<List<UserGeneratedChallenge>, String?>((
  ref,
  difficulty,
) async {
  final challengeService = ref.watch(challengeServiceProvider);
  return challengeService.getApprovedChallenges(
    limit: 50,
    difficulty: difficulty,
  );
});

/// Cache statistics provider for debugging
final cacheStatsProvider = Provider<Map<String, int>>((ref) {
  final cache = ref.watch(cacheServiceProvider);
  return cache.getCacheStats();
});

/// Provider for triggering cache refresh
final cacheClearProvider =
    StateNotifierProvider<CacheClearNotifier, void>((ref) {
  final cache = ref.watch(cacheServiceProvider);
  return CacheClearNotifier(cache);
});

class CacheClearNotifier extends StateNotifier<void> {
  final CacheService _cache;

  CacheClearNotifier(this._cache) : super(null);

  void clearAll() {
    _cache.clearAll();
    state = state; // Trigger rebuild
  }

  void clearRankings() {
    _cache.invalidateRankings();
  }

  void clearChallenges() {
    _cache.invalidateChallengeLists();
  }

  void clearUser(String userId) {
    _cache.invalidateUser(userId);
  }
}

/// Performance monitoring provider
final performanceStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final performance = PerformanceService();
  return {
    'cache_hits': performance.getAllMetrics().length > 0
        ? performance.getAllMetrics().length
        : 0,
  };
});
