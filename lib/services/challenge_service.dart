import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:machigai/models/index.dart';
import 'package:uuid/uuid.dart';

/// チャレンジ（問題）の管理サービス
class ChallengeService {
  static const String collectionName = 'challenges';
  static const String attemptsSubcollection = 'attempts';

  final FirebaseFirestore _firestore;

  ChallengeService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 新しいチャレンジを作成
  Future<UserGeneratedChallenge> createChallenge({
    required String creatorId,
    required String videoUrl,
    required Map<String, dynamic> editedPoint,
    required String difficulty,
  }) async {
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
    );

    await _firestore
        .collection(collectionName)
        .doc(id)
        .set(challenge.toFirestore());

    return challenge;
  }

  /// チャレンジを取得
  Future<UserGeneratedChallenge?> getChallenge(String challengeId) async {
    try {
      final doc = await _firestore
          .collection(collectionName)
          .doc(challengeId)
          .get();

      if (!doc.exists) return null;
      return UserGeneratedChallenge.fromFirestore(doc);
    } catch (e) {
      print('Error fetching challenge: $e');
      return null;
    }
  }

  /// 承認済みチャレンジを複数取得（公開用）
  Future<List<UserGeneratedChallenge>> getApprovedChallenges({
    int limit = 20,
    String? difficulty,
  }) async {
    try {
      Query query = _firestore
          .collection(collectionName)
          .where('moderationStatus', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true);

      if (difficulty != null) {
        query = query.where('difficulty', isEqualTo: difficulty);
      }

      query = query.limit(limit);

      final docs = await query.get();
      return docs.docs
          .map((doc) =>
              UserGeneratedChallenge.fromFirestore(doc as DocumentSnapshot))
          .toList();
    } catch (e) {
      print('Error fetching approved challenges: $e');
      return [];
    }
  }

  /// ユーザーが作成したチャレンジを取得
  Future<List<UserGeneratedChallenge>> getUserChallenges(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final docs = await _firestore
          .collection(collectionName)
          .where('creatorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return docs.docs
          .map((doc) =>
              UserGeneratedChallenge.fromFirestore(doc as DocumentSnapshot))
          .toList();
    } catch (e) {
      print('Error fetching user challenges: $e');
      return [];
    }
  }

  /// シェアトークンでチャレンジを取得
  Future<UserGeneratedChallenge?> getChallengeByShareToken(
    String shareToken,
  ) async {
    try {
      final docs = await _firestore
          .collection(collectionName)
          .where('shareToken', isEqualTo: shareToken)
          .limit(1)
          .get();

      if (docs.docs.isEmpty) return null;
      return UserGeneratedChallenge.fromFirestore(docs.docs.first);
    } catch (e) {
      print('Error fetching challenge by share token: $e');
      return null;
    }
  }

  /// チャレンジの状態を更新（モデレーション結果など）
  Future<void> updateChallenge(UserGeneratedChallenge challenge) async {
    try {
      await _firestore
          .collection(collectionName)
          .doc(challenge.id)
          .set(challenge.toFirestore());
    } catch (e) {
      print('Error updating challenge: $e');
      rethrow;
    }
  }

  /// チャレンジの解答数を増加
  Future<void> incrementSolveCount(String challengeId) async {
    try {
      await _firestore.collection(collectionName).doc(challengeId).update({
        'solveCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing solve count: $e');
    }
  }

  /// チャレンジを削除
  Future<void> deleteChallenge(String challengeId) async {
    try {
      await _firestore.collection(collectionName).doc(challengeId).delete();
    } catch (e) {
      print('Error deleting challenge: $e');
      rethrow;
    }
  }
}
