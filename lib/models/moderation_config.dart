/// UGCモデレーション設定・ルール
class ModerationConfig {
  /// NGワード一覧（カテゴリ別）
  static const Map<String, List<String>> ngWords = {
    'violence': [
      '殺す', '殺害', '暴力', '暴行', '襲撃',
    ],
    'sexual': [
      'sex', 'porn',
    ],
    'discrimination': [
      '差別', '偏見',
    ],
    'harassment': [
      'いじめ', 'harassment',
    ],
  };

  /// 難易度別の難しさスコアの範囲
  static const Map<String, (double, double)> difficultyScoreRange = {
    'easy': (20.0, 40.0),
    'medium': (40.0, 70.0),
    'hard': (70.0, 100.0),
  };

  /// Aha Moment到達の条件
  static const int ahaMomentCorrectAnswers = 3; // 連続3問正解
  static const Duration ahaMomentTimeWindow = Duration(minutes: 3); // 出題後3分以内

  /// AIが検診で判定する最小スコア
  static const double minAIDiagnosisScore = 25.0;
}
