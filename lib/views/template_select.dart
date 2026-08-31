import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:machigai/viewmodels/index.dart';

/// テンプレート選択画面
/// Aha Moment 最短経路第2ステップ：テンプレートを選んで編集画面へ
class TemplateSelectScreen extends ConsumerStatefulWidget {
  const TemplateSelectScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TemplateSelectScreen> createState() =>
      _TemplateSelectScreenState();
}

class _TemplateSelectScreenState extends ConsumerState<TemplateSelectScreen> {
  String? selectedDifficulty;
  String? selectedCategory;

  @override
  Widget build(BuildContext context) {
    // テンプレート取得（フィルタ付き）
    final templatesAsync = ref.watch(
      availableTemplatesProvider(
        (difficulty: selectedDifficulty, category: selectedCategory),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('テンプレートを選ぶ'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // フィルタエリア
            _FilterBar(
              onDifficultyChanged: (difficulty) {
                setState(() => selectedDifficulty = difficulty);
              },
              onCategoryChanged: (category) {
                setState(() => selectedCategory = category);
              },
            ),

            // テンプレート一覧
            Expanded(
              child: templatesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (err, st) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('テンプレートを取得できません'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.refresh(
                            availableTemplatesProvider(
                              (
                                difficulty: selectedDifficulty,
                                category: selectedCategory
                              ),
                            ),
                          );
                        },
                        child: const Text('再試行'),
                      ),
                    ],
                  ),
                ),
                data: (templates) {
                  if (templates.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'テンプレートが見つかりません',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1 / 1.2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                    ),
                    itemCount: templates.length,
                    itemBuilder: (context, index) {
                      final template = templates[index];
                      return _TemplateCard(
                        template: template,
                        onTap: () {
                          // 選択したテンプレートを notifier に設定
                          ref
                              .read(videoEditProvider.notifier)
                              .selectTemplate(template.id);

                          // 編集画面へ遷移
                          context.push('/edit', extra: template.id);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// フィルタバー（難易度＋カテゴリ）
class _FilterBar extends StatefulWidget {
  final ValueChanged<String?> onDifficultyChanged;
  final ValueChanged<String?> onCategoryChanged;

  const _FilterBar({
    required this.onDifficultyChanged,
    required this.onCategoryChanged,
  });

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  String? selectedDifficulty;
  String? selectedCategory;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 難易度フィルタ
            _FilterChip(
              label: '難易度',
              values: const ['easy', 'medium', 'hard'],
              labels: const ['イージー', 'ノーマル', 'ハード'],
              selected: selectedDifficulty,
              onSelected: (value) {
                setState(() => selectedDifficulty = value);
                widget.onDifficultyChanged(value);
              },
            ),

            const SizedBox(width: 12),

            // カテゴリフィルタ
            _FilterChip(
              label: 'カテゴリ',
              values: const ['office', 'room', 'outdoor', 'special'],
              labels: const ['オフィス', '部屋', '屋外', 'スペシャル'],
              selected: selectedCategory,
              onSelected: (value) {
                setState(() => selectedCategory = value);
                widget.onCategoryChanged(value);
              },
            ),

            const SizedBox(width: 12),

            // リセットボタン
            if (selectedDifficulty != null || selectedCategory != null)
              OutlinedButton.icon(
                icon: const Icon(Icons.clear),
                label: const Text('リセット'),
                onPressed: () {
                  setState(() {
                    selectedDifficulty = null;
                    selectedCategory = null;
                  });
                  widget.onDifficultyChanged(null);
                  widget.onCategoryChanged(null);
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// フィルタ用ドロップダウンチップ
class _FilterChip extends StatefulWidget {
  final String label;
  final List<String> values;
  final List<String> labels;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _FilterChip({
    required this.label,
    required this.values,
    required this.labels,
    this.selected,
    required this.onSelected,
  });

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final selectedLabel = widget.selected != null
        ? widget.labels[widget.values.indexOf(widget.selected!)]
        : widget.label;

    return PopupMenuButton<String>(
      onSelected: (value) {
        widget.onSelected(value == widget.selected ? null : value);
      },
      itemBuilder: (context) => [
        ...widget.values.asMap().entries.map((e) {
          final value = e.value;
          final label = widget.labels[e.key];
          return PopupMenuItem<String>(
            value: value,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (value == widget.selected)
                  const Icon(Icons.check, size: 20),
                if (value == widget.selected) const SizedBox(width: 8),
                Text(label),
              ],
            ),
          );
        }),
      ],
      child: FilterChip(
        label: Text(selectedLabel),
        onSelected: (_) {},
        avatar: Icon(
          Icons.arrow_drop_down,
          size: 18,
          color: Theme.of(context).primaryColor,
        ),
        side: BorderSide(
          color: widget.selected != null
              ? Theme.of(context).primaryColor
              : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
    );
  }
}

/// テンプレート表示カード
class _TemplateCard extends StatelessWidget {
  final VideoTemplate template;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 難易度ラベル
    String difficultyLabel = '';
    Color difficultyColor = Colors.grey;

    switch (template.difficulty) {
      case 'easy':
        difficultyLabel = 'イージー';
        difficultyColor = Colors.green;
        break;
      case 'medium':
        difficultyLabel = 'ノーマル';
        difficultyColor = Colors.orange;
        break;
      case 'hard':
        difficultyLabel = 'ハード';
        difficultyColor = Colors.red;
        break;
    }

    // カテゴリラベル
    String categoryLabel = '';
    switch (template.category) {
      case 'office':
        categoryLabel = 'オフィス';
        break;
      case 'room':
        categoryLabel = '部屋';
        break;
      case 'outdoor':
        categoryLabel = '屋外';
        break;
      case 'special':
        categoryLabel = 'スペシャル';
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // サムネイル（プレースホルダー）
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.grey[300],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam,
                      size: 48,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ビデオプレビュー',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 情報エリア
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // タイトル
                    Text(
                      template.description.isNotEmpty
                          ? template.description
                          : 'テンプレート ${template.id.substring(0, 8)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // 難易度・カテゴリタグ
                    Row(
                      children: [
                        Expanded(
                          child: _TagChip(
                            label: difficultyLabel,
                            color: difficultyColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _TagChip(
                            label: categoryLabel,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// タグ用小型チップ
class _TagChip extends StatelessWidget {
  final String label;
  final Color color;

  const _TagChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
