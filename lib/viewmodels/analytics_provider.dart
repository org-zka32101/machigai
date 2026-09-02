import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:machigai/services/offline_analytics_service.dart';

/// Analytics data state
class AnalyticsData {
  final SyncPerformanceMetrics syncPerformance;
  final OfflineUsageMetrics offlineUsage;
  final NetworkMetrics networkMetrics;
  final DateTime generatedAt;

  AnalyticsData({
    required this.syncPerformance,
    required this.offlineUsage,
    required this.networkMetrics,
    required this.generatedAt,
  });

  /// Get overall health score (0-100)
  int get healthScore {
    // Calculate based on sync success rate and network stability
    final syncScore = syncPerformance.successRate;
    final networkStability = 100 - (networkMetrics.disconnectionCount * 5).clamp(0, 100).toDouble();
    return ((syncScore + networkStability) / 2).toInt();
  }

  /// Get health status text
  String get healthStatus {
    if (healthScore >= 90) return 'Excellent';
    if (healthScore >= 75) return 'Good';
    if (healthScore >= 60) return 'Fair';
    if (healthScore >= 40) return 'Poor';
    return 'Critical';
  }

  /// Get health status color
  String get healthStatusColor {
    if (healthScore >= 90) return '#4CAF50'; // Green
    if (healthScore >= 75) return '#8BC34A'; // Light green
    if (healthScore >= 60) return '#FFC107'; // Amber
    if (healthScore >= 40) return '#FF9800'; // Orange
    return '#F44336'; // Red
  }
}

/// Analytics notifier
class AnalyticsNotifier extends StateNotifier<AnalyticsData> {
  final OfflineAnalyticsService _analyticsService;

  AnalyticsNotifier(this._analyticsService)
      : super(
          AnalyticsData(
            syncPerformance: _analyticsService.getSyncPerformanceMetrics(),
            offlineUsage: _analyticsService.getOfflineUsageMetrics(),
            networkMetrics: _analyticsService.getNetworkMetrics(),
            generatedAt: DateTime.now(),
          ),
        ) {
    _startAutoRefresh();
  }

  /// Auto-refresh analytics every 30 seconds
  void _startAutoRefresh() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 30));
      refresh();
      return true;
    });
  }

  /// Manually refresh analytics
  void refresh() {
    state = AnalyticsData(
      syncPerformance: _analyticsService.getSyncPerformanceMetrics(),
      offlineUsage: _analyticsService.getOfflineUsageMetrics(),
      networkMetrics: _analyticsService.getNetworkMetrics(),
      generatedAt: DateTime.now(),
    );
  }

  /// Record a sync event
  void recordSyncEvent(String operationType, Duration duration, bool success) {
    _analyticsService.recordEvent(
      AnalyticsEvent(
        type: success ? AnalyticsEventType.syncSuccess : AnalyticsEventType.syncFailed,
        data: {
          'operationType': operationType,
          'duration': duration.inMilliseconds,
        },
        duration: duration,
      ),
    );
    refresh();
  }

  /// Record offline mode change
  void recordOfflineModeChange(bool isOffline) {
    _analyticsService.recordEvent(
      AnalyticsEvent(
        type: isOffline ? AnalyticsEventType.offlineModeEnabled : AnalyticsEventType.offlineModeDisabled,
        data: {'isOffline': isOffline},
      ),
    );
    refresh();
  }

  /// Record connectivity change
  void recordConnectivityChange(bool isOnline) {
    _analyticsService.recordEvent(
      AnalyticsEvent(
        type: AnalyticsEventType.connectivityChanged,
        data: {'isOnline': isOnline},
      ),
    );
    refresh();
  }

  /// Record operation queued
  void recordOperationQueued(String operationType) {
    _analyticsService.recordEvent(
      AnalyticsEvent(
        type: AnalyticsEventType.operationQueued,
        data: {'operationType': operationType},
      ),
    );
    refresh();
  }

  /// Clear all analytics
  void clearAnalytics() {
    _analyticsService.clearAnalytics();
    refresh();
  }

  /// Export analytics as JSON string
  String exportAsJson() {
    return _analyticsService.exportAsJson();
  }
}

/// Analytics provider
final analyticsProvider = StateNotifierProvider.autoDispose<AnalyticsNotifier, AnalyticsData>(
  (ref) {
    return AnalyticsNotifier(OfflineAnalyticsService());
  },
);

/// Sync performance metrics provider
final syncPerformanceProvider = Provider.autoDispose<SyncPerformanceMetrics>((ref) {
  final analytics = ref.watch(analyticsProvider);
  return analytics.syncPerformance;
});

/// Offline usage metrics provider
final offlineUsageProvider = Provider.autoDispose<OfflineUsageMetrics>((ref) {
  final analytics = ref.watch(analyticsProvider);
  return analytics.offlineUsage;
});

/// Network metrics provider
final networkMetricsProvider = Provider.autoDispose<NetworkMetrics>((ref) {
  final analytics = ref.watch(analyticsProvider);
  return analytics.networkMetrics;
});

/// Health score provider
final healthScoreProvider = Provider.autoDispose<int>((ref) {
  final analytics = ref.watch(analyticsProvider);
  return analytics.healthScore;
});

/// Health status provider
final healthStatusProvider = Provider.autoDispose<String>((ref) {
  final analytics = ref.watch(analyticsProvider);
  return analytics.healthStatus;
});

/// Refresh analytics function provider
final analyticsRefreshProvider = Provider.autoDispose<Function>((ref) {
  return () {
    ref.read(analyticsProvider.notifier).refresh();
  };
});
