import 'package:machigai/services/local_storage_service.dart';

/// Conflict resolution strategies for data sync
enum ConflictResolutionStrategy {
  /// Prefer local version
  preferLocal,
  /// Prefer remote version
  preferRemote,
  /// Prefer most recent version
  preferMostRecent,
  /// Merge both versions
  merge,
  /// Manual resolution required
  requireManualResolution,
}

/// Represents a data conflict
class DataConflict {
  final String id;
  final String dataType; // e.g., 'challenge', 'user', 'draft'
  final dynamic localVersion;
  final dynamic remoteVersion;
  final DateTime localTimestamp;
  final DateTime remoteTimestamp;
  final ConflictResolutionStrategy strategy;
  final DateTime detectedAt;

  DataConflict({
    required this.id,
    required this.dataType,
    required this.localVersion,
    required this.remoteVersion,
    required this.localTimestamp,
    required this.remoteTimestamp,
    required this.strategy,
  }) : detectedAt = DateTime.now();

  /// Determine which version is more recent
  bool get isLocalNewer => localTimestamp.isAfter(remoteTimestamp);

  /// Check if conflict is resolvable automatically
  bool get isAutoResolvable =>
      strategy != ConflictResolutionStrategy.requireManualResolution;

  Map<String, dynamic> toMap() => {
    'id': id,
    'dataType': dataType,
    'localVersion': localVersion,
    'remoteVersion': remoteVersion,
    'localTimestamp': localTimestamp.toIso8601String(),
    'remoteTimestamp': remoteTimestamp.toIso8601String(),
    'strategy': strategy.toString(),
    'detectedAt': detectedAt.toIso8601String(),
  };
}

/// Service for handling data conflicts during sync
class ConflictResolutionService {
  static final ConflictResolutionService _instance =
      ConflictResolutionService._internal();

  factory ConflictResolutionService() {
    return _instance;
  }

  ConflictResolutionService._internal();

  // Conflict tracking
  final List<DataConflict> _detectedConflicts = [];
  final Map<String, ConflictResolutionStrategy> _strategyPreferences = {};

  /// Detect conflict between local and remote versions
  DataConflict detectConflict({
    required String id,
    required String dataType,
    required dynamic localVersion,
    required dynamic remoteVersion,
    required DateTime localTimestamp,
    required DateTime remoteTimestamp,
  }) {
    // Check if versions are actually different
    if (localVersion == remoteVersion) {
      throw Exception('No conflict: versions are identical');
    }

    final strategy = _strategyPreferences[dataType] ??
        ConflictResolutionStrategy.requireManualResolution;

    final conflict = DataConflict(
      id: id,
      dataType: dataType,
      localVersion: localVersion,
      remoteVersion: remoteVersion,
      localTimestamp: localTimestamp,
      remoteTimestamp: remoteTimestamp,
      strategy: strategy,
    );

    _detectedConflicts.add(conflict);

    // Keep only last 100 conflicts for memory efficiency
    if (_detectedConflicts.length > 100) {
      _detectedConflicts.removeAt(0);
    }

    return conflict;
  }

  /// Resolve a conflict using the specified strategy
  dynamic resolveConflict(DataConflict conflict) {
    switch (conflict.strategy) {
      case ConflictResolutionStrategy.preferLocal:
        return conflict.localVersion;

      case ConflictResolutionStrategy.preferRemote:
        return conflict.remoteVersion;

      case ConflictResolutionStrategy.preferMostRecent:
        return conflict.isLocalNewer
            ? conflict.localVersion
            : conflict.remoteVersion;

      case ConflictResolutionStrategy.merge:
        return _mergeVersions(conflict);

      case ConflictResolutionStrategy.requireManualResolution:
        throw Exception(
          'Conflict $conflict.id requires manual resolution',
        );
    }
  }

  /// Merge two versions (deep merge for maps)
  dynamic _mergeVersions(DataConflict conflict) {
    final local = conflict.localVersion;
    final remote = conflict.remoteVersion;

    // Handle map merging
    if (local is Map && remote is Map) {
      final merged = Map<String, dynamic>.from(local);
      for (final entry in remote.entries) {
        if (!merged.containsKey(entry.key) ||
            (remote[entry.key] is Map && merged[entry.key] is Map)) {
          merged[entry.key] = entry.value;
        }
      }
      return merged;
    }

    // Handle list merging (prefer longer list, merge unique items)
    if (local is List && remote is List) {
      final merged = <dynamic>[];
      merged.addAll(local);
      for (final item in remote) {
        if (!merged.contains(item)) {
          merged.add(item);
        }
      }
      return merged;
    }

    // Default: prefer most recent
    return conflict.isLocalNewer ? local : remote;
  }

  /// Set default strategy for a data type
  void setDefaultStrategy(
    String dataType,
    ConflictResolutionStrategy strategy,
  ) {
    _strategyPreferences[dataType] = strategy;
  }

  /// Get unresolved conflicts
  List<DataConflict> getUnresolvedConflicts() {
    return _detectedConflicts
        .where((c) => c.strategy ==
            ConflictResolutionStrategy.requireManualResolution)
        .toList();
  }

  /// Get conflicts by data type
  List<DataConflict> getConflictsByType(String dataType) {
    return _detectedConflicts
        .where((c) => c.dataType == dataType)
        .toList();
  }

  /// Get all recent conflicts (last hour)
  List<DataConflict> getRecentConflicts() {
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    return _detectedConflicts
        .where((c) => c.detectedAt.isAfter(oneHourAgo))
        .toList();
  }

  /// Manually resolve a conflict
  void manuallyResolveConflict(
    String conflictId,
    dynamic resolvedVersion,
  ) {
    final index = _detectedConflicts.indexWhere((c) => c.id == conflictId);
    if (index != -1) {
      _detectedConflicts.removeAt(index);
    }
  }

  /// Get conflict statistics
  Map<String, dynamic> getConflictStats() {
    return {
      'totalConflicts': _detectedConflicts.length,
      'unresolvedConflicts': getUnresolvedConflicts().length,
      'autoResolvableConflicts':
          _detectedConflicts.where((c) => c.isAutoResolvable).length,
      'conflictsByType': _getConflictsByTypeCount(),
      'averageResolutionTime': _calculateAverageResolutionTime(),
    };
  }

  Map<String, int> _getConflictsByTypeCount() {
    final counts = <String, int>{};
    for (final conflict in _detectedConflicts) {
      counts[conflict.dataType] = (counts[conflict.dataType] ?? 0) + 1;
    }
    return counts;
  }

  Duration _calculateAverageResolutionTime() {
    if (_detectedConflicts.isEmpty) return Duration.zero;

    var totalMs = 0;
    for (final conflict in _detectedConflicts) {
      totalMs += DateTime.now().difference(conflict.detectedAt).inMilliseconds;
    }
    return Duration(milliseconds: totalMs ~/ _detectedConflicts.length);
  }

  /// Export conflicts as JSON
  String exportConflictsAsJson() {
    return '''
{
  "timestamp": "${DateTime.now().toIso8601String()}",
  "totalConflicts": ${_detectedConflicts.length},
  "conflicts": [
    ${_detectedConflicts.map((c) => _conflictToJson(c)).join(',\n    ')}
  ],
  "statistics": ${_mapToJson(getConflictStats())}
}
''';
  }

  String _conflictToJson(DataConflict conflict) {
    return '''
{
      "id": "${conflict.id}",
      "dataType": "${conflict.dataType}",
      "strategy": "${conflict.strategy.toString().split('.').last}",
      "isAutoResolvable": ${conflict.isAutoResolvable},
      "localTimestamp": "${conflict.localTimestamp.toIso8601String()}",
      "remoteTimestamp": "${conflict.remoteTimestamp.toIso8601String()}",
      "detectedAt": "${conflict.detectedAt.toIso8601String()}"
    }''';
  }

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
      } else if (entry.value is Duration) {
        buffer.write('${(entry.value as Duration).inMilliseconds}');
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

  /// Clear all conflicts
  void clearConflicts() {
    _detectedConflicts.clear();
  }
}
