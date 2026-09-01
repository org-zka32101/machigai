import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:machigai/models/index.dart';

/// ユーザープロファイル管理サービス
class UserService {
  static const String collectionName = 'users';

  final FirebaseFirestore _firestore;

  UserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// ユーザープロフィールを取得
  Future<User?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection(collectionName).doc(userId).get();

      if (!doc.exists) return null;
      return User.fromFirestore(doc);
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }

  /// ユーザープロフィールを作成または更新
  Future<User> setUser(User user) async {
    try {
      await _firestore
          .collection(collectionName)
          .doc(user.id)
          .set(user.toFirestore());
      return user;
    } catch (e) {
      print('Error setting user: $e');
      rethrow;
    }
  }

  /// ユーザー表示名を更新
  Future<void> updateDisplayName(String userId, String displayName) async {
    try {
      await _firestore.collection(collectionName).doc(userId).update({
        'displayName': displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating display name: $e');
      rethrow;
    }
  }

  /// ユーザーアバター URL を更新
  Future<void> updateAvatar(String userId, String avatarUrl) async {
    try {
      await _firestore.collection(collectionName).doc(userId).update({
        'avatar': avatarUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating avatar: $e');
      rethrow;
    }
  }

  /// ユーザーの作成チャレンジ数をインクリメント
  Future<void> incrementChallengesCreated(String userId) async {
    try {
      await _firestore.collection(collectionName).doc(userId).update({
        'challengesCreated': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error incrementing challenges created: $e');
    }
  }

  /// ユーザーの解答済みチャレンジ数をインクリメント
  Future<void> incrementChallengesSolved(String userId) async {
    try {
      await _firestore.collection(collectionName).doc(userId).update({
        'challengesSolved': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error incrementing challenges solved: $e');
    }
  }

  /// ユーザーのスコアを更新
  Future<void> addScore(String userId, int points) async {
    try {
      await _firestore.collection(collectionName).doc(userId).update({
        'totalScore': FieldValue.increment(points),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding score: $e');
    }
  }

  /// ユーザーのストリークを更新
  Future<void> updateStreak(
    String userId, {
    required int currentStreak,
    required int longestStreak,
  }) async {
    try {
      await _firestore.collection(collectionName).doc(userId).update({
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating streak: $e');
    }
  }

  /// ユーザーレベルを計算（スコアベース）
  static int calculateLevel(int totalScore) {
    // レベル = 総スコア / 500
    return (totalScore ~/ 500) + 1;
  }

  /// ユーザーの成功率を計算（別途 ChallengeAttemptService で計算）
  Future<double> calculateSuccessRate(String userId) async {
    // ChallengeAttemptService.getUserSuccessRate を呼び出す
    // ここでは外部サービスへの依存を避けるため、呼び出し元で計算
    return 0.0;
  }

  /// 複数ユーザーを取得（検索用）
  Future<List<User>> searchUsers(String query, {int limit = 20}) async {
    try {
      final docs = await _firestore
          .collection(collectionName)
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThan: '${query}z')
          .limit(limit)
          .get();

      return docs.docs
          .map((doc) => User.fromFirestore(doc as DocumentSnapshot))
          .toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }
}
