import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:machigai/viewmodels/index.dart';

/// 問題出題確認画面
/// Aha Moment 最短経路第4ステップ：編集した問題を確認・シェア
///
/// 画面フロー：
/// 1. 編集内容を確認
/// 2. シェアトークン生成＆表示
/// 3. SNSシェア or 友達に通知
/// 4. ランキング画面へ遷移
class ChallengePublishedScreen extends ConsumerStatefulWidget {
  final VideoTemplate template;
  final VideoEdit edit;

  const ChallengePublishedScreen({
    required this.template,
    required this.edit,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<ChallengePublishedScreen> createState() =>
      _ChallengePublishedScreenState();
}

class _ChallengePublishedScreenState
    extends ConsumerState<ChallengePublishedScreen> {
  late String shareToken;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    // シェアトークンを生成（簡易版：ランダムID）
    shareToken = _generateShareToken();
  }

  String _generateShareToken() {
    // 簡易実装：8文字のランダムID
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = List.generate(8, (index) {
      return chars[(index * 7) % chars.length];
    }).join();
    return random;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 戻るボタンはホーム画面に戻す
        context.go('/');
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('問題を出題'),
          centerTitle: true,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 成功アイコン
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          size: 48,
                          color: Colors.green[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '問題が作成されました！',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // 問題情報サマリー
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '作成された問題',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.template.description.isNotEmpty
                                          ? widget.template.description
                                          : 'テンプレート問題',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _DifficultyBadge(
                                          difficulty: widget.template.difficulty,
                                        ),
                                        const SizedBox(width: 8),
                                        _CategoryBadge(
                                          category: widget.template.category,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.videocam,
                                      size: 32,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'プレビュー',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
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
                  ),
                ),

                const SizedBox(height: 24),

                // 編集内容
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '加えた編集',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              _EditTypeIcon(type: widget.edit.type),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getEditTypeLabel(widget.edit.type),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getEditDescription(widget.edit),
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
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // シェアトークン
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'シェアコード',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          border: Border.all(color: Colors.blue[200]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              shareToken,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                                fontFamily: 'monospace',
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '友達にこのコードを教えて挑戦させよう！',
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

                const SizedBox(height: 24),

                // シェアボタン
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'シェア方法',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        children: [
                          _ShareButton(
                            icon: Icons.share,
                            label: 'コピー',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('シェアコードをコピーしました'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          _ShareButton(
                            icon: Icons.mail,
                            label: 'LINEで',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('LINEで友達に送信'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          _ShareButton(
                            icon: Icons.chat,
                            label: 'SNSで',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('SNSでシェア'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          _ShareButton(
                            icon: Icons.link,
                            label: 'リンク',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('リンクをコピーしました'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // アクションボタン
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: _isPublishing
                            ? null
                            : () {
                                setState(() => _isPublishing = true);
                                // サーバーに問題を保存（実装予定）
                                Future.delayed(
                                  const Duration(seconds: 1),
                                  () {
                                    if (mounted) {
                                      // ホーム画面に戻る
                                      context.go('/');
                                    }
                                  },
                                );
                              },
                        child: _isPublishing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('問題を出題する'),
                      ),
                      const SizedBox(height: 12),
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

  String _getEditTypeLabel(String type) {
    return type == 'brightness'
        ? '明るさ調整'
        : type == 'color'
            ? '色変更'
            : type == 'position'
                ? '配置変更'
                : 'クロップ';
  }

  String _getEditDescription(VideoEdit edit) {
    final params = edit.parameters;
    switch (edit.type) {
      case 'brightness':
        final change = params['brightnessChange'] as num?;
        return '明るさを ${change?.toStringAsFixed(1)}% ${(change ?? 0) > 0 ? '明るく' : '暗く'}しました';
      case 'color':
        final target = params['targetObject'] as String?;
        final color = params['colorHex'] as String?;
        return '$target を $color に変更しました';
      case 'position':
        final dx = params['deltaX'] as num?;
        final dy = params['deltaY'] as num?;
        return '位置を移動しました（X:${dx?.toStringAsFixed(1)}, Y:${dy?.toStringAsFixed(1)}）';
      case 'crop':
        return 'フレームをクロップしました';
      default:
        return '';
    }
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
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

/// カテゴリバッジ
class _CategoryBadge extends StatelessWidget {
  final String category;

  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    final label = _getCategoryLabel(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.blue,
        ),
      ),
    );
  }

  String _getCategoryLabel(String category) {
    return switch (category) {
      'office' => 'オフィス',
      'room' => '部屋',
      'outdoor' => '屋外',
      'special' => 'スペシャル',
      _ => '不明',
    };
  }
}

/// 編集タイプのアイコン
class _EditTypeIcon extends StatelessWidget {
  final String type;

  const _EditTypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final icon = _getEditIcon(type);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: Colors.blue[700],
      ),
    );
  }

  IconData _getEditIcon(String type) {
    return switch (type) {
      'brightness' => Icons.brightness_6,
      'color' => Icons.palette,
      'position' => Icons.pan_tool,
      'crop' => Icons.crop,
      _ => Icons.edit,
    };
  }
}

/// シェアボタン
class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(8),
              child: Icon(icon, size: 24),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
