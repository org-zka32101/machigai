import 'package:machigai/models/index.dart';

/// UGCモデレーションサービス
/// NGワード検知と簡易審査フローを実装
class ModerationService {
  /// テキストにNGワードが含まれているかチェック
  static ModerationResult checkForNGWords(String text) {
    final lowercaseText = text.toLowerCase();

    for (final category in ModerationConfig.ngWords.entries) {
      for (final word in category.value) {
        if (lowercaseText.contains(word.toLowerCase())) {
          return ModerationResult(
            isApproved: false,
            reason: 'NGワード検出: ${category.key}',
            detectedWords: [word],
          );
        }
      }
    }

    return ModerationResult(isApproved: true);
  }

  /// ビデオコンテンツの簡易モデレーション
  /// 画像認識系は実装時に別途検討
  static Future<ModerationResult> moderateChallenge(
    UserGeneratedChallenge challenge,
  ) async {
    // Step 1: テキストベースのNGワードチェック
    // (現在はビデオメタデータやタイトルがあればそこからチェック)

    // Step 2: ビデオ長などの基本検証
    // (実装時に拡張)

    // Step 3: AI検診スコアの確認
    // (AIGenerationServiceと連携)

    return ModerationResult(
      isApproved: challenge.moderationStatus == 'approved',
    );
  }
}

/// モデレーション結果
class ModerationResult {
  final bool isApproved;
  final String? reason;
  final List<String> detectedWords;

  ModerationResult({
    required this.isApproved,
    this.reason,
    this.detectedWords = const [],
  });
}
