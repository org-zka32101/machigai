/// Service Worker configuration and management for web offline support
class ServiceWorkerConfig {
  final String workerPath; // Path to service worker file
  final List<String> cachePaths; // Paths to cache
  final List<String> networkOnlyPaths; // Paths to never cache
  final List<String> assetsToCache; // Assets to pre-cache
  final Duration cacheDuration; // How long to keep cache
  final bool enableOfflineMode; // Enable offline functionality
  final String cacheName; // Cache storage name

  ServiceWorkerConfig({
    this.workerPath = '/sw.js',
    this.cachePaths = const ['/api/', '/assets/'],
    this.networkOnlyPaths = const ['/auth/', '/logout/'],
    this.assetsToCache = const [],
    this.cacheDuration = const Duration(days: 7),
    this.enableOfflineMode = true,
    this.cacheName = 'machigai_cache_v1',
  });

  Map<String, dynamic> toMap() => {
    'workerPath': workerPath,
    'cachePaths': cachePaths,
    'networkOnlyPaths': networkOnlyPaths,
    'assetsToCache': assetsToCache,
    'cacheDurationDays': cacheDuration.inDays,
    'enableOfflineMode': enableOfflineMode,
    'cacheName': cacheName,
  };
}

/// Service Worker lifecycle events
enum ServiceWorkerEvent {
  installed,
  activated,
  updateAvailable,
  offline,
  online,
  syncTriggered,
}

/// Service Worker registration and management
class ServiceWorkerService {
  static final ServiceWorkerService _instance =
      ServiceWorkerService._internal();

  factory ServiceWorkerService() {
    return _instance;
  }

  ServiceWorkerService._internal();

  ServiceWorkerConfig? _config;
  bool _isRegistered = false;
  final List<ServiceWorkerEvent> _eventLog = [];
  int _cacheSize = 0;
  DateTime? _lastSyncTime;

  /// Initialize Service Worker
  Future<void> initialize(ServiceWorkerConfig config) async {
    _config = config;

    if (!_isSupported()) {
      throw Exception('Service Workers not supported on this platform');
    }

    try {
      _logEvent(ServiceWorkerEvent.installed);
      _isRegistered = true;
    } catch (e) {
      throw Exception('Failed to register Service Worker: $e');
    }
  }

  /// Check if Service Workers are supported
  bool _isSupported() {
    // In web context, this would check navigator.serviceWorker support
    // In Flutter web, we'd check via js interop
    return true; // Placeholder for web platform
  }

  /// Register for background sync
  Future<void> registerBackgroundSync(String tagName) async {
    if (!_isRegistered || _config == null) {
      throw Exception('Service Worker not initialized');
    }

    try {
      _lastSyncTime = DateTime.now();
      _logEvent(ServiceWorkerEvent.syncTriggered);
    } catch (e) {
      throw Exception('Background sync registration failed: $e');
    }
  }

  /// Trigger immediate sync
  Future<void> triggerSync(String tagName) async {
    if (!_isRegistered) {
      throw Exception('Service Worker not registered');
    }

    try {
      _logEvent(ServiceWorkerEvent.syncTriggered);
      _lastSyncTime = DateTime.now();
    } catch (e) {
      throw Exception('Failed to trigger sync: $e');
    }
  }

  /// Cache assets
  Future<void> cacheAssets(List<String> assets) async {
    if (!_isRegistered || _config == null) {
      throw Exception('Service Worker not initialized');
    }

    try {
      for (final asset in assets) {
        // In web context, this would interact with Cache API
        _cacheSize += asset.length;
      }
    } catch (e) {
      throw Exception('Failed to cache assets: $e');
    }
  }

  /// Precache essential assets
  Future<void> precacheEssentialAssets() async {
    if (_config == null) return;

    try {
      await cacheAssets(_config!.assetsToCache);
      _logEvent(ServiceWorkerEvent.activated);
    } catch (e) {
      throw Exception('Precaching failed: $e');
    }
  }

  /// Enable offline mode
  void enableOfflineMode() {
    if (_config != null) {
      final newConfig = ServiceWorkerConfig(
        workerPath: _config!.workerPath,
        cachePaths: _config!.cachePaths,
        networkOnlyPaths: _config!.networkOnlyPaths,
        assetsToCache: _config!.assetsToCache,
        cacheDuration: _config!.cacheDuration,
        enableOfflineMode: true,
        cacheName: _config!.cacheName,
      );
      _config = newConfig;
    }
  }

  /// Disable offline mode
  void disableOfflineMode() {
    if (_config != null) {
      final newConfig = ServiceWorkerConfig(
        workerPath: _config!.workerPath,
        cachePaths: _config!.cachePaths,
        networkOnlyPaths: _config!.networkOnlyPaths,
        assetsToCache: _config!.assetsToCache,
        cacheDuration: _config!.cacheDuration,
        enableOfflineMode: false,
        cacheName: _config!.cacheName,
      );
      _config = newConfig;
    }
  }

  /// Clear cache
  Future<void> clearCache() async {
    if (!_isRegistered) {
      throw Exception('Service Worker not registered');
    }

    try {
      _cacheSize = 0;
    } catch (e) {
      throw Exception('Failed to clear cache: $e');
    }
  }

  /// Get cache size in bytes
  int getCacheSize() {
    return _cacheSize;
  }

  /// Get cache info
  Map<String, dynamic> getCacheInfo() {
    return {
      'enabled': _isRegistered,
      'cacheName': _config?.cacheName,
      'cacheSize': _cacheSize,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'offlineModeEnabled': _config?.enableOfflineMode ?? false,
    };
  }

  /// Check if online
  bool get isOnline {
    // In web context, this would check navigator.onLine
    return true; // Placeholder
  }

  /// Listen to connectivity changes
  void onConnectivityChange(Function(bool isOnline) callback) {
    // In web context, this would listen to online/offline events
  }

  /// Get last sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Get sync status
  Map<String, dynamic> getSyncStatus() {
    return {
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'isSyncing': false,
      'pendingSyncs': 0,
      'successfulSyncs': 0,
      'failedSyncs': 0,
    };
  }

  /// Log event
  void _logEvent(ServiceWorkerEvent event) {
    _eventLog.add(event);
    if (_eventLog.length > 100) {
      _eventLog.removeAt(0);
    }
  }

  /// Get event log
  List<ServiceWorkerEvent> getEventLog() {
    return List.from(_eventLog);
  }

  /// Export configuration as JSON
  String exportConfigAsJson() {
    return '''
{
  "timestamp": "${DateTime.now().toIso8601String()}",
  "config": ${_mapToJson(_config?.toMap() ?? {})},
  "status": ${_mapToJson(_buildStatusMap())},
  "eventLog": [
    ${_eventLog.map((e) => '"${e.toString().split('.').last}"').join(', ')}
  ]
}
''';
  }

  Map<String, dynamic> _buildStatusMap() {
    return {
      'isRegistered': _isRegistered,
      'isOnline': isOnline,
      'cacheSize': _cacheSize,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'offlineModeEnabled': _config?.enableOfflineMode ?? false,
    };
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
      } else if (entry.value is bool) {
        buffer.write('${entry.value}');
      } else if (entry.value is num) {
        buffer.write('${entry.value}');
      } else if (entry.value is List) {
        buffer.write('[${(entry.value as List).map((v) => '"$v"').join(', ')}]');
      } else if (entry.value is Map) {
        buffer.write(_mapToJson(entry.value as Map<String, dynamic>));
      } else {
        buffer.write('"${entry.value}"');
      }

      if (i < entries.length - 1) {
        buffer.write(', ');
      }
    }
    buffer.write('}');
    return buffer.toString();
  }

  /// Unregister Service Worker
  Future<void> unregister() async {
    if (!_isRegistered) return;

    try {
      _isRegistered = false;
      _cacheSize = 0;
      _eventLog.clear();
    } catch (e) {
      throw Exception('Failed to unregister Service Worker: $e');
    }
  }

  /// Get configuration
  ServiceWorkerConfig? get config => _config;

  /// Check if registered
  bool get isRegistered => _isRegistered;
}
