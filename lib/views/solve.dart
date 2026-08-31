import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:machigai/services/index.dart';
import 'package:machigai/viewmodels/index.dart';

/// 問題解答画面
/// ユーザーが友達から共有された問題に挑戦する画面
/// シェアトークンまたはチャレンジIDを受け取って表示
class SolveScreen extends ConsumerStatefulWidget {
  /// シェアトークン OR チャレンジID
  final String? challengeId;
  final String? shareToken;

  const SolveScreen({
    this.challengeId,
    this.shareToken,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<SolveScreen> createState() => _SolveScreenState();
}

class _SolveScreenState extends ConsumerState<SolveScreen> {
  int? selectedRegionIndex;
  bool _isSubmitting = false;
  late Stopwatch _timer;

  @override
  void initState() {
    super.initState();
    _timer = Stopwatch()..start();
  }

  @override
  void dispose() {
    _timer.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // チャレンジを取得
    final challengeAsync = widget.shareToken != null
        ? ref.watch(
            challengeByShareTokenProvider(widget.shareToken!),
          )
        : widget.challengeId != null
            ? ref.watch(
                challengeDetailProvider(widget.challengeId!),
              )
            : AsyncValue.error('No challenge ID or share token provided', null);

    return WillPopScope(
      onWillPop: () async {
        context.pop();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('問題を解く'),
          centerTitle: true,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: challengeAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (err, st) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                const Text('問題を読み込めません'),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('戻る'),
                ),
              ],
            ),
          ),
          data: (challenge) {
            if (challenge == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text('問題が見つかりません'),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('戻る'),
                    ),
                  ],
                ),
              );
            }

            return SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 難易度・タイマー
                    _ChallengeHeader(challenge: challenge, timer: _timer),

                    const SizedBox(height: 16),

                    // ビデオプレビューエリア
                    _VideoPreviewArea(
                      challenge: challenge,
                      selectedRegionIndex: selectedRegionIndex,
                    ),

                    const SizedBox(height: 24),

                    // 問題説明
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '間違い探しをしてね',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '編集された部分をクリックして探してね！',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 回答ボタングリッド（複数の編集可能領域をシミュレート）
                    _AnswerGridSelector(
                      challenge: challenge,
                      selectedIndex: selectedRegionIndex,
                      onSelected: (index) {
                        setState(() => selectedRegionIndex = index);
                      },
                    ),

                    const SizedBox(height: 32),

                    // アクションボタン
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
                            onPressed: selectedRegionIndex == null || _isSubmitting
                                ? null
                                : () => _submitAnswer(context, challenge),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('答える'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () => context.pop(),
                            child: const Text('スキップ'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              );
            );
          },
        ),
      ),
    );
  }

  void _submitAnswer(BuildContext context, UserGeneratedChallenge challenge) {
    if (selectedRegionIndex == null) return;

    setState(() => _isSubmitting = true);

    // 簡易的な答え判定（実装予定：BackendでAI判定）
    final isCorrect = selectedRegionIndex == 0; // ダミー：最初の領域が正解

    // 遅延を追加してUX向上
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      setState(() => _isSubmitting = false);

      // リザルト画面へ遷移
      context.push(
        '/result',
        extra: {
          'challenge': challenge,
          'isCorrect': isCorrect,
          'solveTimeSeconds': _timer.elapsed.inSeconds,
          'selectedRegionIndex': selectedRegionIndex,
        },
      );
    });
  }
}

/// チャレンジヘッダー（難易度・タイマー）
class _ChallengeHeader extends StatefulWidget {
  final UserGeneratedChallenge challenge;
  final Stopwatch timer;

  const _ChallengeHeader({
    required this.challenge,
    required this.timer,
  });

  @override
  State<_ChallengeHeader> createState() => _ChallengeHeaderState();
}

class _ChallengeHeaderState extends State<_ChallengeHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _timerController;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 難易度バッジ
          _DifficultyBadge(difficulty: widget.challenge.difficulty),

          const Spacer(),

          // タイマー
          StreamBuilder(
            stream:
                Stream.periodic(const Duration(milliseconds: 100), (_) => true),
            builder: (context, snapshot) {
              final elapsed = widget.timer.elapsed;
              final minutes = elapsed.inMinutes;
              final seconds = elapsed.inSeconds.remainder(60);
              final timeStr =
                  '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer,
                      size: 16,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 難易度バッジ
class _DifficultyBadge extends StatelessWidget {
  final String difficulty;

  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _getDifficultyInfo(difficulty);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  (String, Color) _getDifficultyInfo(String difficulty) {
    return switch (difficulty) {
      'easy' => ('イージー', Colors.green),
      'medium' => ('ノーマル', Colors.orange),
      'hard' => ('ハード', Colors.red),
      _ => ('不明', Colors.grey),
    };
  }
}

/// ビデオプレビューエリア
class _VideoPreviewArea extends StatelessWidget {
  final UserGeneratedChallenge challenge;
  final int? selectedRegionIndex;

  const _VideoPreviewArea({
    required this.challenge,
    this.selectedRegionIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ビデオプレースホルダー
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam,
                  size: 64,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 8),
                Text(
                  'ビデオプレビュー',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            // クリック可能な領域をオーバーレイ
            Positioned.fill(
              child: GestureDetector(
                onTapDown: (details) {
                  // タップ位置から領域を判定（簡易版）
                  final width = context.size?.width ?? 1;
                  final tapX = details.localPosition.dx;
                  final region = (tapX / width * 3).toInt(); // 3分割
                  // ここで領域選択を処理
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),

            // 選択インジケータ
            if (selectedRegionIndex != null)
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '選択済: 領域 ${selectedRegionIndex! + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 回答ボタングリッド
class _AnswerGridSelector extends StatelessWidget {
  final UserGeneratedChallenge challenge;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  const _AnswerGridSelector({
    required this.challenge,
    this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // チャレンジの編集ポイント数から仮想的に領域数を決定
    // 実装：editedPoint JSON から領域情報を抽出
    final regionCount = 3; // ダミー：3つの選択肢

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'どこが編集されたでしょう？',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: regionCount,
            itemBuilder: (context, index) {
              final isSelected = selectedIndex == index;
              return _AnswerButton(
                label: 'パターン${index + 1}',
                isSelected: isSelected,
                onPressed: () => onSelected(index),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 個別の回答ボタン
class _AnswerButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _AnswerButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[100] : Colors.grey[200],
          border: Border.all(
            color: isSelected ? Colors.blue[400]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  size: 32,
                  color: isSelected ? Colors.blue[700] : Colors.grey[600],
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color:
                        isSelected ? Colors.blue[700] : Colors.grey[600],
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
