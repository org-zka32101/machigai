import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:machigai/viewmodels/index.dart';

/// ビデオ編集画面
/// Aha Moment 最短経路第3ステップ：テンプレート動画を1箇所編集
///
/// 機能：
/// - 明るさ調整（スライダー）
/// - 色変更（カラーピッカー）
/// - 配置変更（ドラッグ）
/// - クロップ（選択ボックス）
class EditScreen extends ConsumerWidget {
  final String templateId;

  const EditScreen({
    required this.templateId,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editState = ref.watch(videoEditProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('動画を編集'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: editState.selectedTemplate == null
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ビデオプレビューエリア
                    _VideoPreviewArea(
                      template: editState.selectedTemplate!,
                      currentEdit: editState.currentEdit,
                    ),

                    const SizedBox(height: 24),

                    // 編集ツールセレクタ
                    _EditToolSelector(
                      onBrightness: () => _showBrightnessEditor(context, ref),
                      onColor: () => _showColorEditor(context, ref),
                      onPosition: () => _showPositionEditor(context, ref),
                      onCrop: () => _showCropEditor(context, ref),
                    ),

                    const SizedBox(height: 24),

                    // 現在の編集内容表示
                    if (editState.currentEdit != null)
                      _EditSummary(edit: editState.currentEdit!),

                    const SizedBox(height: 24),

                    // アクションボタン
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                ref.read(videoEditProvider.notifier).clearEdit();
                              },
                              child: const Text('クリア'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: editState.currentEdit == null
                                  ? null
                                  : () {
                                      // 出題画面へ遷移
                                      context.push(
                                        '/challenge-published',
                                        extra: {
                                          'template': editState.selectedTemplate,
                                          'edit': editState.currentEdit,
                                        },
                                      );
                                    },
                              child: const Text('編集完了'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  void _showBrightnessEditor(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _BrightnessEditor(
        onApply: (brightness) {
          ref.read(videoEditProvider.notifier).editBrightness(
                brightnessChange: brightness,
              );
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showColorEditor(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _ColorEditor(
        onApply: (targetObject, colorHex) {
          ref.read(videoEditProvider.notifier).editColor(
                targetObject: targetObject,
                colorHex: colorHex,
              );
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showPositionEditor(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _PositionEditor(
        onApply: (deltaX, deltaY) {
          ref.read(videoEditProvider.notifier).editPosition(
                deltaX: deltaX,
                deltaY: deltaY,
              );
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showCropEditor(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _CropEditor(
        onApply: (x, y, width, height) {
          ref.read(videoEditProvider.notifier).editCrop(
                x: x,
                y: y,
                width: width,
                height: height,
              );
          Navigator.pop(context);
        },
      ),
    );
  }
}

/// ビデオプレビューエリア
class _VideoPreviewArea extends StatelessWidget {
  final VideoTemplate template;
  final VideoEdit? currentEdit;

  const _VideoPreviewArea({
    required this.template,
    this.currentEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
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

            // 編集エリア表示
            if (template.editableRegions.isNotEmpty)
              ..._buildEditableRegions(template),

            // 現在の編集が何かを示すバッジ
            if (currentEdit != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _editTypeLabel(currentEdit!),
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

  List<Widget> _buildEditableRegions(VideoTemplate template) {
    return template.editableRegions.map((region) {
      return Positioned(
        left: region.x.toDouble(),
        top: region.y.toDouble(),
        width: region.width.toDouble(),
        height: region.height.toDouble(),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.blue.withOpacity(0.5),
              width: 2,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              region.label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  String _editTypeLabel(VideoEdit edit) {
    return edit.type == 'brightness'
        ? '明るさ'
        : edit.type == 'color'
            ? '色'
            : edit.type == 'position'
                ? '配置'
                : 'クロップ';
  }
}

/// 編集内容の概要表示
class _EditSummary extends StatelessWidget {
  final VideoEdit edit;

  const _EditSummary({required this.edit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    '現在の編集',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getEditLabel(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _getEditDescription(),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getEditLabel() {
    return edit.type == 'brightness'
        ? '明るさ調整'
        : edit.type == 'color'
            ? '色変更'
            : edit.type == 'position'
                ? '配置変更'
                : 'クロップ';
  }

  String _getEditDescription() {
    final params = edit.parameters;
    switch (edit.type) {
      case 'brightness':
        final change = params['brightnessChange'] as num?;
        return '明るさを ${change?.toStringAsFixed(1)}% ${(change ?? 0) > 0 ? '明るく' : '暗く'}';
      case 'color':
        final target = params['targetObject'] as String?;
        final color = params['colorHex'] as String?;
        return '$target を $color に変更';
      case 'position':
        final dx = params['deltaX'] as num?;
        final dy = params['deltaY'] as num?;
        return 'X方向: ${dx?.toStringAsFixed(1)}, Y方向: ${dy?.toStringAsFixed(1)}';
      case 'crop':
        final x = params['x'] as int?;
        final y = params['y'] as int?;
        final w = params['width'] as int?;
        final h = params['height'] as int?;
        return 'クロップ範囲: ($x, $y) 幅$w × 高$h';
      default:
        return '';
    }
  }
}

/// 編集ツールセレクタ
class _EditToolSelector extends StatelessWidget {
  final VoidCallback onBrightness;
  final VoidCallback onColor;
  final VoidCallback onPosition;
  final VoidCallback onCrop;

  const _EditToolSelector({
    required this.onBrightness,
    required this.onColor,
    required this.onPosition,
    required this.onCrop,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '編集方法を選ぶ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _EditToolButton(
                  icon: Icons.brightness_6,
                  label: '明るさ',
                  onPressed: onBrightness,
                ),
                const SizedBox(width: 8),
                _EditToolButton(
                  icon: Icons.palette,
                  label: '色',
                  onPressed: onColor,
                ),
                const SizedBox(width: 8),
                _EditToolButton(
                  icon: Icons.pan_tool,
                  label: '配置',
                  onPressed: onPosition,
                ),
                const SizedBox(width: 8),
                _EditToolButton(
                  icon: Icons.crop,
                  label: 'クロップ',
                  onPressed: onCrop,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 編集ツールボタン
class _EditToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _EditToolButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}

/// 明るさ調整エディタ（モーダルボトムシート）
class _BrightnessEditor extends StatefulWidget {
  final ValueChanged<double> onApply;

  const _BrightnessEditor({required this.onApply});

  @override
  State<_BrightnessEditor> createState() => _BrightnessEditorState();
}

class _BrightnessEditorState extends State<_BrightnessEditor> {
  double brightness = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '明るさを調整',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.brightness_4),
                Expanded(
                  child: Slider(
                    value: brightness,
                    min: -100,
                    max: 100,
                    divisions: 200,
                    label: brightness.toStringAsFixed(0),
                    onChanged: (value) {
                      setState(() => brightness = value);
                    },
                  ),
                ),
                const Icon(Icons.brightness_7),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${brightness > 0 ? '+' : ''}${brightness.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => widget.onApply(brightness),
              child: const Text('適用'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 色変更エディタ
class _ColorEditor extends StatefulWidget {
  final Function(String targetObject, String colorHex) onApply;

  const _ColorEditor({required this.onApply});

  @override
  State<_ColorEditor> createState() => _ColorEditorState();
}

class _ColorEditorState extends State<_ColorEditor> {
  String targetObject = '';
  String selectedColor = '#FF0000';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '色を変更',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              decoration: InputDecoration(
                labelText: '対象オブジェクト（例：椅子の色)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() => targetObject = value);
              },
            ),
            const SizedBox(height: 16),
            const Text('選択色:'),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ColorOption(
                    color: const Color(0xFFFF0000),
                    hex: 'FF0000',
                    selected: selectedColor == 'FF0000',
                    onTap: () => setState(() => selectedColor = 'FF0000'),
                  ),
                  const SizedBox(width: 8),
                  _ColorOption(
                    color: const Color(0xFF00FF00),
                    hex: '00FF00',
                    selected: selectedColor == '00FF00',
                    onTap: () => setState(() => selectedColor = '00FF00'),
                  ),
                  const SizedBox(width: 8),
                  _ColorOption(
                    color: const Color(0xFF0000FF),
                    hex: '0000FF',
                    selected: selectedColor == '0000FF',
                    onTap: () => setState(() => selectedColor = '0000FF'),
                  ),
                  const SizedBox(width: 8),
                  _ColorOption(
                    color: const Color(0xFFFFFF00),
                    hex: 'FFFF00',
                    selected: selectedColor == 'FFFF00',
                    onTap: () => setState(() => selectedColor = 'FFFF00'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: targetObject.isEmpty
                  ? null
                  : () => widget.onApply(targetObject, selectedColor),
              child: const Text('適用'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 色選択オプション
class _ColorOption extends StatelessWidget {
  final Color color;
  final String hex;
  final bool selected;
  final VoidCallback onTap;

  const _ColorOption({
    required this.color,
    required this.hex,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: selected ? Colors.black : Colors.transparent,
            width: selected ? 3 : 0,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: selected
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 24,
              )
            : null,
      ),
    );
  }
}

/// 配置変更エディタ
class _PositionEditor extends StatefulWidget {
  final Function(double deltaX, double deltaY) onApply;

  const _PositionEditor({required this.onApply});

  @override
  State<_PositionEditor> createState() => _PositionEditorState();
}

class _PositionEditorState extends State<_PositionEditor> {
  double deltaX = 0;
  double deltaY = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '配置を変更',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            const Text('X方向:'),
            Slider(
              value: deltaX,
              min: -100,
              max: 100,
              divisions: 200,
              label: deltaX.toStringAsFixed(0),
              onChanged: (value) {
                setState(() => deltaX = value);
              },
            ),
            const SizedBox(height: 16),
            const Text('Y方向:'),
            Slider(
              value: deltaY,
              min: -100,
              max: 100,
              divisions: 200,
              label: deltaY.toStringAsFixed(0),
              onChanged: (value) {
                setState(() => deltaY = value);
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => widget.onApply(deltaX, deltaY),
              child: const Text('適用'),
            ),
          ],
        ),
      ),
    );
  }
}

/// クロップエディタ
class _CropEditor extends StatefulWidget {
  final Function(int x, int y, int width, int height) onApply;

  const _CropEditor({required this.onApply});

  @override
  State<_CropEditor> createState() => _CropEditorState();
}

class _CropEditorState extends State<_CropEditor> {
  int cropX = 0;
  int cropY = 0;
  int cropWidth = 100;
  int cropHeight = 100;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'クロップ範囲を設定',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              _CropField(
                label: 'X位置',
                value: cropX,
                onChanged: (value) {
                  setState(() => cropX = value);
                },
              ),
              const SizedBox(height: 12),
              _CropField(
                label: 'Y位置',
                value: cropY,
                onChanged: (value) {
                  setState(() => cropY = value);
                },
              ),
              const SizedBox(height: 12),
              _CropField(
                label: '幅',
                value: cropWidth,
                onChanged: (value) {
                  setState(() => cropWidth = value);
                },
              ),
              const SizedBox(height: 12),
              _CropField(
                label: '高さ',
                value: cropHeight,
                onChanged: (value) {
                  setState(() => cropHeight = value);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () =>
                    widget.onApply(cropX, cropY, cropWidth, cropHeight),
                child: const Text('適用'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// クロップ数値入力フィールド
class _CropField extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _CropField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label),
        ),
        Expanded(
          flex: 3,
          child: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            controller: TextEditingController(text: value.toString()),
            onChanged: (text) {
              final parsed = int.tryParse(text);
              if (parsed != null) {
                onChanged(parsed);
              }
            },
          ),
        ),
      ],
    );
  }
}
