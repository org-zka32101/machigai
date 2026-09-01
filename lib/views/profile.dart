import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:machigai/viewmodels/index.dart';

/// プロフィール画面
/// ユーザー統計、ストリーク、アチーブメントを表示
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserIdAsync = ref.watch(currentUserIdProvider);

    return currentUserIdAsync.when(
      data: (userId) {
        if (userId == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('プロフィール')),
            body: const Center(
              child: Text('ログインしてください'),
            ),
          );
        }
        return _ProfileContent(userId: userId);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('プロフィール')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('プロフィール')),
        body: Center(
          child: Text('エラー: $error'),
        ),
      ),
    );
  }
}

/// プロフィール画面の内容
class _ProfileContent extends ConsumerWidget {
  final String userId;

  const _ProfileContent({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider(userId));
    final successRateAsync = ref.watch(userSuccessRateProvider(userId));

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('プロフィール')),
            body: const Center(
              child: Text('ユーザー情報を取得できません'),
            ),
          );
        }

        return successRateAsync.when(
          data: (successRate) => _buildProfileScaffold(
            context,
            user,
            successRate,
          ),
          loading: () => Scaffold(
            appBar: AppBar(title: const Text('プロフィール')),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Scaffold(
            appBar: AppBar(title: const Text('プロフィール')),
            body: Center(
              child: Text('成功率の取得に失敗: $error'),
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('プロフィール')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('プロフィール')),
        body: Center(
          child: Text('エラー: $error'),
        ),
      ),
    );
  }

  Widget _buildProfileScaffold(
    BuildContext context,
    dynamic user,
    double successRate,
  ) {
    final userProfile = _MockUserProfile(
      userName: user.displayName,
      userAvatar: '😎', // TODO: Real avatar from user.avatar
      level: user.level,
      totalScore: user.totalScore,
      currentStreak: user.currentStreak,
      longestStreak: user.longestStreak,
      challengesCreated: user.challengesCreated,
      challengesSolved: user.challengesSolved,
      successRate: (successRate * 100).clamp(0.0, 100.0),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('設定画面（実装予定）'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ユーザーヘッダー
              _UserHeader(profile: userProfile),

              const SizedBox(height: 24),

              // ストリークカード
              _StreakCard(
                currentStreak: userProfile.currentStreak,
                longestStreak: userProfile.longestStreak,
              ),

              const SizedBox(height: 24),

              // 統計グリッド
              _StatsGrid(profile: userProfile),

              const SizedBox(height: 24),

              // アチーブメント
              _AchievementsSection(achievements: userProfile.achievements),

              const SizedBox(height: 24),

              // 最近のアクティビティ
              _RecentActivitySection(),

              const SizedBox(height: 32),

              // ログアウトボタン
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('ログアウト'),
                        content: const Text('ログアウトしますか？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('キャンセル'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('ログアウトしました'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            child: const Text('ログアウト'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('ログアウト'),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// ユーザーヘッダー
class _UserHeader extends StatelessWidget {
  final _MockUserProfile profile;

  const _UserHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[400]!, Colors.purple[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // アバター
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              profile.userAvatar,
              style: const TextStyle(fontSize: 48),
            ),
          ),

          const SizedBox(height: 16),

          // ユーザー名
          Text(
            profile.userName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 8),

          // レベル表示
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.star,
                color: Colors.amber[300],
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                'レベル ${profile.level}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 総スコア
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '総スコア: ${profile.totalScore}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ストリークカード
class _StreakCard extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;

  const _StreakCard({
    required this.currentStreak,
    required this.longestStreak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department,
                color: Colors.orange[600],
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '連続ログイン',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[900],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '現在のストリーク',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currentStreak 日',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '最長ストリーク',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$longestStreak 日',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // プログレスバー
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: longestStreak > 0 ? currentStreak / longestStreak : 0,
              minHeight: 6,
              backgroundColor: Colors.orange[200],
              valueColor: AlwaysStoppedAnimation(Colors.orange[600]),
            ),
          ),
        ],
      ),
    );
  }
}

/// 統計グリッド
class _StatsGrid extends StatelessWidget {
  final _MockUserProfile profile;

  const _StatsGrid({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          _StatCard(
            icon: Icons.edit,
            iconColor: Colors.blue,
            label: '作成した問題',
            value: '${profile.challengesCreated}',
          ),
          _StatCard(
            icon: Icons.check_circle,
            iconColor: Colors.green,
            label: '解いた問題',
            value: '${profile.challengesSolved}',
          ),
          _StatCard(
            icon: Icons.trending_up,
            iconColor: Colors.purple,
            label: '正答率',
            value: '${profile.successRate.toStringAsFixed(1)}%',
          ),
          _StatCard(
            icon: Icons.star,
            iconColor: Colors.amber,
            label: '総スコア',
            value: '${profile.totalScore}',
          ),
        ],
      ),
    );
  }
}

/// 統計カード
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 28,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// アチーブメントセクション
class _AchievementsSection extends StatelessWidget {
  final List<_Achievement> achievements;

  const _AchievementsSection({required this.achievements});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'アチーブメント',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return _AchievementBadge(achievement: achievement);
            },
          ),
        ],
      ),
    );
  }
}

/// アチーブメントバッジ
class _AchievementBadge extends StatelessWidget {
  final _Achievement achievement;

  const _AchievementBadge({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(achievement.name),
            content: Text(achievement.description),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('閉じる'),
              ),
            ],
          ),
        );
      },
      child: Tooltip(
        message: achievement.name,
        child: Container(
          decoration: BoxDecoration(
            color: achievement.unlocked ? Colors.amber[100] : Colors.grey[200],
            border: Border.all(
              color: achievement.unlocked
                  ? Colors.amber[400]!
                  : Colors.grey[400]!,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  achievement.icon,
                  style: const TextStyle(fontSize: 28),
                ),
                if (!achievement.unlocked)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 最近のアクティビティセクション
class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection();

  @override
  Widget build(BuildContext context) {
    final activities = [
      'レベル 12 に達成した',
      '7日連続ログインを達成！',
      '「高難度問題作成者」バッジを獲得',
      '問題を 15 個作成した',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '最近のアクティビティ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...activities.asMap().entries.map((entry) {
            final activity = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      activity,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// アチーブメント（内部モデル）
class _Achievement {
  final String name;
  final String description;
  final String icon;
  final bool unlocked;

  _Achievement({
    required this.name,
    required this.description,
    required this.icon,
    required this.unlocked,
  });
}

/// モックユーザープロフィール
class _MockUserProfile {
  final String userName;
  final String userAvatar;
  final int level;
  final int totalScore;
  final int currentStreak;
  final int longestStreak;
  final int challengesCreated;
  final int challengesSolved;
  final double successRate;

  late final List<_Achievement> achievements = [
    _Achievement(
      name: 'ファーストステップ',
      description: '最初の問題を作成した',
      icon: '🎯',
      unlocked: true,
    ),
    _Achievement(
      name: 'ウィークウォーリア',
      description: '7日連続ログイン',
      icon: '🔥',
      unlocked: true,
    ),
    _Achievement(
      name: 'マンスマスター',
      description: '30日連続ログイン',
      icon: '👑',
      unlocked: false,
    ),
    _Achievement(
      name: 'クリエイター',
      description: '10個の問題を作成',
      icon: '🎬',
      unlocked: true,
    ),
    _Achievement(
      name: 'スピードランナー',
      description: '10秒以内に解く',
      icon: '⚡',
      unlocked: false,
    ),
    _Achievement(
      name: 'パーフェクト',
      description: '100連勝達成',
      icon: '💯',
      unlocked: false,
    ),
    _Achievement(
      name: '人気者',
      description: '友達が 5 人以上',
      icon: '⭐',
      unlocked: true,
    ),
    _Achievement(
      name: 'エキスパート',
      description: 'スコア 50,000 達成',
      icon: '🏆',
      unlocked: false,
    ),
  ];

  _MockUserProfile({
    required this.userName,
    required this.userAvatar,
    required this.level,
    required this.totalScore,
    required this.currentStreak,
    required this.longestStreak,
    required this.challengesCreated,
    required this.challengesSolved,
    required this.successRate,
  });
}
