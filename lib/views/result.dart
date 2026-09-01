import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:machigai/services/index.dart';

/// リザルト画面
/// チャレンジに答えた後の結果表示（正解/不正解）
class ResultScreen extends ConsumerStatefulWidget {
  final UserGeneratedChallenge challenge;
  final bool isCorrect;
  final int solveTimeSeconds;
  final int selectedRegionIndex;

  const ResultScreen({
    required this.challenge,
    required this.isCorrect,
    required this.solveTimeSeconds,
    required this.selectedRegionIndex,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // アニメーション開始
    _animationController.forward();

    // 成功時は効果音を再生（実装予定）
    if (widget.isCorrect) {
      _playSuccessSound();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _playSuccessSound() {
    // 実装予定：sound_effect_service.playSuccessChime()
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        context.go('/');
        return false;
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),

                // 結果表示エリア
                if (widget.isCorrect)
                  _SuccessResultArea(animationController: _animationController)
                else
                  _FailureResultArea(animationController: _animationController),

                const SizedBox(height: 32),

                // スコア・統計表示
                _ResultStats(
                  challenge: widget.challenge,
                  isCorrect: widget.isCorrect,
                  solveTimeSeconds: widget.solveTimeSeconds,
                ),

                const SizedBox(height: 32),

                // アクションボタン
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 次の問題へ
                      ElevatedButton(
                        onPressed: () {
                          // ランダムなチャレンジを取得して解く
                          context.push('/solve');
                        },
                        child: const Text('次の問題へ'),
                      ),

                      const SizedBox(height: 12),

                      // 結果をシェア
                      OutlinedButton.icon(
                        icon: const Icon(Icons.share),
                        label: const Text('結果をシェア'),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('結果をシェアしました'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // ホームに戻る
                      OutlinedButton(
                        onPressed: () => context.go('/'),
                        child: const Text('ホームに戻る'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 成功結果エリア
class _SuccessResultArea extends StatelessWidget {
  final AnimationController animationController;

  const _SuccessResultArea({
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    final scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.elasticOut,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          // Confetti Lottie animation (overlaid in background)
          Positioned(
            top: -50,
            left: -50,
            right: -50,
            child: SizedBox(
              height: 300,
              child: Lottie.asset(
                'assets/animations/confetti.json',
                repeat: false,
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Main content
          Column(
            children: [
              // 成功アイコン（スケールアニメーション）
              ScaleTransition(
                scale: scaleAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 80,
                    color: Colors.green[600],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 成功メッセージ
              const Text(
                '正解です！',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),

              const SizedBox(height: 8),

              // サブメッセージ
              Text(
                '友達を「ひっかける」ことに成功！',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 24),

              // スター表示（簡易版：難易度による）
              _StarRating(difficulty: 'medium'),
            ],
          ),
        ],
      ),
    );
  }
}

/// 失敗結果エリア
class _FailureResultArea extends StatelessWidget {
  final AnimationController animationController;

  const _FailureResultArea({
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    final shakeAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.elasticIn,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Shake Lottie animation with failure icon
          Stack(
            alignment: Alignment.center,
            children: [
              // Shake Lottie animation background
              SizedBox(
                width: 200,
                height: 200,
                child: Lottie.asset(
                  'assets/animations/shake.json',
                  repeat: false,
                  fit: BoxFit.contain,
                ),
              ),
              // 失敗アイコン（シェイク）
              AnimatedBuilder(
                animation: shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(shakeAnimation.value, 0),
                    child: child,
                  );
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 80,
                    color: Colors.red[600],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 失敗メッセージ
          const Text(
            '不正解です',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),

          const SizedBox(height: 8),

          // サブメッセージ
          Text(
            '次回は見つけられるかな？',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 24),

          // 正解の説明
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border.all(color: Colors.blue[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '正解はこちら',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '編集された部分は別の場所でした',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[900],
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

/// スター表示
class _StarRating extends StatelessWidget {
  final String difficulty;

  const _StarRating({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final starCount = difficulty == 'easy'
        ? 1
        : difficulty == 'medium'
            ? 2
            : 3;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            index < starCount ? Icons.star : Icons.star_outline,
            size: 32,
            color: Colors.amber,
          ),
        ),
      ),
    );
  }
}

/// 結果統計表示
class _ResultStats extends StatelessWidget {
  final UserGeneratedChallenge challenge;
  final bool isCorrect;
  final int solveTimeSeconds;

  const _ResultStats({
    required this.challenge,
    required this.isCorrect,
    required this.solveTimeSeconds,
  });

  @override
  Widget build(BuildContext context) {
    // スコア計算（簡易版）
    final baseScore = difficulty == 'easy'
        ? 100
        : difficulty == 'medium'
            ? 200
            : 500;
    final scoreBonus = solveTimeSeconds < 30 ? 50 : 0;
    final totalScore = isCorrect ? baseScore + scoreBonus : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // スコア
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'スコア',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '+$totalScore',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isCorrect ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // 詳細統計
              _StatRow(
                label: '難易度',
                value: difficulty == 'easy'
                    ? 'イージー'
                    : difficulty == 'medium'
                        ? 'ノーマル'
                        : 'ハード',
              ),
              const SizedBox(height: 12),
              _StatRow(
                label: 'クリア時間',
                value:
                    '${(solveTimeSeconds / 60).toStringAsFixed(1)}分',
              ),
              const SizedBox(height: 12),
              _StatRow(
                label: '作成者',
                value: 'ユーザー${challenge.creatorId.substring(0, 8)}',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get difficulty => challenge.difficulty;
}

/// 統計行
class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
