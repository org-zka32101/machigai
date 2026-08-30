import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:machigai/config/firebase_options.dart';
import 'package:machigai/services/analytics_service.dart';
import 'package:machigai/views/index.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Crashlytics設定
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // 分析サービス初期化
  await AnalyticsService.initialize();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'まちがいラボ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}

/// GoRouter設定
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: [
        // 問題作成フロー
        GoRoute(
          path: 'template-select',
          builder: (context, state) => const TemplateSelectScreen(),
        ),
        GoRoute(
          path: 'edit',
          builder: (context, state) {
            final templateId = state.extra as String?;
            return EditScreen(templateId: templateId ?? '');
          },
        ),
        GoRoute(
          path: 'challenge-published',
          builder: (context, state) {
            final extras = state.extra as Map<String, dynamic>?;
            if (extras == null) {
              return const HomeScreen();
            }
            return ChallengePublishedScreen(
              template: extras['template'] as VideoTemplate,
              edit: extras['edit'] as VideoEdit,
            );
          },
        ),

        // 問題解答フロー
        // GoRoute(
        //   path: 'solve',
        //   builder: (context, state) => const SolveScreen(),
        // ),
        // GoRoute(
        //   path: 'result',
        //   builder: (context, state) => const ResultScreen(),
        // ),

        // ランキング・プロフィール
        // GoRoute(
        //   path: 'ranking',
        //   builder: (context, state) => const RankingScreen(),
        // ),
        // GoRoute(
        //   path: 'profile',
        //   builder: (context, state) => const ProfileScreen(),
        // ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('エラー')),
    body: Center(
      child: Text('ページが見つかりません: ${state.location}'),
    ),
  ),
);
