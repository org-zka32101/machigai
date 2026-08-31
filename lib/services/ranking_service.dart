import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:machigai/models/index.dart';

/// ランキング計算・管理サービス
class RankingService {
  static const String rankingCollectionName = 'rankings';
  static const String streakCollectionName = 'streaks';

  final FirebaseFirestore _firestore;

  RankingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// ユーザーのランキング情報を取得
  Future<Ranking?> getUserRanking(String userId) async {
    try {
      final doc = await _firestore
          .collection(rankingCollectionName)
          .doc(userId)
          .get();

      if (!doc.exists) return null;
      return Ranking.fromFirestore(doc);
    } catch (e) {
      print('Error fetching user ranking: $e');
      return null;
    }
  }

  /// デイリーランキングトップを取得
  Future<List<Ranking>> getDailyRankingTop({int limit = 50}) async {
    try {
      final docs = await _firestore
          .collection(rankingCollectionName)
          .orderBy('dailyRank')
          .limit(limit)
          .get();

      return docs.docs
          .map((doc) => Ranking.fromFirestore(doc as DocumentSnapshot))
          .toList();
    } catch (e) {
      print('Error fetching daily ranking: $e');
      return [];
    }
  }

  /// ウィークリーランキングトップを取得
  Future<List<Ranking>> getWeeklyRankingTop({int limit = 50}) async {
    try {
      final docs = await _firestore
          .collection(rankingCollectionName)
          .orderBy('weeklyRank')
          .limit(limit)
          .get();

      return docs.docs
          .map((doc) => Ranking.fromFirestore(doc as DocumentSnapshot))
          .toList();
    } catch (e) {
      print('Error fetching weekly ranking: $e');
      return [];
    }
  }

  /// オールタイムランキングトップを取得
  Future<List<Ranking>> getAllTimeRankingTop({int limit = 50}) async {
    try {
      final docs = await _firestore
          .collection(rankingCollectionName)
          .orderBy('allTimeRank')
          .limit(limit)
          .get();

      return docs.docs
          .map((doc) => Ranking.fromFirestore(doc as DocumentSnapshot))
          .toList();
    } catch (e) {
      print('Error fetching all time ranking: $e');
      return [];
    }
  }

  /// ユーザーのストリーク情報を取得
  Future<DailyStreak?> getTodayStreak(String userId) async {
    try {
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month}-${today.day}';

      final doc = await _firestore
          .collection(streakCollectionName)
          .doc('${userId}_$dateStr')
          .get();

      if (!doc.exists) return null;
      return DailyStreak.fromFirestore(doc);
    } catch (e) {
      print('Error fetching today streak: $e');
      return null;
    }
  }

  /// ストリークを更新
  Future<void> updateStreak({
    required String userId,
    required int score,
  }) async {
    try {
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month}-${today.day}';

      final streak = DailyStreak(
        userId: userId,
        date: today,
        completed: true,
        score: score,
      );

      await _firestore
          .collection(streakCollectionName)
          .doc('${userId}_$dateStr')
          .set(streak.toFirestore());
    } catch (e) {
      print('Error updating streak: $e');
      rethrow;
    }
  }

  /// ランキングを更新（定期実行推奨）
  Future<void> updateRankings() async {
    // TODO: Firestore集計によってランキングを計算・更新
    // - デイリーランキング
    // - ウィークリーランキング
    // - オールタイムランキング
  }
}
