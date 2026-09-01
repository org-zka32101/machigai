import 'package:cloud_firestore/cloud_firestore.dart';

/// ランキング記録モデル
class Ranking {
  final String userId;
  final String userName;
  final DateTime date;
  final int rank; // Current rank (daily/weekly/all-time depending on context)
  final int dailyRank;
  final int weeklyRank;
  final int allTimeRank;
  final int score;
  final int scoreChange; // Change from previous period
  final bool isFriend; // Is this user a friend?

  Ranking({
    required this.userId,
    required this.userName,
    required this.date,
    required this.rank,
    required this.dailyRank,
    required this.weeklyRank,
    required this.allTimeRank,
    required this.score,
    this.scoreChange = 0,
    this.isFriend = false,
  });

  /// Firestoreから復元
  factory Ranking.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return Ranking(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'User',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rank: data['rank'] ?? data['allTimeRank'] ?? 0,
      dailyRank: data['dailyRank'] ?? 0,
      weeklyRank: data['weeklyRank'] ?? 0,
      allTimeRank: data['allTimeRank'] ?? 0,
      score: data['score'] ?? 0,
      scoreChange: data['scoreChange'] ?? 0,
      isFriend: data['isFriend'] ?? false,
    );
  }

  /// Firestoreへの変換
  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'userName': userName,
        'date': Timestamp.fromDate(date),
        'rank': rank,
        'dailyRank': dailyRank,
        'weeklyRank': weeklyRank,
        'allTimeRank': allTimeRank,
        'score': score,
        'scoreChange': scoreChange,
        'isFriend': isFriend,
      };
}
