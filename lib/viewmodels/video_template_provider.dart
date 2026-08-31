import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:machigai/services/index.dart';

/// ビデオテンプレート関連のProviders

/// VideoTemplateServiceのProvider
final videoTemplateServiceProvider = Provider((ref) {
  return VideoTemplateService();
});

/// 利用可能なビデオテンプレート一覧
final availableTemplatesProvider = FutureProvider.family<
    List<VideoTemplate>,
    ({String? difficulty, String? category})>(
  (ref, params) async {
    final service = ref.watch(videoTemplateServiceProvider);
    return service.getAvailableTemplates(
      difficulty: params.difficulty,
      category: params.category,
    );
  },
);

/// 特定のテンプレートを取得
final templateDetailProvider =
    FutureProvider.family<VideoTemplate?, String>(
  (ref, templateId) async {
    final service = ref.watch(videoTemplateServiceProvider);
    return service.getTemplate(templateId);
  },
);

/// ビデオ編集状態管理
class VideoEditState {
  final VideoTemplate? selectedTemplate;
  final VideoEdit? currentEdit;
  final bool isProcessing;
  final String? error;

  VideoEditState({
    this.selectedTemplate,
    this.currentEdit,
    this.isProcessing = false,
    this.error,
  });

  VideoEditState copyWith({
    VideoTemplate? selectedTemplate,
    VideoEdit? currentEdit,
    bool? isProcessing,
    String? error,
  }) {
    return VideoEditState(
      selectedTemplate: selectedTemplate ?? this.selectedTemplate,
      currentEdit: currentEdit ?? this.currentEdit,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error ?? this.error,
    );
  }
}

/// ビデオ編集ViewModel
final videoEditProvider =
    StateNotifierProvider<VideoEditNotifier, VideoEditState>(
  (ref) => VideoEditNotifier(ref),
);

class VideoEditNotifier extends StateNotifier<VideoEditState> {
  final Ref _ref;

  VideoEditNotifier(this._ref) : super(VideoEditState());

  /// テンプレートを選択
  Future<void> selectTemplate(String templateId) async {
    state = state.copyWith(isProcessing: true, error: null);

    try {
      final service = _ref.read(videoTemplateServiceProvider);
      final template = await service.getTemplate(templateId);

      state = state.copyWith(
        selectedTemplate: template,
        isProcessing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// 編集を設定
  void setEdit(VideoEdit edit) {
    state = state.copyWith(currentEdit: edit);
  }

  /// 明るさ編集を作成
  void editBrightness({
    required double brightnessChange,
    int? x,
    int? y,
    int? width,
    int? height,
  }) {
    final edit = VideoEdit.brightness(
      brightnessChange: brightnessChange,
      x: x,
      y: y,
      width: width,
      height: height,
    );
    setEdit(edit);
  }

  /// 色編集を作成
  void editColor({
    required String targetObject,
    required String colorHex,
    int? x,
    int? y,
    int? width,
    int? height,
  }) {
    final edit = VideoEdit.color(
      targetObject: targetObject,
      colorHex: colorHex,
      x: x,
      y: y,
      width: width,
      height: height,
    );
    setEdit(edit);
  }

  /// 配置編集を作成
  void editPosition({
    required double deltaX,
    required double deltaY,
    int? width,
    int? height,
  }) {
    final edit = VideoEdit.position(
      deltaX: deltaX,
      deltaY: deltaY,
      width: width,
      height: height,
    );
    setEdit(edit);
  }

  /// クロップ編集を作成
  void editCrop({
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    final edit = VideoEdit.crop(
      x: x,
      y: y,
      width: width,
      height: height,
    );
    setEdit(edit);
  }

  /// 編集をクリア
  void clearEdit() {
    state = state.copyWith(currentEdit: null);
  }
}
