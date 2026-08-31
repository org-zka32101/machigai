import 'package:cloud_firestore/cloud_firestore.dart';

/// チャレンジ解答記録モデル
class ChallengeAttempt {
  final String attemptId;
  final String challengeId;
  final String solverId; // 解答者ID
  final bool isCorrect;
  final int solveTimeSeconds; // 解答時間（秒）
  final int score; // スコア
  final DateTime createdAt;

  ChallengeAttempt({
    required this.attemptId,
    required this.challengeId,
    required this.solverId,
    required this.isCorrect,
    required this.solveTimeSeconds,
    required this.score,
    required this.createdAt,
  });

  /// Firestoreから復元
  factory ChallengeAttempt.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return ChallengeAttempt(
      attemptId: doc.id,
      challengeId: data['challengeId'] ?? '',
      solverId: data['solverId'] ?? '',
      isCorrect: data['isCorrect'] ?? false,
      solveTimeSeconds: data['solveTimeSeconds'] ?? 0,
      score: data['score'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Firestoreへの変換
  Map<String, dynamic> toFirestore() => {
        'challengeId': challengeId,
        'solverId': solverId,
        'isCorrect': isCorrect,
        'solveTimeSeconds': solveTimeSeconds,
        'score': score,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
