import 'package:cloud_firestore/cloud_firestore.dart';

/// ユーザーモデル
class User {
  final String id;
  final String displayName;
  final String? avatar; // Avatar URL
  final DateTime createdAt;
  final DateTime lastLogin;
  final DateTime? updatedAt;
  final int currentStreak; // 現在のストリーク日数
  final int longestStreak; // 最大ストリーク日数
  final int totalScore;
  final int challengesCreated; // 作成したチャレンジ数
  final int challengesSolved; // 解答したチャレンジ数
  final String? favoriteGenre;

  User({
    required this.id,
    required this.displayName,
    this.avatar,
    required this.createdAt,
    required this.lastLogin,
    this.updatedAt,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalScore = 0,
    this.challengesCreated = 0,
    this.challengesSolved = 0,
    this.favoriteGenre,
  });

  /// ユーザーレベル（スコアから計算）
  int get level => (totalScore ~/ 500) + 1;

  /// 成功率（別途計算する必要がある）
  double get successRate =>
      challengesSolved > 0 ? (challengesCreated / challengesSolved) : 0.0;

  /// Firestoreから復元
  factory User.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return User(
      id: doc.id,
      displayName: data['displayName'] ?? 'Player',
      avatar: data['avatar'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      totalScore: data['totalScore'] ?? 0,
      challengesCreated: data['challengesCreated'] ?? 0,
      challengesSolved: data['challengesSolved'] ?? 0,
      favoriteGenre: data['favoriteGenre'],
    );
  }

  /// Firestoreへの変換
  Map<String, dynamic> toFirestore() => {
        'displayName': displayName,
        'avatar': avatar,
        'createdAt': Timestamp.fromDate(createdAt),
        'lastLogin': Timestamp.fromDate(lastLogin),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'totalScore': totalScore,
        'challengesCreated': challengesCreated,
        'challengesSolved': challengesSolved,
        'favoriteGenre': favoriteGenre,
      };

  /// コピーメソッド
  User copyWith({
    String? id,
    String? displayName,
    String? avatar,
    DateTime? createdAt,
    DateTime? lastLogin,
    DateTime? updatedAt,
    int? currentStreak,
    int? longestStreak,
    int? totalScore,
    int? challengesCreated,
    int? challengesSolved,
    String? favoriteGenre,
  }) {
    return User(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      updatedAt: updatedAt ?? this.updatedAt,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalScore: totalScore ?? this.totalScore,
      challengesCreated: challengesCreated ?? this.challengesCreated,
      challengesSolved: challengesSolved ?? this.challengesSolved,
      favoriteGenre: favoriteGenre ?? this.favoriteGenre,
    );
  }
}
