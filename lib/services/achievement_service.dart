import 'package:cloud_firestore/cloud_firestore.dart';

/// Achievement badge earned by users
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon; // emoji or icon name
  final String category; // 'milestone' | 'skill' | 'challenge' | 'social'
  final int requiredCount; // count to achieve
  final DateTime unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.requiredCount,
    required this.unlockedAt,
  });

  factory Achievement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Achievement(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '🏆',
      category: data['category'] ?? 'milestone',
      requiredCount: data['requiredCount'] ?? 0,
      unlockedAt: (data['unlockedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'category': category,
      'requiredCount': requiredCount,
      'unlockedAt': unlockedAt,
    };
  }
}

/// Predefined achievement definitions
class AchievementDefinition {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String category;
  final String trigger; // what action triggers this
  final int requiredCount;

  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.trigger,
    required this.requiredCount,
  });
}

/// Manager for user achievements and badges
class AchievementService {
  static const String achievementsCollection = 'user_achievements';

  final FirebaseFirestore _firestore;

  AchievementService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Predefined achievements
  static final List<AchievementDefinition> definitions = [
    // Milestone achievements
    AchievementDefinition(
      id: 'first_challenge',
      title: '挑戦開始',
      description: '最初のチャレンジを作成しました',
      icon: '🚀',
      category: 'milestone',
      trigger: 'challenge_created',
      requiredCount: 1,
    ),
    AchievementDefinition(
      id: 'creator_pro',
      title: 'クリエイター',
      description: '10個のチャレンジを作成しました',
      icon: '🎬',
      category: 'milestone',
      trigger: 'challenge_created',
      requiredCount: 10,
    ),
    AchievementDefinition(
      id: 'prolific_creator',
      title: 'プロ作成者',
      description: '50個のチャレンジを作成しました',
      icon: '🌟',
      category: 'milestone',
      trigger: 'challenge_created',
      requiredCount: 50,
    ),

    // Solver achievements
    AchievementDefinition(
      id: 'first_solve',
      title: 'チャレンジ完了',
      description: '最初のチャレンジを解きました',
      icon: '✅',
      category: 'milestone',
      trigger: 'challenge_solved',
      requiredCount: 1,
    ),
    AchievementDefinition(
      id: 'problem_solver',
      title: '問題解決者',
      description: '100個のチャレンジを解きました',
      icon: '🧩',
      category: 'milestone',
      trigger: 'challenge_solved',
      requiredCount: 100,
    ),

    // Skill achievements
    AchievementDefinition(
      id: 'accuracy_master',
      title: '正確性の達人',
      description: '連続10回正解しました',
      icon: '🎯',
      category: 'skill',
      trigger: 'perfect_streak',
      requiredCount: 10,
    ),
    AchievementDefinition(
      id: 'speed_runner',
      title: 'スピードラン',
      description: 'チャレンジを5秒以下で解きました',
      icon: '⚡',
      category: 'skill',
      trigger: 'fast_solve',
      requiredCount: 1,
    ),

    // Challenge quality achievements
    AchievementDefinition(
      id: 'quality_creator',
      title: 'クオリティ職人',
      description: 'AIスコア80以上のチャレンジを作成しました',
      icon: '💎',
      category: 'challenge',
      trigger: 'high_quality_challenge',
      requiredCount: 1,
    ),
    AchievementDefinition(
      id: 'popular_challenge',
      title: 'バズったチャレンジ',
      description: 'チャレンジが100回以上解かれました',
      icon: '📈',
      category: 'challenge',
      trigger: 'challenge_popularity',
      requiredCount: 100,
    ),

    // Social achievements
    AchievementDefinition(
      id: 'sharer',
      title: 'シェアラー',
      description: 'チャレンジをシェアしました',
      icon: '🤝',
      category: 'social',
      trigger: 'challenge_shared',
      requiredCount: 1,
    ),
    AchievementDefinition(
      id: 'community_hero',
      title: 'コミュニティのヒーロー',
      description: '10個のチャレンジをシェアしました',
      icon: '🦸',
      category: 'social',
      trigger: 'challenge_shared',
      requiredCount: 10,
    ),
  ];

  /// Get user's achievements
  Future<List<Achievement>> getUserAchievements(String userId) async {
    try {
      final docs = await _firestore
          .collection(achievementsCollection)
          .doc(userId)
          .collection('badges')
          .orderBy('unlockedAt', descending: true)
          .get();

      return docs.docs
          .map((doc) => Achievement.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching achievements: $e');
      return [];
    }
  }

  /// Check if user has specific achievement
  Future<bool> hasAchievement(String userId, String achievementId) async {
    try {
      final doc = await _firestore
          .collection(achievementsCollection)
          .doc(userId)
          .collection('badges')
          .doc(achievementId)
          .get();
      return doc.exists;
    } catch (e) {
      print('Error checking achievement: $e');
      return false;
    }
  }

  /// Unlock an achievement for user
  Future<bool> unlockAchievement(String userId, String achievementId) async {
    try {
      // Check if already unlocked
      if (await hasAchievement(userId, achievementId)) {
        return false; // Already unlocked
      }

      final def = definitions.firstWhere(
        (d) => d.id == achievementId,
        orElse: () => throw Exception('Achievement definition not found'),
      );

      final achievement = Achievement(
        id: achievementId,
        title: def.title,
        description: def.description,
        icon: def.icon,
        category: def.category,
        requiredCount: def.requiredCount,
        unlockedAt: DateTime.now(),
      );

      await _firestore
          .collection(achievementsCollection)
          .doc(userId)
          .collection('badges')
          .doc(achievementId)
          .set(achievement.toFirestore());

      return true; // Newly unlocked
    } catch (e) {
      print('Error unlocking achievement: $e');
      return false;
    }
  }

  /// Get achievement statistics for user
  Future<Map<String, int>> getAchievementStats(String userId) async {
    try {
      final achievements = await getUserAchievements(userId);

      final stats = {
        'total': achievements.length,
        'milestone': 0,
        'skill': 0,
        'challenge': 0,
        'social': 0,
      };

      for (final achievement in achievements) {
        stats[achievement.category] = (stats[achievement.category] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('Error getting achievement stats: $e');
      return {'total': 0};
    }
  }

  /// Get next achievable milestones for user
  /// This would require tracking user stats (challenges created, solved, etc.)
  Future<List<AchievementDefinition>> getNextMilestones(String userId) async {
    // TODO: Implement based on user's current stats
    // For now, return top 3 milestone achievements
    return definitions
        .where((d) => d.category == 'milestone')
        .take(3)
        .toList();
  }

  /// Batch unlock multiple achievements
  Future<int> unlockMultiple(
    String userId,
    List<String> achievementIds,
  ) async {
    int unlockedCount = 0;
    for (final id in achievementIds) {
      if (await unlockAchievement(userId, id)) {
        unlockedCount++;
      }
    }
    return unlockedCount;
  }
}
