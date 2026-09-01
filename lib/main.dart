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
      pageBuilder: (context, state) => MaterialPage(
        child: const HomeScreen(),
      ),
      routes: [
        // 問題作成フロー
        GoRoute(
          path: 'template-select',
          pageBuilder: (context, state) => _buildFadeTransitionPage(
            const TemplateSelectScreen(),
            state,
          ),
        ),
        GoRoute(
          path: 'edit',
          pageBuilder: (context, state) {
            final templateId = state.extra as String?;
            return _buildSlideTransitionPage(
              EditScreen(templateId: templateId ?? ''),
              state,
            );
          },
        ),
        GoRoute(
          path: 'challenge-published',
          pageBuilder: (context, state) {
            final extras = state.extra as Map<String, dynamic>?;
            if (extras == null) {
              return MaterialPage(child: const HomeScreen());
            }
            return _buildFadeTransitionPage(
              ChallengePublishedScreen(
                template: extras['template'] as VideoTemplate,
                edit: extras['edit'] as VideoEdit,
              ),
              state,
            );
          },
        ),

        // 問題解答フロー
        GoRoute(
          path: 'solve',
          pageBuilder: (context, state) {
            final challengeId = state.queryParameters['id'];
            final shareToken = state.queryParameters['token'];
            return _buildSlideTransitionPage(
              SolveScreen(
                challengeId: challengeId,
                shareToken: shareToken,
              ),
              state,
            );
          },
        ),
        GoRoute(
          path: 'result',
          pageBuilder: (context, state) {
            final extras = state.extra as Map<String, dynamic>?;
            if (extras == null) {
              return MaterialPage(child: const HomeScreen());
            }
            return _buildScaleTransitionPage(
              ResultScreen(
                challenge: extras['challenge'] as UserGeneratedChallenge,
                isCorrect: extras['isCorrect'] as bool,
                solveTimeSeconds: extras['solveTimeSeconds'] as int,
                selectedRegionIndex: extras['selectedRegionIndex'] as int,
              ),
              state,
            );
          },
        ),

        // ランキング・プロフィール
        GoRoute(
          path: 'ranking',
          pageBuilder: (context, state) => _buildFadeTransitionPage(
            const RankingScreen(),
            state,
          ),
        ),
        GoRoute(
          path: 'profile',
          pageBuilder: (context, state) => _buildFadeTransitionPage(
            const ProfileScreen(),
            state,
          ),
        ),
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

/// Fade transition page builder
CustomTransitionPage<void> _buildFadeTransitionPage(
  Widget child,
  GoRouterState state,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
  );
}

/// Slide transition page builder (from right)
CustomTransitionPage<void> _buildSlideTransitionPage(
  Widget child,
  GoRouterState state,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: animation.drive(
          Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeInOut)),
        ),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 400),
  );
}

/// Scale transition page builder (pop-in effect)
CustomTransitionPage<void> _buildScaleTransitionPage(
  Widget child,
  GoRouterState state,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: animation.drive(
          Tween<double>(begin: 0.8, end: 1.0).chain(
            CurveTween(curve: Curves.elasticOut),
          ),
        ),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 500),
    reverseTransitionDuration: const Duration(milliseconds: 300),
  );
}
