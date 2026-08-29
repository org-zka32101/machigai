import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:machigai/models/index.dart';
import 'package:uuid/uuid.dart';

/// チャレンジ解答記録サービス
class ChallengeAttemptService {
  static const String collectionName = 'attempts';

  final FirebaseFirestore _firestore;

  ChallengeAttemptService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 解答を記録
  Future<ChallengeAttempt> recordAttempt({
    required String challengeId,
    required String solverId,
    required bool isCorrect,
    required int solveTimeSeconds,
    required int score,
  }) async {
    final attemptId = const Uuid().v4();
    final now = DateTime.now();

    final attempt = ChallengeAttempt(
      attemptId: attemptId,
      challengeId: challengeId,
      solverId: solverId,
      isCorrect: isCorrect,
      solveTimeSeconds: solveTimeSeconds,
      score: score,
      createdAt: now,
    );

    await _firestore
        .collection(collectionName)
        .doc(attemptId)
        .set(attempt.toFirestore());

    return attempt;
  }

  /// ユーザーの解答履歴を取得
  Future<List<ChallengeAttempt>> getUserAttempts(
    String solverId, {
    int limit = 100,
  }) async {
    try {
      final docs = await _firestore
          .collection(collectionName)
          .where('solverId', isEqualTo: solverId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return docs.docs
          .map((doc) => ChallengeAttempt.fromFirestore(doc as DocumentSnapshot))
          .toList();
    } catch (e) {
      print('Error fetching user attempts: $e');
      return [];
    }
  }

  /// チャレンジに対する解答結果を取得
  Future<List<ChallengeAttempt>> getChallengeAttempts(
    String challengeId,
  ) async {
    try {
      final docs = await _firestore
          .collection(collectionName)
          .where('challengeId', isEqualTo: challengeId)
          .orderBy('createdAt', descending: true)
          .get();

      return docs.docs
          .map((doc) => ChallengeAttempt.fromFirestore(doc as DocumentSnapshot))
          .toList();
    } catch (e) {
      print('Error fetching challenge attempts: $e');
      return [];
    }
  }

  /// ユーザーの正解率を計算
  Future<double> getUserSuccessRate(String solverId) async {
    try {
      final docs = await _firestore
          .collection(collectionName)
          .where('solverId', isEqualTo: solverId)
          .get();

      if (docs.docs.isEmpty) return 0.0;

      final correct = docs.docs
          .where((doc) => doc['isCorrect'] == true)
          .length;

      return correct / docs.docs.length;
    } catch (e) {
      print('Error calculating success rate: $e');
      return 0.0;
    }
  }
}
