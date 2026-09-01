import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:machigai/models/index.dart';
import 'package:machigai/viewmodels/index.dart';

/// ランキング画面
/// ユーザーの順位と友達のランキングを表示
class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserIdAsync = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ランキング'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '日間'),
            Tab(text: '週間'),
            Tab(text: '全期間'),
          ],
        ),
      ),
      body: SafeArea(
        child: currentUserIdAsync.when(
          data: (userId) {
            if (userId == null) {
              return const Center(
                child: Text('ログインしてください'),
              );
            }
            return TabBarView(
              controller: _tabController,
              children: [
                // 日間ランキング
                _RankingTabContent(
                  tabType: 'daily',
                  userId: userId,
                ),
                // 週間ランキング
                _RankingTabContent(
                  tabType: 'weekly',
                  userId: userId,
                ),
                // 全期間ランキング
                _RankingTabContent(
                  tabType: 'alltime',
                  userId: userId,
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Text('エラー: $error'),
          ),
        ),
      ),
    );
  }
}

/// ランキングタブコンテンツ
class _RankingTabContent extends ConsumerWidget {
  final String tabType;
  final String userId;

  const _RankingTabContent({
    required this.tabType,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 選択されたランキングタイプに応じたプロバイダーを選択
    late final AsyncValue<List<Ranking>> rankingsAsync;
    late final AsyncValue<Ranking?> userRankingAsync;

    switch (tabType) {
      case 'daily':
        rankingsAsync = ref.watch(dailyRankingProvider);
        userRankingAsync = ref.watch(userRankingProvider(userId));
        break;
      case 'weekly':
        rankingsAsync = ref.watch(weeklyRankingProvider);
        userRankingAsync = ref.watch(userRankingProvider(userId));
        break;
      case 'alltime':
        rankingsAsync = ref.watch(allTimeRankingProvider);
        userRankingAsync = ref.watch(userRankingProvider(userId));
        break;
      default:
        rankingsAsync = ref.watch(allTimeRankingProvider);
        userRankingAsync = ref.watch(userRankingProvider(userId));
    }

    return rankingsAsync.when(
      data: (rankings) {
        return userRankingAsync.when(
          data: (userRanking) {
            return CustomScrollView(
              slivers: [
                // ユーザーのランク表示
                if (userRanking != null)
                  SliverToBoxAdapter(
                    child: _UserRankCard(
                      ranking: userRanking,
                    ),
                  ),

                // ランキングリスト
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final ranking = rankings[index];
                      final isUserRank = ranking.userId == userId;

                      return _RankingTile(
                        rank: index + 1,
                        ranking: ranking,
                        isUserRank: isUserRank,
                      );
                    },
                    childCount: rankings.length,
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Text('ユーザーランクの取得に失敗: $error'),
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Text('ランキングの取得に失敗: $error'),
      ),
    );
  }
}

/// ユーザーランクカード
class _UserRankCard extends StatelessWidget {
  final Ranking ranking;

  const _UserRankCard({
    required this.ranking,
  });

  @override
  Widget build(BuildContext context) {
    final changeIndicator = ranking.scoreChange > 0
        ? '↑ ${ranking.scoreChange}位上昇'
        : ranking.scoreChange < 0
            ? '↓ ${(-ranking.scoreChange).abs()}位下降'
            : '→ 変わらず';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 順位表示
              Column(
                children: [
                  const Text(
                    'あなたの順位',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '#${ranking.rank}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 24),

              // ユーザー情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '😎', // TODO: Load real avatar from user profile
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ranking.userName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'スコア: ${ranking.score}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ランク上昇インジケータ with Pulse animation
          Stack(
            alignment: Alignment.center,
            children: [
              // Pulse Lottie animation (only show if rank changed)
              if (ranking.scoreChange != 0)
                SizedBox(
                  width: 120,
                  height: 40,
                  child: Lottie.asset(
                    'assets/animations/pulse.json',
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                ),
              // Rank change indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      ranking.scoreChange > 0
                          ? Icons.trending_up
                          : ranking.scoreChange < 0
                              ? Icons.trending_down
                              : Icons.trending_flat,
                      size: 16,
                      color: ranking.scoreChange > 0
                          ? Colors.lightGreen
                          : ranking.scoreChange < 0
                              ? Colors.red[300]
                              : Colors.grey[300],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      changeIndicator,
                      style: TextStyle(
                        fontSize: 12,
                        color: ranking.scoreChange > 0
                            ? Colors.lightGreen
                            : ranking.scoreChange < 0
                                ? Colors.red[300]
                                : Colors.grey[300],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ランキングタイル
class _RankingTile extends StatelessWidget {
  final int rank;
  final Ranking ranking;
  final bool isUserRank;

  const _RankingTile({
    required this.rank,
    required this.ranking,
    required this.isUserRank,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isUserRank
            ? Colors.blue[50]
            : (ranking.isFriend ? Colors.purple[50] : Colors.white),
        border: isUserRank
            ? Border.all(color: Colors.blue[300]!, width: 2)
            : (ranking.isFriend
                ? Border.all(color: Colors.purple[200]!)
                : Border.all(color: Colors.grey[200]!)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // ランク表示
            SizedBox(
              width: 40,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getRankColor(rank),
                ),
              ),
            ),

            // ユーザー情報
            Expanded(
              child: Row(
                children: [
                  Text(
                    '😎', // TODO: Load real avatar from user profile
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                ranking.userName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (ranking.isFriend)
                              Container(
                                margin:
                                    const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple[100],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  '友達',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.purple,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${ranking.score} pt',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // スコア＋ランク変動
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${ranking.score} pt',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (ranking.scoreChange > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_upward,
                        size: 12,
                        color: Colors.green,
                      ),
                      SizedBox(
                        width: 20,
                        child: Text(
                          '${ranking.scoreChange}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  )
                else if (ranking.scoreChange < 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_downward,
                        size: 12,
                        color: Colors.red,
                      ),
                      SizedBox(
                        width: 20,
                        child: Text(
                          '${ranking.scoreChange.abs()}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  )
                else
                  const SizedBox(
                    width: 20,
                    child: Text(
                      '−',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    return switch (rank) {
      1 => Colors.amber,
      2 => Colors.grey,
      3 => Colors.brown,
      _ => Colors.grey[700] ?? Colors.grey,
    };
  }
}
