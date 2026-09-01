import 'package:flutter/foundation.dart';

/// Performance metrics for monitoring and optimization
class PerformanceMetric {
  final String name;
  final DateTime timestamp;
  final int durationMs;
  final String? operation;
  final bool isError;

  PerformanceMetric({
    required this.name,
    required this.timestamp,
    required this.durationMs,
    this.operation,
    this.isError = false,
  });

  @override
  String toString() =>
      'PerformanceMetric($name: ${durationMs}ms at ${timestamp.toIso8601String()})';
}

/// Service for tracking and monitoring application performance
/// Useful for identifying bottlenecks and optimizing critical paths
class PerformanceService {
  static final PerformanceService _instance =
      PerformanceService._internal();

  factory PerformanceService() {
    return _instance;
  }

  PerformanceService._internal();

  // Metric tracking
  final List<PerformanceMetric> _metrics = [];
  static const int maxMetrics = 1000; // Keep last 1000 metrics

  // Stopwatch for measuring operations
  final Map<String, Stopwatch> _activeStopwatches = {};

  /// Start measuring an operation
  void startMeasure(String operationName) {
    if (!kDebugMode) return; // Skip in release mode for performance

    _activeStopwatches[operationName] = Stopwatch()..start();
  }

  /// End measuring and record the metric
  void endMeasure(String operationName, {String? operation, bool isError = false}) {
    if (!kDebugMode) return;

    final stopwatch = _activeStopwatches[operationName];
    if (stopwatch == null) return;

    final durationMs = stopwatch.elapsedMilliseconds;
    stopwatch.stop();
    _activeStopwatches.remove(operationName);

    // Log if it's slow (> 1 second)
    if (durationMs > 1000) {
      debugPrint(
        '⚠️ SLOW OPERATION: $operationName took ${durationMs}ms${operation != null ? ' ($operation)' : ''}',
      );
    }

    _recordMetric(
      PerformanceMetric(
        name: operationName,
        timestamp: DateTime.now(),
        durationMs: durationMs,
        operation: operation,
        isError: isError,
      ),
    );
  }

  /// Record a manually timed metric
  void recordMetric(PerformanceMetric metric) {
    if (!kDebugMode) return;
    _recordMetric(metric);
  }

  void _recordMetric(PerformanceMetric metric) {
    _metrics.add(metric);

    // Keep metrics list under max size
    if (_metrics.length > maxMetrics) {
      _metrics.removeRange(0, _metrics.length - maxMetrics);
    }

    // Print slow operations in debug mode
    if (kDebugMode && metric.durationMs > 500) {
      debugPrint(
        '⏱️ ${metric.name}: ${metric.durationMs}ms',
      );
    }
  }

  /// Get metrics filtered by name
  List<PerformanceMetric> getMetricsByName(String name) {
    return _metrics.where((m) => m.name.contains(name)).toList();
  }

  /// Get average duration for an operation
  int getAverageDuration(String operationName) {
    final filtered = getMetricsByName(operationName);
    if (filtered.isEmpty) return 0;
    final sum = filtered.fold<int>(0, (sum, m) => sum + m.durationMs);
    return (sum / filtered.length).toInt();
  }

  /// Get percentile duration (e.g., p95 = 95th percentile)
  int getDurationPercentile(String operationName, double percentile) {
    final filtered = getMetricsByName(operationName);
    if (filtered.isEmpty) return 0;

    final sorted = filtered.map((m) => m.durationMs).toList()..sort();
    final index = ((sorted.length * percentile) / 100).toInt();
    return sorted[index];
  }

  /// Get performance statistics
  Map<String, dynamic> getStats(String operationName) {
    final filtered = getMetricsByName(operationName);
    if (filtered.isEmpty) {
      return {
        'count': 0,
        'average': 0,
        'min': 0,
        'max': 0,
        'p95': 0,
        'p99': 0,
        'errors': 0,
      };
    }

    final durations = filtered.map((m) => m.durationMs).toList();
    final sorted = durations..sort();

    return {
      'count': filtered.length,
      'average': getAverageDuration(operationName),
      'min': sorted.first,
      'max': sorted.last,
      'p95': getDurationPercentile(operationName, 95),
      'p99': getDurationPercentile(operationName, 99),
      'errors': filtered.where((m) => m.isError).length,
    };
  }

  /// Clear all metrics
  void clearMetrics() {
    _metrics.clear();
    _activeStopwatches.clear();
  }

  /// Print performance report
  void printReport({String? filterName}) {
    if (_metrics.isEmpty) {
      debugPrint('No performance metrics recorded');
      return;
    }

    debugPrint('=== PERFORMANCE REPORT ===');
    final operationNames = _metrics.map((m) => m.name).toSet();

    for (final name in operationNames) {
      if (filterName != null && !name.contains(filterName)) continue;

      final stats = getStats(name);
      debugPrint(
        '\n$name:\n'
        '  Calls: ${stats['count']}\n'
        '  Average: ${stats['average']}ms\n'
        '  Min: ${stats['min']}ms\n'
        '  Max: ${stats['max']}ms\n'
        '  P95: ${stats['p95']}ms\n'
        '  P99: ${stats['p99']}ms\n'
        '  Errors: ${stats['errors']}',
      );
    }
  }

  /// Get all metrics
  List<PerformanceMetric> getAllMetrics() => List.unmodifiable(_metrics);
}

/// Utility class for using stopwatch as context manager
class StopwatchScope {
  final PerformanceService _service;
  final String operationName;
  late final Stopwatch _stopwatch;

  StopwatchScope({
    required this.operationName,
    PerformanceService? service,
  }) : _service = service ?? PerformanceService() {
    _stopwatch = Stopwatch()..start();
  }

  Future<T> measure<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } finally {
      _stopwatch.stop();
      _service.recordMetric(
        PerformanceMetric(
          name: operationName,
          timestamp: DateTime.now(),
          durationMs: _stopwatch.elapsedMilliseconds,
        ),
      );
    }
  }
}
