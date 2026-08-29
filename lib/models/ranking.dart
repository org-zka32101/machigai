import 'package:cloud_firestore/cloud_firestore.dart';

/// ランキング記録モデル
class Ranking {
  final String userId;
  final DateTime date;
  final int dailyRank;
  final int weeklyRank;
  final int allTimeRank;
  final int score;

  Ranking({
    required this.userId,
    required this.date,
    required this.dailyRank,
    required this.weeklyRank,
    required this.allTimeRank,
    required this.score,
  });

  /// Firestoreから復元
  factory Ranking.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return Ranking(
      userId: data['userId'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dailyRank: data['dailyRank'] ?? 0,
      weeklyRank: data['weeklyRank'] ?? 0,
      allTimeRank: data['allTimeRank'] ?? 0,
      score: data['score'] ?? 0,
    );
  }

  /// Firestoreへの変換
  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'date': Timestamp.fromDate(date),
        'dailyRank': dailyRank,
        'weeklyRank': weeklyRank,
        'allTimeRank': allTimeRank,
        'score': score,
      };
}
