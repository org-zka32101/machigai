import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:machigai/models/index.dart';
import 'package:machigai/services/index.dart';

/// ランキングサービスプロバイダー
final rankingServiceProvider = Provider((_) => RankingService());

/// デイリーランキング取得プロバイダー
final dailyRankingProvider = FutureProvider<List<Ranking>>((ref) async {
  final rankingService = ref.watch(rankingServiceProvider);
  return rankingService.getDailyRankingTop(limit: 50);
});

/// ウィークリーランキング取得プロバイダー
final weeklyRankingProvider = FutureProvider<List<Ranking>>((ref) async {
  final rankingService = ref.watch(rankingServiceProvider);
  return rankingService.getWeeklyRankingTop(limit: 50);
});

/// オールタイムランキング取得プロバイダー
final allTimeRankingProvider = FutureProvider<List<Ranking>>((ref) async {
  final rankingService = ref.watch(rankingServiceProvider);
  return rankingService.getAllTimeRankingTop(limit: 50);
});

/// ユーザーランキング取得プロバイダー
final userRankingProvider =
    FutureProvider.family<Ranking?, String>((ref, userId) async {
  final rankingService = ref.watch(rankingServiceProvider);
  return rankingService.getUserRanking(userId);
});

/// ユーザーサービスプロバイダー
final userServiceProvider = Provider((_) => UserService());

/// ユーザープロフィール取得プロバイダー
final userProfileProvider =
    FutureProvider.family<User?, String>((ref, userId) async {
  final userService = ref.watch(userServiceProvider);
  return userService.getUser(userId);
});

/// チャレンジサービスプロバイダー
final challengeServiceProvider = Provider((_) => ChallengeService());

/// チャレンジ試行サービスプロバイダー
final challengeAttemptServiceProvider =
    Provider((_) => ChallengeAttemptService());

/// ユーザーのチャレンジ一覧プロバイダー
final userChallengesProvider =
    FutureProvider.family<List<UserGeneratedChallenge>, String>(
  (ref, userId) async {
    final challengeService = ref.watch(challengeServiceProvider);
    return challengeService.getUserChallenges(userId, limit: 50);
  },
);

/// ユーザーの試行履歴プロバイダー
final userAttemptsProvider =
    FutureProvider.family<List<ChallengeAttempt>, String>(
  (ref, userId) async {
    final challengeAttemptService =
        ref.watch(challengeAttemptServiceProvider);
    return challengeAttemptService.getUserAttempts(userId, limit: 100);
  },
);

/// ユーザーの成功率プロバイダー
final userSuccessRateProvider =
    FutureProvider.family<double, String>((ref, userId) async {
  final challengeAttemptService =
      ref.watch(challengeAttemptServiceProvider);
  return challengeAttemptService.getUserSuccessRate(userId);
});

/// 承認済みチャレンジ取得プロバイダー
final approvedChallengesProvider =
    FutureProvider.family<List<UserGeneratedChallenge>, String?>((
  ref,
  difficulty,
) async {
  final challengeService = ref.watch(challengeServiceProvider);
  return challengeService.getApprovedChallenges(
    limit: 50,
    difficulty: difficulty,
  );
});
