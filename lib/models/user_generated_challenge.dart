import 'package:cloud_firestore/cloud_firestore.dart';

/// ユーザー生成の間違い探し問題モデル
class UserGeneratedChallenge {
  final String id;
  final String creatorId;
  final String videoUrl; // Firebase Storage URL
  final Map<String, dynamic> editedPoint; // 編集された座標情報 {x, y, ...}
  final String difficulty; // 'easy', 'medium', 'hard'
  final DateTime createdAt;
  final int solveCount; // 解答者数
  final double successRate; // 正解率 (0.0-1.0)
  final String shareToken; // 共有用トークン
  final String moderationStatus; // 'pending', 'approved', 'rejected'
  final String? moderationReason; // リジェクト理由（あれば）
  final double? aiScore; // AI品質スコア (0.0-100.0)

  UserGeneratedChallenge({
    required this.id,
    required this.creatorId,
    required this.videoUrl,
    required this.editedPoint,
    required this.difficulty,
    required this.createdAt,
    this.solveCount = 0,
    this.successRate = 0.0,
    required this.shareToken,
    this.moderationStatus = 'pending',
    this.moderationReason,
    this.aiScore,
  });

  /// Firestoreから復元
  factory UserGeneratedChallenge.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return UserGeneratedChallenge(
      id: doc.id,
      creatorId: data['creatorId'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      editedPoint: data['editedPoint'] ?? {},
      difficulty: data['difficulty'] ?? 'medium',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      solveCount: data['solveCount'] ?? 0,
      successRate: (data['successRate'] ?? 0.0).toDouble(),
      shareToken: data['shareToken'] ?? '',
      moderationStatus: data['moderationStatus'] ?? 'pending',
      moderationReason: data['moderationReason'],
      aiScore: data['aiScore'] != null ? (data['aiScore'] as num).toDouble() : null,
    );
  }

  /// Firestoreへの変換
  Map<String, dynamic> toFirestore() => {
        'creatorId': creatorId,
        'videoUrl': videoUrl,
        'editedPoint': editedPoint,
        'difficulty': difficulty,
        'createdAt': Timestamp.fromDate(createdAt),
        'solveCount': solveCount,
        'successRate': successRate,
        'shareToken': shareToken,
        'moderationStatus': moderationStatus,
        'moderationReason': moderationReason,
        'aiScore': aiScore,
      };

  /// コピーメソッド（状態更新用）
  UserGeneratedChallenge copyWith({
    String? id,
    String? creatorId,
    String? videoUrl,
    Map<String, dynamic>? editedPoint,
    String? difficulty,
    DateTime? createdAt,
    int? solveCount,
    double? successRate,
    String? shareToken,
    String? moderationStatus,
    String? moderationReason,
    double? aiScore,
  }) {
    return UserGeneratedChallenge(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      videoUrl: videoUrl ?? this.videoUrl,
      editedPoint: editedPoint ?? this.editedPoint,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt ?? this.createdAt,
      solveCount: solveCount ?? this.solveCount,
      successRate: successRate ?? this.successRate,
      shareToken: shareToken ?? this.shareToken,
      moderationStatus: moderationStatus ?? this.moderationStatus,
      moderationReason: moderationReason ?? this.moderationReason,
      aiScore: aiScore ?? this.aiScore,
    );
  }
}
