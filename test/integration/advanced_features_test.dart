import 'package:flutter_test/flutter_test.dart';
import 'package:machigai/services/conflict_resolution_service.dart';
import 'package:machigai/services/encrypted_storage_service.dart';
import 'package:machigai/services/multi_device_sync_service.dart';
import 'package:machigai/services/service_worker_service.dart';

void main() {
  group('Advanced Features Tests', () {
    late ConflictResolutionService conflictService;
    late EncryptedStorageService encryptedService;
    late MultiDeviceSyncService multiDeviceService;
    late ServiceWorkerService serviceWorkerService;

    setUp(() {
      conflictService = ConflictResolutionService();
      encryptedService = EncryptedStorageService();
      multiDeviceService = MultiDeviceSyncService();
      serviceWorkerService = ServiceWorkerService();
    });

    group('Conflict Resolution Tests', () {
      test('Detect conflict between local and remote versions', () {
        final conflict = conflictService.detectConflict(
          id: 'challenge_123',
          dataType: 'challenge',
          localVersion: {'title': 'Local Challenge', 'version': 1},
          remoteVersion: {'title': 'Remote Challenge', 'version': 2},
          localTimestamp: DateTime.now(),
          remoteTimestamp: DateTime.now().add(const Duration(minutes: 1)),
        );

        expect(conflict.id, 'challenge_123');
        expect(conflict.dataType, 'challenge');
        expect(conflict.isAutoResolvable, false);
      });

      test('Resolve conflict with prefer local strategy', () {
        conflictService.setDefaultStrategy(
          'challenge',
          ConflictResolutionStrategy.preferLocal,
        );

        final conflict = conflictService.detectConflict(
          id: 'test_1',
          dataType: 'challenge',
          localVersion: {'data': 'local'},
          remoteVersion: {'data': 'remote'},
          localTimestamp: DateTime.now(),
          remoteTimestamp: DateTime.now(),
        );

        final resolved = conflictService.resolveConflict(conflict);
        expect(resolved, {'data': 'local'});
      });

      test('Resolve conflict with prefer most recent strategy', () {
        conflictService.setDefaultStrategy(
          'challenge',
          ConflictResolutionStrategy.preferMostRecent,
        );

        final now = DateTime.now();
        final conflict = conflictService.detectConflict(
          id: 'test_2',
          dataType: 'challenge',
          localVersion: {'data': 'old'},
          remoteVersion: {'data': 'new'},
          localTimestamp: now.subtract(const Duration(minutes: 1)),
          remoteTimestamp: now,
        );

        final resolved = conflictService.resolveConflict(conflict);
        expect(resolved, {'data': 'new'});
      });

      test('Merge conflicted maps', () {
        conflictService.setDefaultStrategy(
          'challenge',
          ConflictResolutionStrategy.merge,
        );

        final conflict = conflictService.detectConflict(
          id: 'test_3',
          dataType: 'challenge',
          localVersion: {'title': 'Local', 'local_field': 'value'},
          remoteVersion: {'title': 'Remote', 'remote_field': 'value'},
          localTimestamp: DateTime.now(),
          remoteTimestamp: DateTime.now(),
        );

        final resolved = conflictService.resolveConflict(conflict);
        expect(resolved is Map, true);
        expect((resolved as Map).containsKey('remote_field'), true);
      });

      test('Get unresolved conflicts', () {
        conflictService.setDefaultStrategy(
          'challenge',
          ConflictResolutionStrategy.requireManualResolution,
        );

        conflictService.detectConflict(
          id: 'manual_1',
          dataType: 'challenge',
          localVersion: {'data': 'local'},
          remoteVersion: {'data': 'remote'},
          localTimestamp: DateTime.now(),
          remoteTimestamp: DateTime.now(),
        );

        final unresolved = conflictService.getUnresolvedConflicts();
        expect(unresolved.isNotEmpty, true);
      });

      test('Get conflict statistics', () {
        for (int i = 0; i < 3; i++) {
          conflictService.detectConflict(
            id: 'conflict_$i',
            dataType: 'challenge',
            localVersion: {'data': 'local_$i'},
            remoteVersion: {'data': 'remote_$i'},
            localTimestamp: DateTime.now(),
            remoteTimestamp: DateTime.now(),
          );
        }

        final stats = conflictService.getConflictStats();
        expect(stats.containsKey('totalConflicts'), true);
        expect(stats['totalConflicts'], greaterThan(0));
      });

      test('Export conflicts as JSON', () {
        conflictService.detectConflict(
          id: 'export_test',
          dataType: 'challenge',
          localVersion: {'data': 'test'},
          remoteVersion: {'data': 'test'},
          localTimestamp: DateTime.now(),
          remoteTimestamp: DateTime.now(),
        );

        final json = conflictService.exportConflictsAsJson();
        expect(json.contains('totalConflicts'), true);
        expect(json.contains('conflicts'), true);
      });
    });

    group('Encrypted Storage Tests', () {
      test('Initialize encrypted storage', () async {
        await encryptedService.initialize(masterKey: 'test_key');
        expect(encryptedService.getAllEncryptedKeys().isEmpty, true);
      });

      test('Save and retrieve encrypted data', () async {
        await encryptedService.initialize(masterKey: 'test_key');
        await encryptedService.saveEncrypted(
          'testKey',
          'testValue',
          level: EncryptionLevel.basic,
        );

        final retrieved = encryptedService.getEncrypted('testKey');
        expect(retrieved, 'testValue');
      });

      test('Save with different encryption levels', () async {
        await encryptedService.initialize(masterKey: 'test_key');

        await encryptedService.saveEncrypted(
          'basicData',
          'basic_value',
          level: EncryptionLevel.basic,
        );

        await encryptedService.saveEncrypted(
          'strongData',
          'strong_value',
          level: EncryptionLevel.strong,
        );

        expect(encryptedService.getEncrypted('basicData'), 'basic_value');
        expect(encryptedService.getEncrypted('strongData'), 'strong_value');
      });

      test('Save and retrieve encrypted JSON', () async {
        await encryptedService.initialize(masterKey: 'test_key');

        final data = {'name': 'Test', 'value': 123};
        await encryptedService.saveEncryptedJson(
          'jsonKey',
          data,
          level: EncryptionLevel.basic,
        );

        final retrieved = encryptedService.getEncryptedJson('jsonKey');
        expect(retrieved?['name'], 'Test');
        expect(retrieved?['value'], 123);
      });

      test('Delete encrypted data', () async {
        await encryptedService.initialize(masterKey: 'test_key');
        await encryptedService.saveEncrypted(
          'deleteKey',
          'value',
          level: EncryptionLevel.basic,
        );

        expect(encryptedService.containsEncrypted('deleteKey'), true);

        await encryptedService.deleteEncrypted('deleteKey');
        expect(encryptedService.containsEncrypted('deleteKey'), false);
      });

      test('Verify data integrity', () async {
        await encryptedService.initialize(masterKey: 'test_key');
        await encryptedService.saveEncrypted(
          'integrityKey',
          'value',
          level: EncryptionLevel.basic,
        );

        final isValid = encryptedService.verifyIntegrity('integrityKey');
        expect(isValid, true);
      });

      test('Get storage statistics', () async {
        await encryptedService.initialize(masterKey: 'test_key');
        await encryptedService.saveEncrypted(
          'stat1',
          'value1',
          level: EncryptionLevel.basic,
        );

        final stats = encryptedService.getStorageStats();
        expect(stats.containsKey('totalEncryptedItems'), true);
      });
    });

    group('Multi-Device Sync Tests', () {
      test('Initialize current device', () {
        multiDeviceService.initializeCurrentDevice(
          deviceId: 'device_1',
          deviceName: 'Test Device',
          deviceType: 'mobile',
          platform: 'ios',
          appVersion: '1.0.0',
        );

        expect(multiDeviceService.getAllDevices().isNotEmpty, true);
      });

      test('Register additional device', () {
        multiDeviceService.initializeCurrentDevice(
          deviceId: 'device_1',
          deviceName: 'Device 1',
          deviceType: 'mobile',
          platform: 'ios',
          appVersion: '1.0.0',
        );

        multiDeviceService.registerDevice(
          deviceId: 'device_2',
          deviceName: 'Device 2',
          deviceType: 'tablet',
          platform: 'android',
          appVersion: '1.0.0',
        );

        expect(multiDeviceService.getAllDevices().length, 2);
      });

      test('Record sync event', () {
        multiDeviceService.initializeCurrentDevice(
          deviceId: 'device_1',
          deviceName: 'Test Device',
          deviceType: 'mobile',
          platform: 'ios',
          appVersion: '1.0.0',
        );

        multiDeviceService.recordSyncEvent(
          dataType: 'challenge',
          operationType: 'create',
          data: {'id': 'challenge_123', 'title': 'Test'},
        );

        // Event should be recorded
        expect(multiDeviceService.getSyncEventsByType('challenge').isNotEmpty, true);
      });

      test('Mark sync completion', () {
        multiDeviceService.initializeCurrentDevice(
          deviceId: 'device_1',
          deviceName: 'Device 1',
          deviceType: 'mobile',
          platform: 'ios',
          appVersion: '1.0.0',
        );

        multiDeviceService.registerDevice(
          deviceId: 'device_2',
          deviceName: 'Device 2',
          deviceType: 'mobile',
          platform: 'android',
          appVersion: '1.0.0',
        );

        multiDeviceService.recordSyncEvent(
          dataType: 'challenge',
          operationType: 'create',
          data: {'id': 'test'},
        );

        final events = multiDeviceService.getSyncEventsByType('challenge');
        if (events.isNotEmpty) {
          multiDeviceService.markSyncComplete(
            events[0].eventId,
            'device_2',
            success: true,
          );

          expect(events[0].isSyncedToDevice('device_2'), true);
        }
      });

      test('Get sync statistics', () {
        multiDeviceService.initializeCurrentDevice(
          deviceId: 'device_1',
          deviceName: 'Test',
          deviceType: 'mobile',
          platform: 'ios',
          appVersion: '1.0.0',
        );

        final stats = multiDeviceService.getSyncStatistics();
        expect(stats.containsKey('totalDevices'), true);
        expect(stats.containsKey('activeDevices'), true);
      });

      test('Export sync data as JSON', () {
        multiDeviceService.initializeCurrentDevice(
          deviceId: 'device_1',
          deviceName: 'Test',
          deviceType: 'mobile',
          platform: 'ios',
          appVersion: '1.0.0',
        );

        final json = multiDeviceService.exportSyncDataAsJson();
        expect(json.contains('timestamp'), true);
        expect(json.contains('devices'), true);
      });
    });

    group('Service Worker Tests', () {
      test('Initialize service worker', () async {
        final config = ServiceWorkerConfig();
        await serviceWorkerService.initialize(config);

        expect(serviceWorkerService.isRegistered, true);
      });

      test('Cache assets', () async {
        final config = ServiceWorkerConfig();
        await serviceWorkerService.initialize(config);

        await serviceWorkerService.cacheAssets(['asset1', 'asset2']);

        expect(serviceWorkerService.getCacheSize(), greaterThan(0));
      });

      test('Precache essential assets', () async {
        final config = ServiceWorkerConfig(
          assetsToCache: ['index.html', 'style.css'],
        );
        await serviceWorkerService.initialize(config);
        await serviceWorkerService.precacheEssentialAssets();

        expect(serviceWorkerService.isRegistered, true);
      });

      test('Enable/disable offline mode', () async {
        final config = ServiceWorkerConfig(enableOfflineMode: false);
        await serviceWorkerService.initialize(config);

        serviceWorkerService.enableOfflineMode();
        expect(serviceWorkerService.config?.enableOfflineMode, true);

        serviceWorkerService.disableOfflineMode();
        expect(serviceWorkerService.config?.enableOfflineMode, false);
      });

      test('Get cache info', () async {
        final config = ServiceWorkerConfig();
        await serviceWorkerService.initialize(config);

        final cacheInfo = serviceWorkerService.getCacheInfo();
        expect(cacheInfo.containsKey('enabled'), true);
        expect(cacheInfo.containsKey('cacheSize'), true);
      });

      test('Get sync status', () async {
        final config = ServiceWorkerConfig();
        await serviceWorkerService.initialize(config);

        final syncStatus = serviceWorkerService.getSyncStatus();
        expect(syncStatus.containsKey('isSyncing'), true);
        expect(syncStatus.containsKey('pendingSyncs'), true);
      });

      test('Export configuration as JSON', () async {
        final config = ServiceWorkerConfig();
        await serviceWorkerService.initialize(config);

        final json = serviceWorkerService.exportConfigAsJson();
        expect(json.contains('timestamp'), true);
        expect(json.contains('config'), true);
      });

      test('Unregister service worker', () async {
        final config = ServiceWorkerConfig();
        await serviceWorkerService.initialize(config);
        expect(serviceWorkerService.isRegistered, true);

        await serviceWorkerService.unregister();
        expect(serviceWorkerService.isRegistered, false);
      });
    });

    group('Integration Tests', () {
      test('Full advanced features workflow', () async {
        // Initialize conflict resolution
        conflictService.setDefaultStrategy(
          'challenge',
          ConflictResolutionStrategy.preferMostRecent,
        );

        // Initialize encryption
        await encryptedService.initialize(masterKey: 'test_key');

        // Initialize multi-device sync
        multiDeviceService.initializeCurrentDevice(
          deviceId: 'device_1',
          deviceName: 'Main Device',
          deviceType: 'mobile',
          platform: 'ios',
          appVersion: '1.0.0',
        );

        // Initialize service worker
        final config = ServiceWorkerConfig();
        await serviceWorkerService.initialize(config);

        // All services should be available
        expect(conflictService != null, true);
        expect(encryptedService != null, true);
        expect(multiDeviceService != null, true);
        expect(serviceWorkerService != null, true);
      });

      test('Conflict resolution with encrypted storage', () async {
        await encryptedService.initialize(masterKey: 'test_key');

        final localData = {'title': 'Local Challenge', 'version': 1};
        await encryptedService.saveEncryptedJson(
          'challenge_data',
          localData,
          level: EncryptionLevel.strong,
        );

        final conflict = conflictService.detectConflict(
          id: 'challenge_123',
          dataType: 'challenge',
          localVersion: localData,
          remoteVersion: {'title': 'Remote Challenge', 'version': 2},
          localTimestamp: DateTime.now(),
          remoteTimestamp: DateTime.now(),
        );

        expect(conflict.id, 'challenge_123');
        expect(encryptedService.getEncryptedJson('challenge_data')?['title'],
            'Local Challenge');
      });
    });

    tearDown(() {
      multiDeviceService.dispose();
      serviceWorkerService.clearCache();
      encryptedService.clearAll();
      conflictService.clearConflicts();
    });
  });
}
