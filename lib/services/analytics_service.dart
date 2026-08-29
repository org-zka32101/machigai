import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// 計測・分析サービス
/// Firebase Analytics/Crashlytics/Remote Configを統合管理
class AnalyticsService {
  static final _analytics = FirebaseAnalytics.instance;
  static final _crashlytics = FirebaseCrashlytics.instance;
  static final _remoteConfig = FirebaseRemoteConfig.instance;

  /// 初期化
  static Future<void> initialize() async {
    try {
      // Remote Config の初期化
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 30),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      await _remoteConfig.setDefaults({
        'paywall_enabled': true,
        'subscription_price': 200,
        'free_trial_days': 14,
      });

      // 初回フェッチ
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      print('Error initializing Remote Config: $e');
    }
  }

  /// Aha Moment到達イベント
  static Future<void> trackAhaMomentReached(String type) async {
    await _analytics.logEvent(
      name: 'aha_moment_reached',
      parameters: {
        'type': type, // 'challenge_created' or 'correct_answers'
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// チャレンジ完了イベント
  static Future<void> trackDailyChallengeCompleted(int score) async {
    await _analytics.logEvent(
      name: 'daily_challenge_completed',
      parameters: {
        'score': score,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// ストリーク達成イベント（Day7, 14, 30）
  static Future<void> trackStreakMilestone(int dayCount) async {
    await _analytics.logEvent(
      name: 'streak_day_$dayCount',
      parameters: {
        'day_count': dayCount,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// ペイウォール表示イベント
  static Future<void> trackPaywallShown() async {
    await _analytics.logEvent(
      name: 'paywall_shown',
      parameters: {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// 購読開始イベント
  static Future<void> trackSubscriptionStarted(String productId) async {
    await _analytics.logEvent(
      name: 'subscription_started',
      parameters: {
        'product_id': productId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// エラー記録
  static Future<void> recordError(
    dynamic exception,
    StackTrace stackTrace,
  ) async {
    await _crashlytics.recordError(exception, stackTrace);
  }

  /// Remote Configから値を取得
  static String getRemoteConfigString(String key, String defaultValue) {
    return _remoteConfig.getString(key).isEmpty
        ? defaultValue
        : _remoteConfig.getString(key);
  }

  static bool getRemoteConfigBool(String key, bool defaultValue) {
    try {
      return _remoteConfig.getBool(key);
    } catch (_) {
      return defaultValue;
    }
  }

  static int getRemoteConfigInt(String key, int defaultValue) {
    try {
      return _remoteConfig.getInt(key);
    } catch (_) {
      return defaultValue;
    }
  }
}
