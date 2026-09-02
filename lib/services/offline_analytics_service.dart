import 'dart:async';
import 'package:machigai/services/sync_manager.dart';
import 'package:machigai/services/local_storage_service.dart';

/// Analytics event types
enum AnalyticsEventType {
  syncStarted,
  syncSuccess,
  syncFailed,
  operationQueued,
  operationRetried,
  draftCreated,
  draftDeleted,
  offlineModeEnabled,
  offlineModeDisabled,
  connectivityChanged,
  prefetchTriggered,
  prefetchSuccess,
  prefetchFailed,
}

/// Individual analytics event
class AnalyticsEvent {
  final AnalyticsEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final Duration? duration;

  AnalyticsEvent({
    required this.type,
    required this.data,
    this.duration,
  }) : timestamp = DateTime.now();

  Map<String, dynamic> toMap() => {
    'type': type.toString(),
    'timestamp': timestamp.toIso8601String(),
    'duration': duration?.inMilliseconds,
    'data': data,
  };
}

/// Sync performance metrics
class SyncPerformanceMetrics {
  final int totalSyncOperations;
  final int successfulSyncs;
  final int failedSyncs;
  final Duration averageSyncDuration;
  final Duration minSyncDuration;
  final Duration maxSyncDuration;
  final double successRate;
  final int totalRetries;

  SyncPerformanceMetrics({
    required this.totalSyncOperations,
    required this.successfulSyncs,
    required this.failedSyncs,
    required this.averageSyncDuration,
    required this.minSyncDuration,
    required this.maxSyncDuration,
    required this.successRate,
    required this.totalRetries,
  });

  Map<String, dynamic> toMap() => {
    'totalSyncOperations': totalSyncOperations,
    'successfulSyncs': successfulSyncs,
    'failedSyncs': failedSyncs,
    'averageSyncDurationMs': averageSyncDuration.inMilliseconds,
    'minSyncDurationMs': minSyncDuration.inMilliseconds,
    'maxSyncDurationMs': maxSyncDuration.inMilliseconds,
    'successRate': successRate,
    'totalRetries': totalRetries,
  };
}

/// Offline usage metrics
class OfflineUsageMetrics {
  final int totalOfflineEvents;
  final Duration totalOfflineTime;
  final int operationsQueuedOffline;
  final int operationsSyncedAfterOffline;
  final int draftsCreatedOffline;
  final double offlineSuccessRate;

  OfflineUsageMetrics({
    required this.totalOfflineEvents,
    required this.totalOfflineTime,
    required this.operationsQueuedOffline,
    required this.operationsSyncedAfterOffline,
    required this.draftsCreatedOffline,
    required this.offlineSuccessRate,
  });

  Map<String, dynamic> toMap() => {
    'totalOfflineEvents': totalOfflineEvents,
    'totalOfflineTimeMinutes': totalOfflineTime.inMinutes,
    'operationsQueuedOffline': operationsQueuedOffline,
    'operationsSyncedAfterOffline': operationsSyncedAfterOffline,
    'draftsCreatedOffline': draftsCreatedOffline,
    'offlineSuccessRate': offlineSuccessRate,
  };
}

/// Network condition metrics
class NetworkMetrics {
  final bool isOnline;
  final String? currentNetworkType; // wifi, mobile, none
  final int disconnectionCount;
  final DateTime? lastDisconnectionTime;
  final Duration? longestDisconnectionDuration;

  NetworkMetrics({
    required this.isOnline,
    this.currentNetworkType,
    required this.disconnectionCount,
    this.lastDisconnectionTime,
    this.longestDisconnectionDuration,
  });

  Map<String, dynamic> toMap() => {
    'isOnline': isOnline,
    'currentNetworkType': currentNetworkType,
    'disconnectionCount': disconnectionCount,
    'lastDisconnectionTime': lastDisconnectionTime?.toIso8601String(),
    'longestDisconnectionDurationMinutes': longestDisconnectionDuration?.inMinutes,
  };
}

/// Analytics service for offline-first metrics
class OfflineAnalyticsService {
  static final OfflineAnalyticsService _instance = OfflineAnalyticsService._internal();

  factory OfflineAnalyticsService() {
    return _instance;
  }

  OfflineAnalyticsService._internal();

  // Event tracking
  final List<AnalyticsEvent> _events = [];
  final Map<String, List<Duration>> _syncDurations = {};

  // Offline tracking
  int _offlineEventCount = 0;
  DateTime? _offlineModeStartTime;
  final List<Duration> _offlinePeriods = [];
  int _operationsQueuedOffline = 0;
  int _operationsSyncedAfterOffline = 0;
  int _draftsCreatedOffline = 0;

  // Network tracking
  int _disconnectionCount = 0;
  DateTime? _lastDisconnectionTime;
  DateTime? _disconnectionStart;
  final List<Duration> _disconnectionDurations = [];
  bool _wasOnline = true;

  /// Record an analytics event
  void recordEvent(AnalyticsEvent event) {
    _events.add(event);

    // Keep only last 1000 events for memory efficiency
    if (_events.length > 1000) {
      _events.removeAt(0);
    }

    // Process specific events
    _processEvent(event);
  }

  /// Process event for specific tracking
  void _processEvent(AnalyticsEvent event) {
    switch (event.type) {
      case AnalyticsEventType.syncSuccess:
        if (event.duration != null) {
          final opType = event.data['operationType'] as String? ?? 'unknown';
          _syncDurations.putIfAbsent(opType, () => []).add(event.duration!);
        }
      case AnalyticsEventType.offlineModeEnabled:
        _offlineModeStartTime = event.timestamp;
        _offlineEventCount++;
      case AnalyticsEventType.offlineModeDisabled:
        if (_offlineModeStartTime != null) {
          _offlinePeriods.add(event.timestamp.difference(_offlineModeStartTime!));
          _offlineModeStartTime = null;
        }
      case AnalyticsEventType.operationQueued:
        _operationsQueuedOffline++;
      case AnalyticsEventType.syncSuccess:
        _operationsSyncedAfterOffline++;
      case AnalyticsEventType.draftCreated:
        _draftsCreatedOffline++;
      case AnalyticsEventType.connectivityChanged:
        final isOnline = event.data['isOnline'] as bool? ?? false;
        if (!isOnline && _wasOnline) {
          // Just went offline
          _disconnectionCount++;
          _disconnectionStart = event.timestamp;
          _lastDisconnectionTime = event.timestamp;
        } else if (isOnline && !_wasOnline && _disconnectionStart != null) {
          // Just came back online
          final duration = event.timestamp.difference(_disconnectionStart!);
          _disconnectionDurations.add(duration);
          _disconnectionStart = null;
        }
        _wasOnline = isOnline;
      default:
        break;
    }
  }

  /// Get sync performance metrics
  SyncPerformanceMetrics getSyncPerformanceMetrics() {
    final successfulSyncs = _events.where((e) => e.type == AnalyticsEventType.syncSuccess).length;
    final failedSyncs = _events.where((e) => e.type == AnalyticsEventType.syncFailed).length;
    final totalSyncs = successfulSyncs + failedSyncs;

    // Calculate duration statistics
    final allDurations = _syncDurations.values.expand((l) => l).toList();
    Duration avgDuration = Duration.zero;
    Duration minDuration = Duration(seconds: 999999);
    Duration maxDuration = Duration.zero;

    if (allDurations.isNotEmpty) {
      avgDuration = Duration(
        milliseconds: allDurations
            .fold(0, (sum, d) => sum + d.inMilliseconds) ~/ allDurations.length,
      );
      minDuration = allDurations.reduce((a, b) => a < b ? a : b);
      maxDuration = allDurations.reduce((a, b) => a > b ? a : b);
    }

    final totalRetries = _events.where((e) => e.type == AnalyticsEventType.operationRetried).length;

    return SyncPerformanceMetrics(
      totalSyncOperations: totalSyncs,
      successfulSyncs: successfulSyncs,
      failedSyncs: failedSyncs,
      averageSyncDuration: avgDuration,
      minSyncDuration: minDuration == Duration(seconds: 999999) ? Duration.zero : minDuration,
      maxSyncDuration: maxDuration,
      successRate: totalSyncs > 0 ? (successfulSyncs / totalSyncs) * 100 : 0,
      totalRetries: totalRetries,
    );
  }

  /// Get offline usage metrics
  OfflineUsageMetrics getOfflineUsageMetrics() {
    Duration totalOfflineTime = Duration.zero;
    for (final period in _offlinePeriods) {
      totalOfflineTime += period;
    }

    final totalQueued = _events.where((e) => e.type == AnalyticsEventType.operationQueued).length;
    final totalSynced = _events.where((e) => e.type == AnalyticsEventType.syncSuccess).length;

    return OfflineUsageMetrics(
      totalOfflineEvents: _offlineEventCount,
      totalOfflineTime: totalOfflineTime,
      operationsQueuedOffline: _operationsQueuedOffline,
      operationsSyncedAfterOffline: _operationsSyncedAfterOffline,
      draftsCreatedOffline: _draftsCreatedOffline,
      offlineSuccessRate: totalQueued > 0 ? (_operationsSyncedAfterOffline / totalQueued) * 100 : 0,
    );
  }

  /// Get network metrics
  NetworkMetrics getNetworkMetrics() {
    Duration? longestDisconnection;
    if (_disconnectionDurations.isNotEmpty) {
      longestDisconnection = _disconnectionDurations.reduce((a, b) => a > b ? a : b);
    }

    return NetworkMetrics(
      isOnline: _wasOnline,
      currentNetworkType: null, // Would be populated from connectivity_plus
      disconnectionCount: _disconnectionCount,
      lastDisconnectionTime: _lastDisconnectionTime,
      longestDisconnectionDuration: longestDisconnection,
    );
  }

  /// Get summary report
  Map<String, dynamic> getSummaryReport() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'totalEvents': _events.length,
      'syncPerformance': getSyncPerformanceMetrics().toMap(),
      'offlineUsage': getOfflineUsageMetrics().toMap(),
      'networkMetrics': getNetworkMetrics().toMap(),
    };
  }

  /// Get events by type
  List<AnalyticsEvent> getEventsByType(AnalyticsEventType type) {
    return _events.where((e) => e.type == type).toList();
  }

  /// Get events in time range
  List<AnalyticsEvent> getEventsInRange(DateTime start, DateTime end) {
    return _events
        .where((e) => e.timestamp.isAfter(start) && e.timestamp.isBefore(end))
        .toList();
  }

  /// Clear all analytics data
  void clearAnalytics() {
    _events.clear();
    _syncDurations.clear();
    _offlineEventCount = 0;
    _offlineModeStartTime = null;
    _offlinePeriods.clear();
    _operationsQueuedOffline = 0;
    _operationsSyncedAfterOffline = 0;
    _draftsCreatedOffline = 0;
    _disconnectionCount = 0;
    _lastDisconnectionTime = null;
    _disconnectionStart = null;
    _disconnectionDurations.clear();
  }

  /// Export analytics as JSON
  String exportAsJson() {
    return '''
{
  "timestamp": "${DateTime.now().toIso8601String()}",
  "totalEvents": ${_events.length},
  "syncPerformance": ${_mapToJson(getSyncPerformanceMetrics().toMap())},
  "offlineUsage": ${_mapToJson(getOfflineUsageMetrics().toMap())},
  "networkMetrics": ${_mapToJson(getNetworkMetrics().toMap())}
}
''';
  }

  /// Helper to convert map to JSON string
  String _mapToJson(Map<String, dynamic> map) {
    final buffer = StringBuffer('{');
    final entries = map.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      buffer.write('"${entry.key}": ');

      if (entry.value == null) {
        buffer.write('null');
      } else if (entry.value is String) {
        buffer.write('"${entry.value}"');
      } else if (entry.value is Map) {
        buffer.write(_mapToJson(entry.value as Map<String, dynamic>));
      } else {
        buffer.write('${entry.value}');
      }

      if (i < entries.length - 1) {
        buffer.write(', ');
      }
    }
    buffer.write('}');
    return buffer.toString();
  }
}
