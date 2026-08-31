import 'package:cloud_firestore/cloud_firestore.dart';

/// ユーザーモデル
class User {
  final String id;
  final String displayName;
  final DateTime createdAt;
  final DateTime lastLogin;
  final int streak; // 現在のストリーク日数
  final int maxStreak; // 最大ストリーク日数
  final int totalScore;
  final String? favoriteGenre;

  User({
    required this.id,
    required this.displayName,
    required this.createdAt,
    required this.lastLogin,
    this.streak = 0,
    this.maxStreak = 0,
    this.totalScore = 0,
    this.favoriteGenre,
  });

  /// Firestoreから復元
  factory User.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return User(
      id: doc.id,
      displayName: data['displayName'] ?? 'Player',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now(),
      streak: data['streak'] ?? 0,
      maxStreak: data['maxStreak'] ?? 0,
      totalScore: data['totalScore'] ?? 0,
      favoriteGenre: data['favoriteGenre'],
    );
  }

  /// Firestoreへの変換
  Map<String, dynamic> toFirestore() => {
        'displayName': displayName,
        'createdAt': Timestamp.fromDate(createdAt),
        'lastLogin': Timestamp.fromDate(lastLogin),
        'streak': streak,
        'maxStreak': maxStreak,
        'totalScore': totalScore,
        'favoriteGenre': favoriteGenre,
      };

  /// コピーメソッド
  User copyWith({
    String? id,
    String? displayName,
    DateTime? createdAt,
    DateTime? lastLogin,
    int? streak,
    int? maxStreak,
    int? totalScore,
    String? favoriteGenre,
  }) {
    return User(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      streak: streak ?? this.streak,
      maxStreak: maxStreak ?? this.maxStreak,
      totalScore: totalScore ?? this.totalScore,
      favoriteGenre: favoriteGenre ?? this.favoriteGenre,
    );
  }
}
