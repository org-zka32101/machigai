import 'package:machigai/models/index.dart';

/// AI生成・診断サービス
/// petit_aiを経由して動画テンプレ生成と問題診断を実施
class AIGenerationService {
  /// ビデオテンプレートから問題として成立するかをAI診断
  /// 返り値: 診断スコア (0.0-100.0)
  /// スコアが高いほど「良い問題」と判定される
  static Future<double> diagnoseChallenge(
    UserGeneratedChallenge challenge,
  ) async {
    // TODO: petit_aiの軽量モデルを使用してAI診断を実施
    // - ビデオの複雑度分析
    // - 編集ポイントの検出難易度
    // - 問題としての成立度

    // 仮の実装: ランダムスコア（実装時は削除）
    final score = _calculateDiagnosisScore(challenge);
    return score;
  }

  /// 診断スコアを計算
  static double _calculateDiagnosisScore(UserGeneratedChallenge challenge) {
    double score = 50.0; // ベーススコア

    // 難易度別の基本スコア調整
    switch (challenge.difficulty) {
      case 'easy':
        score += 10.0;
        break;
      case 'hard':
        score += -5.0;
        break;
      default:
        break;
    }

    // 編集ポイント数による調整
    final editPointCount = challenge.editedPoint.length;
    if (editPointCount > 0) {
      score += (editPointCount * 5.0).clamp(0, 20.0);
    }

    return score.clamp(0.0, 100.0);
  }

  /// ビデオテンプレート候補を取得
  /// 実装時: petit_aiで事前生成されたテンプレートをFirebase Storageから取得
  static Future<List<String>> getVideoTemplates({
    String? category,
  }) async {
    // TODO: Firebase Storageからテンプレート一覧を取得
    return [];
  }

  /// 初期問題プール用の問題を自動生成
  /// Must7対応: リリース初速でコールドスタート対策
  static Future<List<UserGeneratedChallenge>> generateInitialProblemPool({
    required int count,
  }) async {
    // TODO: petit_aiで動画テンプレ+編集パターンを事前生成
    // - 50-100件の多様な問題を生成
    // - AI検診と同ロジックで検証
    // - moderationStatus=approvedで初期配信
    return [];
  }
}
