import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:machigai/models/index.dart';
import 'package:machigai/services/index.dart';

/// AI生成サービスプロバイダー
final aiGenerationServiceProvider = Provider((_) => AIGenerationService());

/// チャレンジ品質スコアプロバイダー
/// 与えられたチャレンジの品質スコア（0-100）を計算
final challengeQualityScoreProvider =
    FutureProvider.family<double, UserGeneratedChallenge>((ref, challenge) async {
  final aiService = ref.watch(aiGenerationServiceProvider);
  return aiService.diagnoseChallenge(challenge);
});

/// 編集パラメータから自動難易度計算プロバイダー
/// ユーザーが編集を行う際にリアルタイムで難易度を提案
final autoDifficultyProvider =
    FutureProvider.family<String, Map<String, dynamic>>(
  (ref, editedPoint) async {
    return AIGenerationService.calculateDifficulty(editedPoint);
  },
);

/// 品質スコアから品質ラベルを取得
/// "優秀", "良好", "普通", "要改善", "不適格"
final qualityLabelProvider = FutureProvider.family<String, double>(
  (ref, score) async {
    return AIGenerationService.getQualityLabel(score);
  },
);

/// 品質スコアから品質インジケータ色を取得
final qualityColorProvider = FutureProvider.family<int, double>(
  (ref, score) async {
    return AIGenerationService.getQualityColor(score);
  },
);
