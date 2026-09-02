import 'dart:async';
import 'package:uuid/uuid.dart';

/// Device information for multi-device sync
class DeviceInfo {
  final String deviceId;
  final String deviceName;
  final String deviceType; // mobile, tablet, web, desktop
  final String platform; // ios, android, windows, macos, linux, web
  final String appVersion;
  final DateTime registeredAt;
  DateTime? lastSyncAt;
  int totalSyncsCount;
  int failedSyncsCount;

  DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    required this.platform,
    required this.appVersion,
  })  : registeredAt = DateTime.now(),
        totalSyncsCount = 0,
        failedSyncsCount = 0;

  /// Check if device is active (synced within last 24 hours)
  bool get isActive =>
      lastSyncAt != null &&
      DateTime.now().difference(lastSyncAt!).inHours < 24;

  /// Get sync success rate
  double get syncSuccessRate =>
      totalSyncsCount > 0
          ? ((totalSyncsCount - failedSyncsCount) / totalSyncsCount) * 100
          : 0;

  Map<String, dynamic> toMap() => {
    'deviceId': deviceId,
    'deviceName': deviceName,
    'deviceType': deviceType,
    'platform': platform,
    'appVersion': appVersion,
    'registeredAt': registeredAt.toIso8601String(),
    'lastSyncAt': lastSyncAt?.toIso8601String(),
    'totalSyncsCount': totalSyncsCount,
    'failedSyncsCount': failedSyncsCount,
    'isActive': isActive,
    'syncSuccessRate': syncSuccessRate,
  };
}

/// Synchronization event for cross-device tracking
class SyncEvent {
  final String eventId;
  final String sourceDeviceId;
  final String dataType;
  final String operationType; // create, update, delete
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final List<String> syncedToDevices; // Devices this was synced to

  SyncEvent({
    required this.sourceDeviceId,
    required this.dataType,
    required this.operationType,
    required this.data,
    List<String>? syncedToDevices,
  })  : eventId = const Uuid().v4(),
        timestamp = DateTime.now(),
        syncedToDevices = syncedToDevices ?? [];

  /// Mark device as synced
  void markSyncedToDevice(String deviceId) {
    if (!syncedToDevices.contains(deviceId)) {
      syncedToDevices.add(deviceId);
    }
  }

  /// Check if synced to specific device
  bool isSyncedToDevice(String deviceId) => syncedToDevices.contains(deviceId);

  /// Get sync status
  int get syncProgress => syncedToDevices.length;

  Map<String, dynamic> toMap() => {
    'eventId': eventId,
    'sourceDeviceId': sourceDeviceId,
    'dataType': dataType,
    'operationType': operationType,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'syncedToDevices': syncedToDevices,
  };
}

/// Service for managing multi-device synchronization
class MultiDeviceSyncService {
  static final MultiDeviceSyncService _instance =
      MultiDeviceSyncService._internal();

  factory MultiDeviceSyncService() {
    return _instance;
  }

  MultiDeviceSyncService._internal();

  // Device tracking
  final Map<String, DeviceInfo> _registeredDevices = {};
  String? _currentDeviceId;

  // Sync event tracking
  final List<SyncEvent> _syncEvents = [];
  final Map<String, int> _deviceSyncCounts = {};

  // Sync coordination
  late Timer _syncCoordinationTimer;
  final StreamController<SyncEvent> _syncEventController =
      StreamController<SyncEvent>.broadcast();

  /// Initialize with current device info
  void initializeCurrentDevice({
    required String deviceId,
    required String deviceName,
    required String deviceType,
    required String platform,
    required String appVersion,
  }) {
    _currentDeviceId = deviceId;

    if (!_registeredDevices.containsKey(deviceId)) {
      _registeredDevices[deviceId] = DeviceInfo(
        deviceId: deviceId,
        deviceName: deviceName,
        deviceType: deviceType,
        platform: platform,
        appVersion: appVersion,
      );
    }

    _startSyncCoordination();
  }

  /// Register additional device
  void registerDevice({
    required String deviceId,
    required String deviceName,
    required String deviceType,
    required String platform,
    required String appVersion,
  }) {
    if (!_registeredDevices.containsKey(deviceId)) {
      _registeredDevices[deviceId] = DeviceInfo(
        deviceId: deviceId,
        deviceName: deviceName,
        deviceType: deviceType,
        platform: platform,
        appVersion: appVersion,
      );
    }
  }

  /// Record a sync event
  void recordSyncEvent({
    required String dataType,
    required String operationType,
    required Map<String, dynamic> data,
  }) {
    if (_currentDeviceId == null) {
      throw Exception('Current device not initialized');
    }

    final event = SyncEvent(
      sourceDeviceId: _currentDeviceId!,
      dataType: dataType,
      operationType: operationType,
      data: data,
    );

    _syncEvents.add(event);

    // Keep only last 500 events for memory efficiency
    if (_syncEvents.length > 500) {
      _syncEvents.removeAt(0);
    }

    _syncEventController.add(event);
  }

  /// Mark sync completion for device
  void markSyncComplete(String eventId, String deviceId, {bool success = true}) {
    final eventIndex = _syncEvents.indexWhere((e) => e.eventId == eventId);
    if (eventIndex != -1) {
      _syncEvents[eventIndex].markSyncedToDevice(deviceId);

      // Update device sync stats
      final device = _registeredDevices[deviceId];
      if (device != null) {
        device.lastSyncAt = DateTime.now();
        device.totalSyncsCount++;
        if (!success) {
          device.failedSyncsCount++;
        }
      }
    }
  }

  /// Start sync coordination timer
  void _startSyncCoordination() {
    _syncCoordinationTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _coordinateDeviceSyncs(),
    );
  }

  /// Coordinate syncs across devices
  void _coordinateDeviceSyncs() {
    // Get events that haven't been synced to all devices
    final pendingEvents =
        _syncEvents.where((e) => e.syncedToDevices.length < _registeredDevices.length);

    for (final event in pendingEvents) {
      for (final device in _registeredDevices.values) {
        if (!event.isSyncedToDevice(device.deviceId) &&
            device.isActive &&
            device.deviceId != event.sourceDeviceId) {
          // Device is eligible for sync
          _notifyDeviceForSync(device.deviceId, event);
        }
      }
    }
  }

  /// Notify device about pending sync
  void _notifyDeviceForSync(String deviceId, SyncEvent event) {
    // In production, this would send a notification to the other device
    // via push notification or background sync
  }

  /// Get all registered devices
  List<DeviceInfo> getAllDevices() {
    return _registeredDevices.values.toList();
  }

  /// Get active devices (synced recently)
  List<DeviceInfo> getActiveDevices() {
    return _registeredDevices.values.where((d) => d.isActive).toList();
  }

  /// Get sync events for device
  List<SyncEvent> getSyncEventsForDevice(String deviceId) {
    return _syncEvents.where((e) => !e.isSyncedToDevice(deviceId)).toList();
  }

  /// Get sync events by type
  List<SyncEvent> getSyncEventsByType(String dataType) {
    return _syncEvents.where((e) => e.dataType == dataType).toList();
  }

  /// Get recent sync events
  List<SyncEvent> getRecentSyncEvents({Duration? within}) {
    final cutoffTime = DateTime.now().subtract(within ?? const Duration(hours: 1));
    return _syncEvents.where((e) => e.timestamp.isAfter(cutoffTime)).toList();
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStatistics() {
    return {
      'totalDevices': _registeredDevices.length,
      'activeDevices': getActiveDevices().length,
      'totalSyncEvents': _syncEvents.length,
      'pendingSyncCount': _syncEvents
          .where((e) => e.syncedToDevices.length < _registeredDevices.length)
          .length,
      'deviceSyncStats': _getDeviceSyncStats(),
      'dataTypeSyncStats': _getDataTypeSyncStats(),
    };
  }

  Map<String, dynamic> _getDeviceSyncStats() {
    final stats = <String, dynamic>{};
    for (final device in _registeredDevices.values) {
      stats[device.deviceId] = {
        'name': device.deviceName,
        'isActive': device.isActive,
        'totalSyncs': device.totalSyncsCount,
        'failedSyncs': device.failedSyncsCount,
        'successRate': device.syncSuccessRate,
        'lastSync': device.lastSyncAt?.toIso8601String(),
      };
    }
    return stats;
  }

  Map<String, int> _getDataTypeSyncStats() {
    final stats = <String, int>{};
    for (final event in _syncEvents) {
      stats[event.dataType] = (stats[event.dataType] ?? 0) + 1;
    }
    return stats;
  }

  /// Export sync data as JSON
  String exportSyncDataAsJson() {
    return '''
{
  "timestamp": "${DateTime.now().toIso8601String()}",
  "devices": [
    ${_registeredDevices.values.map((d) => _deviceToJson(d)).join(',\n    ')}
  ],
  "recentSyncEvents": [
    ${getRecentSyncEvents().map((e) => _eventToJson(e)).join(',\n    ')}
  ],
  "statistics": ${_mapToJson(getSyncStatistics())}
}
''';
  }

  String _deviceToJson(DeviceInfo device) {
    return '''
{
      "deviceId": "${device.deviceId}",
      "deviceName": "${device.deviceName}",
      "deviceType": "${device.deviceType}",
      "platform": "${device.platform}",
      "isActive": ${device.isActive},
      "syncSuccessRate": ${device.syncSuccessRate.toStringAsFixed(1)},
      "lastSyncAt": "${device.lastSyncAt?.toIso8601String() ?? 'never'}"
    }''';
  }

  String _eventToJson(SyncEvent event) {
    return '''
{
      "eventId": "${event.eventId}",
      "sourceDeviceId": "${event.sourceDeviceId}",
      "dataType": "${event.dataType}",
      "operationType": "${event.operationType}",
      "timestamp": "${event.timestamp.toIso8601String()}",
      "syncProgress": "${event.syncProgress}/${_registeredDevices.length}"
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

  /// Get sync event stream
  Stream<SyncEvent> get syncEventStream => _syncEventController.stream;

  /// Unregister device
  void unregisterDevice(String deviceId) {
    _registeredDevices.remove(deviceId);
  }

  /// Clear all sync data
  void clearSyncData() {
    _syncEvents.clear();
    _deviceSyncCounts.clear();
  }

  /// Dispose resources
  void dispose() {
    _syncCoordinationTimer.cancel();
    _syncEventController.close();
  }
}
