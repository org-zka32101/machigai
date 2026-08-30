import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// ホーム画面
/// Aha Moment最短経路の分岐点
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧩 まちがいラボ'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ロゴ/ウェルカム
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      const Text(
                        '間違い探し',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '友達を「ひっかける」楽しさ',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // CTA: 出題（メイン）
                _HomeButton(
                  label: '問題を作る',
                  subtitle: '動画を編集して友達に出題',
                  icon: Icons.edit,
                  onPressed: () => context.push('/template-select'),
                  isPrimary: true,
                ),

                const SizedBox(height: 12),

                // CTA: 解答
                _HomeButton(
                  label: '問題を解く',
                  subtitle: 'シェアされた問題に挑戦',
                  icon: Icons.play_arrow,
                  onPressed: () => context.push('/solve'),
                ),

                const SizedBox(height: 12),

                // CTA: ランキング
                _HomeButton(
                  label: 'ランキング',
                  subtitle: '友達と競う',
                  icon: Icons.trending_up,
                  onPressed: () => context.push('/ranking'),
                ),

                const SizedBox(height: 12),

                // CTA: プロフィール
                _HomeButton(
                  label: 'プロフィール',
                  subtitle: 'ストリーク・スコア',
                  icon: Icons.person,
                  onPressed: () => context.push('/profile'),
                ),

                const SizedBox(height: 32),

                // 情報セクション
                _InfoCard(
                  title: 'Aha Moment',
                  description: '3分以内に問題を作って友達に出題 → 反応を見る',
                  color: Colors.blue[50],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ホームボタン
class _HomeButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _HomeButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isPrimary
                ? Theme.of(context).primaryColor
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: isPrimary
                ? null
                : Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPrimary
                      ? Colors.white.withOpacity(0.2)
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isPrimary ? Colors.white : Colors.grey[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isPrimary ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isPrimary
                            ? Colors.white.withOpacity(0.8)
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: isPrimary ? Colors.white : Colors.grey[600],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 情報カード
class _InfoCard extends StatelessWidget {
  final String title;
  final String description;
  final Color? color;

  const _InfoCard({
    required this.title,
    required this.description,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
