import 'dart:async';
import 'package:machigai/models/index.dart';
import 'package:machigai/services/cache_service.dart';
import 'package:machigai/services/challenge_service.dart';

/// User behavior patterns for prefetch optimization
class UserBehaviorPattern {
  final String userId;
  final int challengesViewedToday;
  final int averageChallengesPerSession;
  final String preferredDifficulty;
  final DateTime lastActiveTime;
  final List<String> recentChallengeIds;

  UserBehaviorPattern({
    required this.userId,
    required this.challengesViewedToday,
    required this.averageChallengesPerSession,
    required this.preferredDifficulty,
    required this.lastActiveTime,
    required this.recentChallengeIds,
  });
}

/// Prefetch strategy based on user behavior
class PrefetchStrategy {
  final int maxPrefetchItems;
  final Duration prefetchTimeout;
  final bool enableSmartPrefetch;
  final bool enableRankingPrefetch;
  final bool enableRelatedChallenges;

  const PrefetchStrategy({
    this.maxPrefetchItems = 10,
    this.prefetchTimeout = const Duration(seconds: 5),
    this.enableSmartPrefetch = true,
    this.enableRankingPrefetch = true,
    this.enableRelatedChallenges = true,
  });
}

/// Service for intelligent data prefetching
/// Predicts what data user will need and loads it in advance
class PrefetchService {
  static final PrefetchService _instance = PrefetchService._internal();

  factory PrefetchService() {
    return _instance;
  }

  PrefetchService._internal();

  final CacheService _cache = CacheService();
  final ChallengeService _challengeService = ChallengeService();

  // Tracking
  final Map<String, DateTime> _prefetchHistory = {};
  int _successfulPrefetches = 0;
  int _failedPrefetches = 0;

  // Configuration
  late PrefetchStrategy _strategy = const PrefetchStrategy();

  /// Initialize prefetch service
  void initialize({PrefetchStrategy? strategy}) {
    if (strategy != null) {
      _strategy = strategy;
    }
  }

  /// Prefetch challenges based on user's viewing pattern
  Future<int> prefetchNextChallenges(
    String userId, {
    String? difficulty,
    int limit = 5,
  }) async {
    if (!_strategy.enableSmartPrefetch) return 0;

    int prefetchedCount = 0;

    try {
      // Fetch approved challenges
      final challenges = await _challengeService
          .getApprovedChallenges(
            limit: limit,
            difficulty: difficulty,
          )
          .timeout(_strategy.prefetchTimeout);

      // Cache them
      for (final challenge in challenges) {
        _cache.setChallenge(challenge);
        prefetchedCount++;
      }

      _successfulPrefetches++;
      _recordPrefetch('prefetch_challenges');

      return prefetchedCount;
    } catch (e) {
      print('Error prefetching challenges: $e');
      _failedPrefetches++;
      return 0;
    }
  }

  /// Prefetch ranking data
  Future<bool> prefetchRankings({
    String period = 'daily',
    int limit = 50,
  }) async {
    if (!_strategy.enableRankingPrefetch) return false;

    try {
      // In real implementation, would fetch ranking data here
      // For now, this is a placeholder for the pattern
      _successfulPrefetches++;
      _recordPrefetch('prefetch_rankings');
      return true;
    } catch (e) {
      print('Error prefetching rankings: $e');
      _failedPrefetches++;
      return false;
    }
  }

  /// Prefetch user profile and related data
  Future<bool> prefetchUserProfile(String userId) async {
    try {
      // Prefetch logic would go here
      _successfulPrefetches++;
      _recordPrefetch('prefetch_user_$userId');
      return true;
    } catch (e) {
      print('Error prefetching user profile: $e');
      _failedPrefetches++;
      return false;
    }
  }

  /// Prefetch related challenges (similar difficulty/theme)
  Future<int> prefetchRelatedChallenges(
    String challengeId, {
    String? difficulty,
  }) async {
    if (!_strategy.enableRelatedChallenges) return 0;

    int prefetchedCount = 0;

    try {
      // Fetch related challenges based on difficulty
      final challenges = await _challengeService
          .getApprovedChallenges(
            limit: _strategy.maxPrefetchItems ~/ 2,
            difficulty: difficulty,
          )
          .timeout(_strategy.prefetchTimeout);

      // Cache them
      for (final challenge in challenges) {
        _cache.setChallenge(challenge);
        prefetchedCount++;
      }

      _successfulPrefetches++;
      _recordPrefetch('prefetch_related_$challengeId');

      return prefetchedCount;
    } catch (e) {
      print('Error prefetching related challenges: $e');
      _failedPrefetches++;
      return 0;
    }
  }

  /// Aggressive prefetch for imminent user actions
  /// Call when user opens ranking/profile screens
  Future<int> prefetchScreenData(String screenName) async {
    int totalPrefetched = 0;

    try {
      switch (screenName) {
        case 'ranking':
          if (await prefetchRankings()) totalPrefetched++;
          break;
        case 'challenges':
          totalPrefetched += await prefetchNextChallenges('', limit: 15);
          break;
        case 'profile':
          // Profile prefetch would happen here
          totalPrefetched++;
          break;
      }

      _recordPrefetch('screen_prefetch_$screenName');
      return totalPrefetched;
    } catch (e) {
      print('Error prefetching screen data: $e');
      return 0;
    }
  }

  /// Optimize prefetch based on network conditions
  /// Call when network state changes
  Future<void> optimizeForNetworkConditions({
    required bool isHighBandwidth,
    required bool isMetered,
  }) async {
    // Adjust prefetch strategy based on network
    if (!isHighBandwidth || isMetered) {
      // Reduce prefetch aggressiveness
      _strategy = PrefetchStrategy(
        maxPrefetchItems: 5,
        prefetchTimeout: const Duration(seconds: 3),
        enableSmartPrefetch: !isMetered,
        enableRankingPrefetch: !isMetered,
      );
    } else {
      // Full prefetch capability
      _strategy = const PrefetchStrategy();
    }
  }

  /// Record prefetch attempt
  void _recordPrefetch(String key) {
    _prefetchHistory[key] = DateTime.now();

    // Keep history clean (max 100 entries)
    if (_prefetchHistory.length > 100) {
      final sorted = _prefetchHistory.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      _prefetchHistory.removeWhere(
        (k, v) => _prefetchHistory.length > 100 && k == sorted.first.key,
      );
    }
  }

  /// Get prefetch statistics
  Map<String, dynamic> getPrefetchStats() {
    final total = _successfulPrefetches + _failedPrefetches;
    return {
      'successful': _successfulPrefetches,
      'failed': _failedPrefetches,
      'total': total,
      'successRate': total > 0 ? (_successfulPrefetches / total) * 100 : 0.0,
      'recentPrefetches': _prefetchHistory.length,
      'maxPrefetchItems': _strategy.maxPrefetchItems,
      'lastPrefetchTime': _prefetchHistory.values.isEmpty
          ? null
          : _prefetchHistory.values.reduce(
              (a, b) => a.isAfter(b) ? a : b,
            ),
    };
  }

  /// Clear prefetch history
  void clearHistory() {
    _prefetchHistory.clear();
    _successfulPrefetches = 0;
    _failedPrefetches = 0;
  }

  /// Determine next likely action based on user pattern
  String predictNextUserAction(UserBehaviorPattern pattern) {
    // Simple pattern analysis
    if (pattern.challengesViewedToday < pattern.averageChallengesPerSession) {
      return 'challenges'; // User likely to view more challenges
    }

    if (DateTime.now().difference(pattern.lastActiveTime).inMinutes < 30) {
      return 'ranking'; // Recently active, check rankings
    }

    return 'profile'; // Check profile/stats
  }

  /// Get recommended prefetch actions
  List<String> getRecommendedPrefetchActions(UserBehaviorPattern pattern) {
    final actions = <String>[];
    final nextAction = predictNextUserAction(pattern);

    // Always prefetch next likely action
    actions.add(nextAction);

    // Add difficulty-specific prefetch
    actions.add('challenges_${pattern.preferredDifficulty}');

    // Add ranking prefetch
    if (pattern.challengesViewedToday > 5) {
      actions.add('ranking');
    }

    return actions;
  }
}
