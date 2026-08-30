import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:machigai/models/index.dart';

/// ビデオテンプレートサービス
/// 動画編集機能の技術検証（㉙7日プロト）
///
/// ユーザーがテンプレート動画から1箇所編集して
/// 問題を作成できるようにするサービス。
class VideoTemplateService {
  static const String templatesBucket = 'gs://machigai-xxxx.appspot.com/templates';
  static const String userEditsBucket = 'gs://machigai-xxxx.appspot.com/user-edits';

  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;

  VideoTemplateService({
    FirebaseStorage? storage,
    FirebaseFirestore? firestore,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// 利用可能なビデオテンプレートを取得
  Future<List<VideoTemplate>> getAvailableTemplates({
    String? difficulty,
    String? category,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection('video_templates')
          .where('available', isEqualTo: true)
          .orderBy('createdAt', descending: true);

      if (difficulty != null) {
        query = query.where('suggestedDifficulty', isEqualTo: difficulty);
      }

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      query = query.limit(limit);

      final docs = await query.get();
      return docs.docs
          .map((doc) => VideoTemplate.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching templates: $e');
      return [];
    }
  }

  /// 特定のテンプレートを取得
  Future<VideoTemplate?> getTemplate(String templateId) async {
    try {
      final doc = await _firestore
          .collection('video_templates')
          .doc(templateId)
          .get();

      if (!doc.exists) return null;
      return VideoTemplate.fromFirestore(doc);
    } catch (e) {
      print('Error fetching template: $e');
      return null;
    }
  }

  /// ビデオ編集ファイルをアップロード
  ///
  /// Returns: Firebase StorageのURL
  Future<String> uploadEditedVideo({
    required String userId,
    required String templateId,
    required List<int> videoBytes,
    required VideoEdit edit,
  }) async {
    try {
      final fileName =
          '${userId}_${templateId}_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final ref = _storage.ref('user-edits/$fileName');

      final uploadTask = await ref.putData(
        videoBytes,
        SettableMetadata(
          contentType: 'video/mp4',
          customMetadata: {
            'userId': userId,
            'templateId': templateId,
            'editType': edit.type,
          },
        ),
      );

      final url = await ref.getDownloadURL();
      print('✅ Video uploaded: $url');
      return url;
    } catch (e) {
      print('Error uploading video: $e');
      rethrow;
    }
  }

  /// テンプレートをダウンロード（端末での編集用）
  Future<List<int>?> downloadTemplate(String templateId) async {
    try {
      final template = await getTemplate(templateId);
      if (template == null) return null;

      final bytes = await _storage
          .refFromURL(template.videoUrl)
          .getData(100 * 1024 * 1024); // Max 100MB

      return bytes;
    } catch (e) {
      print('Error downloading template: $e');
      return null;
    }
  }
}

/// ビデオテンプレートモデル
class VideoTemplate {
  final String id;
  final String videoUrl; // Firebase Storage URL
  final String category; // 'office', 'room', 'outdoor', 'special'
  final String suggestedDifficulty; // 'easy', 'medium', 'hard'
  final String description;
  final bool available; // 公開中か
  final DateTime createdAt;
  final List<EditableRegion> editableRegions;

  VideoTemplate({
    required this.id,
    required this.videoUrl,
    required this.category,
    required this.suggestedDifficulty,
    required this.description,
    this.available = true,
    required this.createdAt,
    this.editableRegions = const [],
  });

  /// Firestoreから復元
  factory VideoTemplate.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return VideoTemplate(
      id: doc.id,
      videoUrl: data['videoUrl'] ?? '',
      category: data['category'] ?? 'office',
      suggestedDifficulty: data['suggestedDifficulty'] ?? 'medium',
      description: data['description'] ?? '',
      available: data['available'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      editableRegions: (data['editableRegions'] as List?)
              ?.map((r) => EditableRegion.fromJson(r))
              .toList() ??
          [],
    );
  }

  /// Firestoreへの変換
  Map<String, dynamic> toFirestore() => {
        'videoUrl': videoUrl,
        'category': category,
        'suggestedDifficulty': suggestedDifficulty,
        'description': description,
        'available': available,
        'createdAt': Timestamp.fromDate(createdAt),
        'editableRegions':
            editableRegions.map((r) => r.toJson()).toList(),
      };
}

/// 編集可能リージョン
class EditableRegion {
  final int x;
  final int y;
  final int width;
  final int height;
  final List<String> editTypes; // 'brightness', 'color', 'position', 'crop'

  EditableRegion({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.editTypes = const ['brightness', 'color', 'position'],
  });

  /// JSONから復元
  factory EditableRegion.fromJson(Map<String, dynamic> json) {
    return EditableRegion(
      x: json['x'] ?? 0,
      y: json['y'] ?? 0,
      width: json['width'] ?? 100,
      height: json['height'] ?? 100,
      editTypes: List<String>.from(json['editTypes'] ?? []),
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'editTypes': editTypes,
      };
}

/// ビデオ編集情報
class VideoEdit {
  final String type; // 'brightness', 'color', 'position', 'crop'
  final Map<String, dynamic> parameters;

  VideoEdit({
    required this.type,
    required this.parameters,
  });

  /// 明るさ編集
  factory VideoEdit.brightness({
    required double brightnessChange, // -100 to +100
    int? x,
    int? y,
    int? width,
    int? height,
  }) {
    return VideoEdit(
      type: 'brightness',
      parameters: {
        'brightnessChange': brightnessChange.clamp(-100, 100),
        if (x != null) 'x': x,
        if (y != null) 'y': y,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
      },
    );
  }

  /// 色編集
  factory VideoEdit.color({
    required String targetObject,
    required String colorHex,
    int? x,
    int? y,
    int? width,
    int? height,
  }) {
    return VideoEdit(
      type: 'color',
      parameters: {
        'targetObject': targetObject,
        'colorHex': colorHex,
        if (x != null) 'x': x,
        if (y != null) 'y': y,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
      },
    );
  }

  /// 配置編集
  factory VideoEdit.position({
    required double deltaX,
    required double deltaY,
    int? width,
    int? height,
  }) {
    return VideoEdit(
      type: 'position',
      parameters: {
        'deltaX': deltaX,
        'deltaY': deltaY,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
      },
    );
  }

  /// クロップ編集
  factory VideoEdit.crop({
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    return VideoEdit(
      type: 'crop',
      parameters: {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      },
    );
  }
}
