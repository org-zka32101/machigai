import 'package:flutter_test/flutter_test.dart';
import 'package:machigai/services/offline_analytics_service.dart';

void main() {
  group('Offline Analytics Tests', () {
    late OfflineAnalyticsService analyticsService;

    setUp(() {
      analyticsService = OfflineAnalyticsService();
    });

    tearDown(() {
      analyticsService.clearAnalytics();
    });

    test('Record sync success event', () {
      analyticsService.recordEvent(
        AnalyticsEvent(
          type: AnalyticsEventType.syncSuccess,
          data: {
            'operationType': 'createChallenge',
          },
          duration: const Duration(milliseconds: 200),
        ),
      );

      final metrics = analyticsService.getSyncPerformanceMetrics();
      expect(metrics.totalSyncOperations, 1);
      expect(metrics.successfulSyncs, 1);
      expect(metrics.failedSyncs, 0);
      expect(metrics.successRate, 100.0);
    });

    test('Record multiple sync events with statistics', () {
      // Record 5 successes
      for (int i = 0; i < 5; i++) {
        analyticsService.recordEvent(
          AnalyticsEvent(
            type: AnalyticsEventType.syncSuccess,
            data: {'operationType': 'createChallenge'},
            duration: Duration(milliseconds: 200 + (i * 50)),
          ),
        );
      }

      // Record 1 failure
      analyticsService.recordEvent(
        AnalyticsEvent(
          type: AnalyticsEventType.syncFailed,
          data: {'operationType': 'updateChallenge'},
          duration: const Duration(milliseconds: 100),
        ),
      );

      final metrics = analyticsService.getSyncPerformanceMetrics();
      expect(metrics.totalSyncOperations, 6);
      expect(metrics.successfulSyncs, 5);
      expect(metrics.failedSyncs, 1);
      expect(metrics.successRate, closeTo(83.33, 1.0));
      expect(metrics.averageSyncDuration.inMilliseconds, greaterThan(0));
      expect(metrics.minSyncDuration.inMilliseconds, lessThan(300));
      expect(metrics.maxSyncDuration.inMilliseconds, greaterThan(300));
    });

    test('Track offline mode events', () {
      // Enable offline mode
      analyticsService.recordEvent(
        AnalyticsEvent(
          type: AnalyticsEventType.offlineModeEnabled,
          data: {'isOffline': true},
        ),
      );

      // Wait a bit
      Future.delayed(const Duration(milliseconds: 100));

      // Disable offline mode
      analyticsService.recordEvent(
        AnalyticsEvent(
          type: AnalyticsEventType.offlineModeDisabled,
          data: {'isOffline': false},
        ),
      );

      final metrics = analyticsService.getOfflineUsageMetrics();
      expect(metrics.totalOfflineEvents, 1);
    });

    test('Track queued operations while offline', () {
      // Record queued operations
      for (int i = 0; i < 3; i++) {
        analyticsService.recordEvent(
          AnalyticsEvent(
            type: AnalyticsEventType.operationQueued,
            data: {
              'operationType': 'createChallenge',
              'queueIndex': i,
            },
          ),
        );
      }

      // Record successful syncs
      for (int i = 0; i < 2; i++) {
        analyticsService.recordEvent(
          AnalyticsEvent(
            type: AnalyticsEventType.syncSuccess,
            data: {'operationType': 'createChallenge'},
            duration: const Duration(milliseconds: 200),
          ),
        );
      }

      final metrics = analyticsService.getOfflineUsageMetrics();
      expect(metrics.operationsQueuedOffline, 3);
      expect(metrics.operationsSyncedAfterOffline, 2);
    });

    test('Track connectivity changes', () {
      // Go offline
      analyticsService.recordEvent(
        AnalyticsEvent(
          type: AnalyticsEventType.connectivityChanged,
          data: {'isOnline': false},
        ),
      );

      // Come back online
      analyticsService.recordEvent(
        AnalyticsEvent(
          type: AnalyticsEventType.connectivityChanged,
          data: {'isOnline': true},
        ),
      );

      final metrics = analyticsService.getNetworkMetrics();
      expect(metrics.isOnline, true);
      expect(metrics.disconnectionCount, 1);
      expect(metrics.longestDisconnectionDuration, isNotNull);
    });

    test('Track multiple disconnections', () {
      // First disconnection
      analyticsService.recordEvent(
        AnalyticsEvent(
          type: AnalyticsEventType.connectivityChanged,
          data: {'isOnline': false},
        ),
      );

      analyticsService.recordEvent(
        AnalyticsEvent(
          type: AnalyticsEventType.connectivityChanged,
          data: {'isOnline': true},
        ),
      );

      // Second disconnection
      analyticsService.recordEvent(
        AnalyticsEvent(
          type: AnalyticsEventType.connectivityChanged,
          data: {'isOnline': false},
        ),
      );

      analyticsService.recordEvent(
        AnalyticsEvent(
          type: AnalyticsEventType.connectivityChanged,
          data: {'isOnline': true},
        ),
      );

      final metrics = analyticsService.getNetworkMetrics();
      expect(metrics.disconnectionCount, 2);
    });

    test('Get events by type', () {
      // Record various events
      analyticsService.recordEvent(
        AnalyticsEvent(
          type: AnalyticsEventType.syncSuccess,
          data: {'type': 'test'},
        ),
      );

      analyticsService.recordEvent(
        AnalyticsEvent(
          type: AnalyticsEventType.syncSuccess,
          data: {'type': 'test'},
        ),
      );

      analyticsService.recordEvent(
        AnalyticsEvent(
          type: AnalyticsEventType.syncFailed,
          data: {'type': 'test'},
        ),
      );

      final successEvents = analyticsService.getEventsByType(AnalyticsEventType.syncSuccess);
      final failedEvents = analyticsService.getEventsByType(AnalyticsEventType.syncFailed);

      expect(successEvents.length, 2);
      expect(failedEvents.length, 1);
    });

    test('Get events in time range', () {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));

      // Record event
      analyticsService.recordEvent(
        AnalyticsEvent(
          type: AnalyticsEventType.syncSuccess,
          data: {'type': 'test'},
        ),
      );

      // Get events from last 2 hours
      final eventsInRange = analyticsService.getEventsInRange(
        oneHourAgo,
        now.add(const Duration(hours: 1)),
      );

      expect(eventsInRange.isNotEmpty, true);
    });

    test('Track retry operations', () {
      // Record retried operations
      analyticsService.recordEvent(
        AnalyticsEvent(
          type: AnalyticsEventType.operationRetried,
          data: {'operationId': 'op_001'},
        ),
      );

      analyticsService.recordEvent(
        AnalyticsEvent(
          type: AnalyticsEventType.operationRetried,
          data: {'operationId': 'op_002'},
        ),
      );

      final metrics = analyticsService.getSyncPerformanceMetrics();
      expect(metrics.totalRetries, 2);
    });

    test('Get summary report', () {
      // Record various events
      analyticsService.recordEvent(
        AnalyticsEvent(
          type: AnalyticsEventType.syncSuccess,
          data: {'type': 'test'},
          duration: const Duration(milliseconds: 200),
        ),
      );

      analyticsService.recordEvent(
        AnalyticsEvent(
          type: AnalyticsEventType.operationQueued,
          data: {'operationType': 'test'},
        ),
      );

      final report = analyticsService.getSummaryReport();

      expect(report.containsKey('timestamp'), true);
      expect(report.containsKey('totalEvents'), true);
      expect(report.containsKey('syncPerformance'), true);
      expect(report.containsKey('offlineUsage'), true);
      expect(report.containsKey('networkMetrics'), true);
      expect(report['totalEvents'], 2);
    });

    test('Export analytics as JSON', () {
      analyticsService.recordEvent(
        AnalyticsEvent(
          type: AnalyticsEventType.syncSuccess,
          data: {'type': 'test'},
          duration: const Duration(milliseconds: 200),
        ),
      );

      final json = analyticsService.exportAsJson();

      expect(json.contains('timestamp'), true);
      expect(json.contains('totalEvents'), true);
      expect(json.contains('syncPerformance'), true);
      expect(json.contains('offlineUsage'), true);
      expect(json.contains('networkMetrics'), true);
    });

    test('Clear analytics', () {
      analyticsService.recordEvent(
        AnalyticsEvent(
          type: AnalyticsEventType.syncSuccess,
          data: {'type': 'test'},
        ),
      );

      var metrics = analyticsService.getSyncPerformanceMetrics();
      expect(metrics.totalSyncOperations, 1);

      analyticsService.clearAnalytics();

      metrics = analyticsService.getSyncPerformanceMetrics();
      expect(metrics.totalSyncOperations, 0);
    });

    test('Track drafts created offline', () {
      analyticsService.recordEvent(
        AnalyticsEvent(
          type: AnalyticsEventType.draftCreated,
          data: {'draftId': 'draft_001'},
        ),
      );

      analyticsService.recordEvent(
        AnalyticsEvent(
          type: AnalyticsEventType.draftCreated,
          data: {'draftId': 'draft_002'},
        ),
      );

      final metrics = analyticsService.getOfflineUsageMetrics();
      expect(metrics.draftsCreatedOffline, 2);
    });

    test('Track prefetch events', () {
      analyticsService.recordEvent(
        AnalyticsEvent(
          type: AnalyticsEventType.prefetchTriggered,
          data: {'screen': 'challenges'},
          duration: const Duration(milliseconds: 100),
        ),
      );

      analyticsService.recordEvent(
        AnalyticsEvent(
          type: AnalyticsEventType.prefetchSuccess,
          data: {'itemsCount': 10},
          duration: const Duration(milliseconds: 150),
        ),
      );

      final events = analyticsService.getEventsByType(AnalyticsEventType.prefetchTriggered);
      expect(events.length, 1);
    });
  });
}
