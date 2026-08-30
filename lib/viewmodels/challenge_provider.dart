import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:machigai/models/index.dart';
import 'package:machigai/services/index.dart';

/// チャレンジ関連のProviders

/// ChallengeServiceのProvider
final challengeServiceProvider = Provider((ref) {
  return ChallengeService();
});

/// 承認済みチャレンジ一覧（難易度別）
final approvedChallengesProvider = FutureProvider.family<
    List<UserGeneratedChallenge>,
    String?>(
  (ref, difficulty) async {
    final service = ref.watch(challengeServiceProvider);
    return service.getApprovedChallenges(difficulty: difficulty);
  },
);

/// ユーザーが作成したチャレンジ一覧
final userChallengesProvider =
    FutureProvider.family<List<UserGeneratedChallenge>, String>(
  (ref, userId) async {
    final service = ref.watch(challengeServiceProvider);
    return service.getUserChallenges(userId);
  },
);

/// シェアトークンからチャレンジを取得
final challengeByShareTokenProvider =
    FutureProvider.family<UserGeneratedChallenge?, String>(
  (ref, shareToken) async {
    final service = ref.watch(challengeServiceProvider);
    return service.getChallengeByShareToken(shareToken);
  },
);

/// 特定のチャレンジを取得
final challengeDetailProvider =
    FutureProvider.family<UserGeneratedChallenge?, String>(
  (ref, challengeId) async {
    final service = ref.watch(challengeServiceProvider);
    return service.getChallenge(challengeId);
  },
);

/// チャレンジ作成状態管理
class ChallengeCreateState {
  final UserGeneratedChallenge? challenge;
  final bool isLoading;
  final String? error;

  ChallengeCreateState({
    this.challenge,
    this.isLoading = false,
    this.error,
  });

  ChallengeCreateState copyWith({
    UserGeneratedChallenge? challenge,
    bool? isLoading,
    String? error,
  }) {
    return ChallengeCreateState(
      challenge: challenge ?? this.challenge,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// チャレンジ作成ViewModel
final challengeCreateProvider =
    StateNotifierProvider<ChallengeCreateNotifier, ChallengeCreateState>(
  (ref) => ChallengeCreateNotifier(ref),
);

class ChallengeCreateNotifier extends StateNotifier<ChallengeCreateState> {
  final Ref _ref;

  ChallengeCreateNotifier(this._ref) : super(ChallengeCreateState());

  /// チャレンジを作成
  Future<void> createChallenge({
    required String userId,
    required String videoUrl,
    required Map<String, dynamic> editedPoint,
    required String difficulty,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = _ref.read(challengeServiceProvider);
      final challenge = await service.createChallenge(
        creatorId: userId,
        videoUrl: videoUrl,
        editedPoint: editedPoint,
        difficulty: difficulty,
      );

      state = state.copyWith(
        challenge: challenge,
        isLoading: false,
      );

      // Analytics記録
      await AnalyticsService.trackDailyChallengeCompleted(0);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// チャレンジの解答数を増加
  Future<void> incrementSolveCount(String challengeId) async {
    try {
      final service = _ref.read(challengeServiceProvider);
      await service.incrementSolveCount(challengeId);
    } catch (e) {
      print('Error incrementing solve count: $e');
    }
  }
}
