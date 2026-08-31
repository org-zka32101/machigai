import 'package:cloud_firestore/cloud_firestore.dart';

/// 日付ごとのストリーク記録
class DailyStreak {
  final String userId;
  final DateTime date;
  final bool completed; // その日にプレイしたか
  final int score;

  DailyStreak({
    required this.userId,
    required this.date,
    required this.completed,
    required this.score,
  });

  /// Firestoreから復元
  factory DailyStreak.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return DailyStreak(
      userId: data['userId'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completed: data['completed'] ?? false,
      score: data['score'] ?? 0,
    );
  }

  /// Firestoreへの変換
  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'date': Timestamp.fromDate(date),
        'completed': completed,
        'score': score,
      };
}
