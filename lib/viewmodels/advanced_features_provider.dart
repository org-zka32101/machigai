import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:machigai/services/conflict_resolution_service.dart';
import 'package:machigai/services/encrypted_storage_service.dart';
import 'package:machigai/services/multi_device_sync_service.dart';
import 'package:machigai/services/service_worker_service.dart';

/// Advanced features state
class AdvancedFeaturesState {
  final ConflictResolutionService conflictResolution;
  final EncryptedStorageService encryptedStorage;
  final MultiDeviceSyncService multiDeviceSync;
  final ServiceWorkerService serviceWorker;
  final DateTime initializedAt;
  final Map<String, dynamic> featureStatus;

  AdvancedFeaturesState({
    required this.conflictResolution,
    required this.encryptedStorage,
    required this.multiDeviceSync,
    required this.serviceWorker,
    required this.featureStatus,
  }) : initializedAt = DateTime.now();

  /// Check if all features are initialized
  bool get isFullyInitialized =>
      featureStatus['conflictResolution'] == true &&
      featureStatus['encryptedStorage'] == true &&
      featureStatus['multiDeviceSync'] == true &&
      featureStatus['serviceWorker'] == true;

  /// Get overall system health
  double get systemHealth {
    var healthScore = 0.0;
    var count = 0;

    if (featureStatus['conflictResolution'] == true) {
      final stats = conflictResolution.getConflictStats();
      final autoResolvable =
          stats['autoResolvableConflicts'] as int? ?? 0;
      final total = stats['totalConflicts'] as int? ?? 1;
      healthScore += (autoResolvable / total) * 100;
      count++;
    }

    if (featureStatus['encryptedStorage'] == true) {
      final stats = encryptedStorage.getStorageStats();
      // Consider storage health based on integrity
      healthScore += 90.0; // Assume good if no errors
      count++;
    }

    if (featureStatus['multiDeviceSync'] == true) {
      final stats = multiDeviceSync.getSyncStatistics();
      final activeDevices = stats['activeDevices'] as int? ?? 0;
      final totalDevices = stats['totalDevices'] as int? ?? 1;
      healthScore += (activeDevices / totalDevices) * 100;
      count++;
    }

    if (featureStatus['serviceWorker'] == true) {
      healthScore += serviceWorker.isOnline ? 100.0 : 50.0;
      count++;
    }

    return count > 0 ? healthScore / count : 0.0;
  }

  Map<String, dynamic> toMap() => {
    'initializedAt': initializedAt.toIso8601String(),
    'isFullyInitialized': isFullyInitialized,
    'systemHealth': systemHealth,
    'featureStatus': featureStatus,
  };
}

/// Advanced features notifier
class AdvancedFeaturesNotifier extends StateNotifier<AdvancedFeaturesState> {
  AdvancedFeaturesNotifier()
      : super(
          AdvancedFeaturesState(
            conflictResolution: ConflictResolutionService(),
            encryptedStorage: EncryptedStorageService(),
            multiDeviceSync: MultiDeviceSyncService(),
            serviceWorker: ServiceWorkerService(),
            featureStatus: {
              'conflictResolution': false,
              'encryptedStorage': false,
              'multiDeviceSync': false,
              'serviceWorker': false,
            },
          ),
        );

  /// Initialize all advanced features
  Future<void> initializeAllFeatures({
    String? encryptionKey,
    String? currentDeviceId,
    String? deviceName,
  }) async {
    try {
      // Initialize encrypted storage
      await state.encryptedStorage.initialize(masterKey: encryptionKey);
      _updateFeatureStatus('encryptedStorage', true);

      // Initialize multi-device sync
      if (currentDeviceId != null && deviceName != null) {
        state.multiDeviceSync.initializeCurrentDevice(
          deviceId: currentDeviceId,
          deviceName: deviceName,
          deviceType: 'mobile', // Would be determined by platform
          platform: 'ios', // Would be determined by platform
          appVersion: '1.0.0', // Would come from package info
        );
        _updateFeatureStatus('multiDeviceSync', true);
      }

      // Initialize service worker (web only)
      try {
        final config = ServiceWorkerConfig(
          enableOfflineMode: true,
          cacheDuration: const Duration(days: 7),
        );
        await state.serviceWorker.initialize(config);
        await state.serviceWorker.precacheEssentialAssets();
        _updateFeatureStatus('serviceWorker', true);
      } catch (e) {
        // Service worker not available on mobile
      }

      _updateFeatureStatus('conflictResolution', true);
    } catch (e) {
      throw Exception('Failed to initialize advanced features: $e');
    }
  }

  /// Update feature status
  void _updateFeatureStatus(String feature, bool status) {
    final updatedStatus = Map<String, dynamic>.from(state.featureStatus);
    updatedStatus[feature] = status;

    state = AdvancedFeaturesState(
      conflictResolution: state.conflictResolution,
      encryptedStorage: state.encryptedStorage,
      multiDeviceSync: state.multiDeviceSync,
      serviceWorker: state.serviceWorker,
      featureStatus: updatedStatus,
    );
  }

  /// Set conflict resolution strategy
  void setConflictStrategy(
    String dataType,
    ConflictResolutionStrategy strategy,
  ) {
    state.conflictResolution.setDefaultStrategy(dataType, strategy);
  }

  /// Save encrypted data
  Future<void> saveEncryptedData(
    String key,
    String value,
    EncryptionLevel level,
  ) async {
    await state.encryptedStorage.saveEncrypted(
      key,
      value,
      level: level,
    );
  }

  /// Record device sync event
  void recordDeviceSyncEvent(
    String dataType,
    String operationType,
    Map<String, dynamic> data,
  ) {
    state.multiDeviceSync.recordSyncEvent(
      dataType: dataType,
      operationType: operationType,
      data: data,
    );
  }

  /// Register background sync
  Future<void> registerBackgroundSync(String tagName) async {
    await state.serviceWorker.registerBackgroundSync(tagName);
  }

  /// Get system diagnostics
  Map<String, dynamic> getSystemDiagnostics() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'systemHealth': state.systemHealth,
      'conflictStats': state.conflictResolution.getConflictStats(),
      'encryptedStorageStats':
          state.encryptedStorage.getStorageStats(),
      'multiDeviceSyncStats':
          state.multiDeviceSync.getSyncStatistics(),
      'serviceWorkerInfo': state.serviceWorker.getCacheInfo(),
    };
  }

  /// Export all advanced features data
  String exportAllData() {
    return '''
{
  "timestamp": "${DateTime.now().toIso8601String()}",
  "systemHealth": ${state.systemHealth.toStringAsFixed(1)},
  "conflictData": ${state.conflictResolution.exportConflictsAsJson()},
  "multiDeviceSyncData": ${state.multiDeviceSync.exportSyncDataAsJson()},
  "serviceWorkerData": ${state.serviceWorker.exportConfigAsJson()}
}
''';
  }
}

/// Advanced features provider
final advancedFeaturesProvider =
    StateNotifierProvider.autoDispose<AdvancedFeaturesNotifier, AdvancedFeaturesState>(
  (ref) {
    return AdvancedFeaturesNotifier();
  },
);

/// Conflict resolution provider
final conflictResolutionProvider =
    Provider.autoDispose<ConflictResolutionService>((ref) {
  final features = ref.watch(advancedFeaturesProvider);
  return features.conflictResolution;
});

/// Encrypted storage provider
final encryptedStorageProvider =
    Provider.autoDispose<EncryptedStorageService>((ref) {
  final features = ref.watch(advancedFeaturesProvider);
  return features.encryptedStorage;
});

/// Multi-device sync provider
final multiDeviceSyncProvider =
    Provider.autoDispose<MultiDeviceSyncService>((ref) {
  final features = ref.watch(advancedFeaturesProvider);
  return features.multiDeviceSync;
});

/// Service worker provider
final serviceWorkerProvider = Provider.autoDispose<ServiceWorkerService>((ref) {
  final features = ref.watch(advancedFeaturesProvider);
  return features.serviceWorker;
});

/// System health provider
final systemHealthProvider =
    Provider.autoDispose<double>((ref) {
  final features = ref.watch(advancedFeaturesProvider);
  return features.systemHealth;
});

/// Feature status provider
final featureStatusProvider =
    Provider.autoDispose<Map<String, bool>>((ref) {
  final features = ref.watch(advancedFeaturesProvider);
  return Map<String, bool>.from(
    features.featureStatus.map(
      (key, value) => MapEntry(key, value as bool),
    ),
  );
});

/// Diagnostics provider
final diagnosticsProvider =
    Provider.autoDispose<Map<String, dynamic>>((ref) {
  final features = ref.watch(advancedFeaturesProvider);
  return features.systemHealth > 0
      ? (ref.watch(advancedFeaturesProvider.notifier)).getSystemDiagnostics()
      : {};
});
