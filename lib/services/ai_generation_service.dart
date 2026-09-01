import 'package:machigai/models/index.dart';

/// AI生成・診断サービス
/// 動画編集から問題品質を分析し、難易度とスコアを自動計算
class AIGenerationService {
  /// ビデオテンプレートから問題として成立するかをAI診断
  /// 返り値: 診断スコア (0.0-100.0)
  /// スコアが高いほど「良い問題」と判定される
  static Future<double> diagnoseChallenge(
    UserGeneratedChallenge challenge,
  ) async {
    // petit_aiモデルによる診断（ここでは高度な発見的手法を使用）
    final score = _calculateDiagnosisScore(challenge);
    return score;
  }

  /// 診断スコアを計算（発見的手法ベース）
  ///
  /// 評価基準:
  /// - 編集の複雑度（複数パラメータの組み合わせ）
  /// - 編集ポイントの検出難易度
  /// - 問題としての区別可能性
  static double _calculateDiagnosisScore(UserGeneratedChallenge challenge) {
    double score = 50.0; // ベーススコア

    // 1. 編集ポイント数による評価（最重要）
    final editPointCount = challenge.editedPoint.length;
    if (editPointCount == 0) {
      return 0.0; // 編集なし = 無効な問題
    }

    // 編集ポイント数：1個で+15、2個で+25、3個以上で+35
    if (editPointCount == 1) {
      score += 15.0;
    } else if (editPointCount == 2) {
      score += 25.0;
    } else {
      score += 35.0;
    }

    // 2. 編集パラメータの多様性評価
    int parameterVariety = _evaluateParameterVariety(challenge.editedPoint);
    score += parameterVariety * 8.0; // 1パラメータ = +8ポイント

    // 3. 難易度別の基本スコア調整
    // 難易度が適切に設定されているほどスコア加算
    switch (challenge.difficulty) {
      case 'easy':
        // イージーは簡単過ぎないかチェック
        if (editPointCount <= 2 && parameterVariety <= 2) {
          score += 10.0;
        } else {
          score -= 5.0; // 編集が多すぎるとイージーにしては複雑
        }
        break;
      case 'medium':
        // ミディアムは標準的な難易度
        score += 15.0; // ボーナス: バランスが取れている
        break;
      case 'hard':
        // ハードは複雑な編集が必要
        if (editPointCount >= 2 && parameterVariety >= 2) {
          score += 15.0;
        } else {
          score -= 10.0; // 編集が少ないわりにハード設定
        }
        break;
      default:
        break;
    }

    // 4. 編集パラメータの極端さチェック
    // 極端な値（明るさ0.0や1.0など）は可視性が低い可能性
    if (_hasExtremeValues(challenge.editedPoint)) {
      score -= 10.0;
    }

    // 5. カラーパラメータの適切性
    if (_hasColorEdit(challenge.editedPoint)) {
      score += 8.0; // 色編集は視認性が高い
    }

    // 6. 位置編集の適切性（中央からのオフセット）
    if (_hasPositionEdit(challenge.editedPoint)) {
      score += 5.0;
    }

    return score.clamp(0.0, 100.0);
  }

  /// 編集パラメータの多様性を評価
  /// 異なる種類のパラメータが含まれているか確認
  static int _evaluateParameterVariety(Map<String, dynamic> editedPoint) {
    int variety = 0;

    if (editedPoint.containsKey('brightness')) variety++;
    if (editedPoint.containsKey('colorHue')) variety++;
    if (editedPoint.containsKey('positionX') ||
        editedPoint.containsKey('positionY')) variety++;
    if (editedPoint.containsKey('cropX') || editedPoint.containsKey('cropWidth')) {
      variety++;
    }

    return variety;
  }

  /// 極端な値（完全な0または完全な1）を検出
  static bool _hasExtremeValues(Map<String, dynamic> editedPoint) {
    for (final value in editedPoint.values) {
      if (value is double) {
        if (value == 0.0 || value == 1.0) {
          return true;
        }
      }
    }
    return false;
  }

  /// カラーパラメータが含まれているか
  static bool _hasColorEdit(Map<String, dynamic> editedPoint) {
    return editedPoint.containsKey('colorHue') &&
        editedPoint['colorHue'] != 0;
  }

  /// 位置編集が含まれているか
  static bool _hasPositionEdit(Map<String, dynamic> editedPoint) {
    final hasX = editedPoint.containsKey('positionX') &&
        (editedPoint['positionX'] as num) != 0;
    final hasY = editedPoint.containsKey('positionY') &&
        (editedPoint['positionY'] as num) != 0;
    return hasX || hasY;
  }

  /// チャレンジの難易度を自動計算
  /// 編集の複雑さから最適な難易度を提案
  static String calculateDifficulty(Map<String, dynamic> editedPoint) {
    if (editedPoint.isEmpty) {
      return 'easy'; // デフォルト
    }

    // パラメータの多様性を計算
    int variety = 0;
    if (editedPoint.containsKey('brightness')) variety++;
    if (editedPoint.containsKey('colorHue')) variety++;
    if (editedPoint.containsKey('positionX') ||
        editedPoint.containsKey('positionY')) variety++;
    if (editedPoint.containsKey('cropX') || editedPoint.containsKey('cropWidth')) {
      variety++;
    }

    // 編集ポイント数
    final editCount = editedPoint.length;

    // パラメータ値の変更幅を計算（0-1の標準化範囲内）
    double maxDelta = 0.0;
    for (final value in editedPoint.values) {
      if (value is double) {
        final delta = (value - 0.5).abs(); // 中央からの距離
        maxDelta = maxDelta > delta ? maxDelta : delta;
      }
    }

    // 難易度の判定ロジック
    if (variety >= 3 || (editCount >= 2 && maxDelta > 0.3)) {
      return 'hard'; // 複雑な編集 → ハード
    } else if (variety >= 2 || (editCount >= 2 && maxDelta > 0.15)) {
      return 'medium'; // 中程度の複雑さ → ミディアム
    } else {
      return 'easy'; // シンプルな編集 → イージー
    }
  }

  /// チャレンジの総合スコアを計算（0-100）
  /// これはFirestoreに保存されるaiScore
  static double calculateTotalScore(UserGeneratedChallenge challenge) {
    return _calculateDiagnosisScore(challenge);
  }

  /// ビデオテンプレート候補を取得
  /// 実装時: Firebase Storageからテンプレート一覧を取得
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

  /// スコア範囲別の品質判定
  /// UI表示用のラベルを返す
  static String getQualityLabel(double score) {
    if (score >= 80) {
      return '優秀'; // Excellent
    } else if (score >= 60) {
      return '良好'; // Good
    } else if (score >= 40) {
      return '普通'; // Fair
    } else if (score >= 20) {
      return '要改善'; // Needs improvement
    } else {
      return '不適格'; // Unacceptable
    }
  }

  /// スコアに対応する色を返す
  static int getQualityColor(double score) {
    // Material 3 color values
    if (score >= 80) {
      return 0xFF4CAF50; // Green
    } else if (score >= 60) {
      return 0xFF8BC34A; // Light Green
    } else if (score >= 40) {
      return 0xFFFFC107; // Amber
    } else if (score >= 20) {
      return 0xFFFF9800; // Orange
    } else {
      return 0xFFF44336; // Red
    }
  }
}
