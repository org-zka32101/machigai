/// 初期問題プール投入スクリプト
///
/// 使用方法:
///   dart run scripts/seed_initial_problems.dart
///
/// 環境変数:
///   FIRESTORE_PROJECT_ID: Firebase project ID
///   INPUT_FILE: 問題テンプレートのJSONファイルパス (default: data/initial_problems.json)
///   VALIDATE: AI診断を実施するか (default: true)

import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:machigai/config/firebase_options.dart';
import 'package:machigai/services/initial_problem_pool_service.dart';

Future<void> main(List<String> args) async {
  print('🚀 Machigai Initial Problem Pool Seeding Script');
  print('=' * 60);

  try {
    // Firebase初期化
    print('🔧 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');

    // 環境変数から設定を読み込み
    final inputFile =
        Platform.environment['INPUT_FILE'] ?? 'data/initial_problems.json';
    final validateFlag = Platform.environment['VALIDATE'] != 'false';

    print('📂 Loading templates from: $inputFile');
    print('🔍 Validate with AI: $validateFlag');
    print('-' * 60);

    // テンプレートファイルを読み込み
    final templates = await _loadTemplates(inputFile);
    if (templates.isEmpty) {
      print('❌ No templates found in $inputFile');
      exit(1);
    }

    print('📋 Loaded ${templates.length} templates');

    // 初期問題プールをシード
    final service = InitialProblemPoolService();

    // 既存の初期問題プールをチェック
    final existingCount = await service.countApprovedInitialProblems();
    if (existingCount > 0) {
      print(
        '⚠️  Found $existingCount existing initial problems',
      );
      print(
        '   Continue? (y/n): ',
      );
      final response = stdin.readLineSync()?.toLowerCase() ?? 'n';
      if (response != 'y') {
        print('❌ Aborted');
        exit(1);
      }
    }

    // 投入実行
    final seedCount = await service.seedInitialProblemPool(
      templates: templates,
      validateWithAIDiagnosis: validateFlag,
    );

    print('-' * 60);
    print('✅ Successfully seeded $seedCount problems');
    print('🎉 Initial problem pool is ready!');
    print('   Ready for cold-start launch');
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print(stackTrace);
    exit(1);
  }
}

/// テンプレートをJSONファイルから読み込み
Future<List<InitialProblemTemplate>> _loadTemplates(String filePath) async {
  final file = File(filePath);

  if (!file.existsSync()) {
    print('❌ File not found: $filePath');
    return [];
  }

  try {
    final content = await file.readAsString();
    final json = jsonDecode(content);

    if (json is List) {
      return json
          .map((item) => InitialProblemTemplate.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (json is Map && json.containsKey('templates')) {
      final templates = json['templates'] as List;
      return templates
          .map((item) => InitialProblemTemplate.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    print('❌ Invalid JSON structure in $filePath');
    return [];
  } catch (e) {
    print('❌ Error reading file: $e');
    return [];
  }
}
