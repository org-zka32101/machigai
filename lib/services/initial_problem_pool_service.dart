import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:machigai/models/index.dart';
import 'package:uuid/uuid.dart';

/// 初期問題プール投入サービス
/// リリース初速でのコールドスタート対策（Must7）
///
/// 運営が事前に50-100件の問題をpetit_aiで生成し、
/// このサービスで検証・Firestoreに投入する。
class InitialProblemPoolService {
  static const String collectionName = 'challenges';
  static const String systemUserPrefix = 'system_admin';

  final FirebaseFirestore _firestore;

  InitialProblemPoolService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 初期問題プール用の問題を生成・投入
  ///
  /// petit_aiで事前生成されたテンプレートから、
  /// 多様な難易度/カテゴリの問題を作成し、
  /// Firestoreに一括投入する。
  ///
  /// Returns: 投入された問題数
  Future<int> seedInitialProblemPool({
    required List<InitialProblemTemplate> templates,
    bool validateWithAIDiagnosis = true,
  }) async {
    int successCount = 0;
    int failureCount = 0;

    print('🌱 Seeding initial problem pool (${templates.length} templates)...');

    for (final template in templates) {
      try {
        // AI診断検証
        if (validateWithAIDiagnosis) {
          final diagnosisScore = await _diagnoseTemplate(template);
          if (diagnosisScore < ModerationConfig.minAIDiagnosisScore) {
            print(
              '❌ Template rejected (low score: $diagnosisScore): ${template.id}',
            );
            failureCount++;
            continue;
          }
          print(
            '✅ Template validated (score: $diagnosisScore): ${template.id}',
          );
        }

        // 問題を作成
        final challenge = _createChallengeFromTemplate(template);

        // Firestoreに投入
        await _firestore
            .collection(collectionName)
            .doc(challenge.id)
            .set(challenge.toFirestore());

        successCount++;
        print('✅ Inserted: ${challenge.id} (${challenge.difficulty})');
      } catch (e) {
        print('❌ Error seeding template ${template.id}: $e');
        failureCount++;
      }
    }

    print(
      '🏁 Seeding complete: $successCount succeeded, $failureCount failed',
    );
    return successCount;
  }

  /// テンプレートをチャレンジに変換
  UserGeneratedChallenge _createChallengeFromTemplate(
    InitialProblemTemplate template,
  ) {
    final id = const Uuid().v4();
    final shareToken = const Uuid().v4();

    return UserGeneratedChallenge(
      id: id,
      creatorId: '${SystemUserID.systemAdmin}', // 運営ユーザーID
      videoUrl: template.videoUrl,
      editedPoint: template.editedPoint,
      difficulty: template.difficulty,
      createdAt: DateTime.now(),
      shareToken: shareToken,
      moderationStatus: 'approved', // 事前検証済みなので即承認
      solveCount: 0,
      successRate: 0.0,
    );
  }

  /// AI診断スコアを取得（petit_ai連携）
  Future<double> _diagnoseTemplate(InitialProblemTemplate template) async {
    // TODO: petit_aiの軽量モデルを使用して診断
    // 現在は仮のロジック（実装時に置き換え）

    double score = 60.0; // ベーススコア

    // 難易度別調整
    switch (template.difficulty) {
      case 'easy':
        score += 15.0;
        break;
      case 'hard':
        score += -5.0;
        break;
      default:
        score += 5.0;
    }

    // 編集ポイント数による調整
    final pointCount = template.editedPoint.length;
    if (pointCount > 0) {
      score += (pointCount * 3.0).clamp(0, 15.0);
    }

    // ビデオ複雑度による調整（petit_ai分析結果を使用）
    if (template.complexityScore != null) {
      score += (template.complexityScore! / 2.0).clamp(-10, 10);
    }

    return score.clamp(0.0, 100.0);
  }

  /// 既存の初期問題プールをチェック
  Future<int> countApprovedInitialProblems() async {
    try {
      final query = _firestore
          .collection(collectionName)
          .where('creatorId', isEqualTo: SystemUserID.systemAdmin)
          .where('moderationStatus', isEqualTo: 'approved');

      final docs = await query.get();
      return docs.size;
    } catch (e) {
      print('Error counting initial problems: $e');
      return 0;
    }
  }

  /// 初期問題プール全体を削除（テスト用）
  Future<void> clearInitialProblemPool() async {
    try {
      final query = _firestore
          .collection(collectionName)
          .where('creatorId', isEqualTo: SystemUserID.systemAdmin);

      final docs = await query.get();
      for (final doc in docs.docs) {
        await doc.reference.delete();
      }
      print('✅ Cleared ${docs.size} initial problems');
    } catch (e) {
      print('Error clearing initial pool: $e');
      rethrow;
    }
  }
}

/// システムユーザーID
class SystemUserID {
  static const String systemAdmin = 'system_admin';
  static const String aiGenerated = 'system_ai_generated';
}

/// 初期問題テンプレート（petit_aiで生成）
class InitialProblemTemplate {
  final String id; // petit_aiで生成されたテンプレートID
  final String videoUrl; // Firebase StorageのURL
  final Map<String, dynamic> editedPoint; // 編集座標
  final String difficulty; // 'easy', 'medium', 'hard'
  final String? category; // カテゴリ（オプション）
  final double? complexityScore; // petit_aiが計算した複雑度スコア
  final String? description; // テンプレートの説明

  InitialProblemTemplate({
    required this.id,
    required this.videoUrl,
    required this.editedPoint,
    required this.difficulty,
    this.category,
    this.complexityScore,
    this.description,
  });

  /// JSON から復元
  factory InitialProblemTemplate.fromJson(Map<String, dynamic> json) {
    return InitialProblemTemplate(
      id: json['id'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      editedPoint: json['editedPoint'] ?? {},
      difficulty: json['difficulty'] ?? 'medium',
      category: json['category'],
      complexityScore: (json['complexityScore'] as num?)?.toDouble(),
      description: json['description'],
    );
  }

  /// JSON に変換
  Map<String, dynamic> toJson() => {
        'id': id,
        'videoUrl': videoUrl,
        'editedPoint': editedPoint,
        'difficulty': difficulty,
        'category': category,
        'complexityScore': complexityScore,
        'description': description,
      };
}
