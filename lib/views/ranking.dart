import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:machigai/models/index.dart';
import 'package:machigai/services/ranking_service.dart';

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
    final rankingService = RankingService();

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
        child: TabBarView(
          controller: _tabController,
          children: [
            // 日間ランキング
            _RankingTabContent(
              tabType: 'daily',
              rankingService: rankingService,
            ),
            // 週間ランキング
            _RankingTabContent(
              tabType: 'weekly',
              rankingService: rankingService,
            ),
            // 全期間ランキング
            _RankingTabContent(
              tabType: 'alltime',
              rankingService: rankingService,
            ),
          ],
        ),
      ),
    );
  }
}

/// ランキングタブコンテンツ
class _RankingTabContent extends StatelessWidget {
  final String tabType;
  final RankingService rankingService;

  const _RankingTabContent({
    required this.tabType,
    required this.rankingService,
  });

  @override
  Widget build(BuildContext context) {
    // ダミーランキングデータ
    final mockRankings = _generateMockRankings();
    final userRank = 15; // ダミー：ユーザーのランク

    return CustomScrollView(
      slivers: [
        // ユーザーのランク表示
        SliverToBoxAdapter(
          child: _UserRankCard(
            userRank: userRank,
            userScore: 2850,
            userAvatar: '👤',
            userName: 'あなた',
          ),
        ),

        // ランキングリスト
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final ranking = mockRankings[index];
              final isUserRank = index + 1 == userRank;

              return _RankingTile(
                rank: index + 1,
                ranking: ranking,
                isUserRank: isUserRank,
              );
            },
            childCount: mockRankings.length,
          ),
        ),
      ],
    );
  }

  List<RankingData> _generateMockRankings() {
    return List.generate(
      50,
      (index) => RankingData(
        rank: index + 1,
        userName: 'ユーザー${index + 1}',
        userAvatar: _getRandomEmoji(),
        score: 5000 - (index * 100),
        changeRank: index % 3 == 0 ? 1 : (index % 2 == 0 ? -1 : 0),
        isFriend: index < 5, // 最初の5人は友達
      ),
    );
  }

  String _getRandomEmoji() {
    final emojis = ['😀', '😎', '🥳', '🤩', '😍', '🤔', '😏', '🎯'];
    return emojis[DateTime.now().microsecond % emojis.length];
  }
}

/// ユーザーランクカード
class _UserRankCard extends StatelessWidget {
  final int userRank;
  final int userScore;
  final String userAvatar;
  final String userName;

  const _UserRankCard({
    required this.userRank,
    required this.userScore,
    required this.userAvatar,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
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
                    '#$userRank',
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
                          userAvatar,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'スコア: $userScore',
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

          // ランク上昇インジケータ
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up,
                  size: 16,
                  color: Colors.lightGreen,
                ),
                SizedBox(width: 4),
                Text(
                  '↑ 3位上昇',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.lightGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ランキングタイル
class _RankingTile extends StatelessWidget {
  final int rank;
  final RankingData ranking;
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
                    ranking.userAvatar,
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
                if (ranking.changeRank > 0)
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
                          '${ranking.changeRank}',
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
                else if (ranking.changeRank < 0)
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
                          '${ranking.changeRank.abs()}',
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

/// ランキングデータモデル（ダミー用）
class RankingData {
  final int rank;
  final String userName;
  final String userAvatar;
  final int score;
  final int changeRank;
  final bool isFriend;

  RankingData({
    required this.rank,
    required this.userName,
    required this.userAvatar,
    required this.score,
    required this.changeRank,
    required this.isFriend,
  });
}
