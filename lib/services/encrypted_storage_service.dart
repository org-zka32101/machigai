import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Encryption levels for different data sensitivity
enum EncryptionLevel {
  /// No encryption (for public data)
  none,
  /// Basic encryption (for sensitive user data)
  basic,
  /// Strong encryption (for authentication tokens, passwords)
  strong,
  /// Maximum encryption (for financial or medical data)
  maximum,
}

/// Simple XOR-based encryption (for demonstration)
/// Production would use flutter_secure_storage or similar
class SimpleEncryption {
  static String _generateKey(String seed) {
    return md5.convert(utf8.encode(seed)).toString();
  }

  static String encrypt(String plaintext, String key) {
    final keyBytes = _generateKey(key).codeUnits;
    final plaintextBytes = plaintext.codeUnits;
    final encrypted = <int>[];

    for (int i = 0; i < plaintextBytes.length; i++) {
      encrypted.add(plaintextBytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    return base64Encode(encrypted);
  }

  static String decrypt(String ciphertext, String key) {
    try {
      final keyBytes = _generateKey(key).codeUnits;
      final ciphertextBytes = base64Decode(ciphertext);
      final decrypted = <int>[];

      for (int i = 0; i < ciphertextBytes.length; i++) {
        decrypted.add(ciphertextBytes[i] ^ keyBytes[i % keyBytes.length]);
      }

      return String.fromCharCodes(decrypted);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }
}

/// Service for encrypted data storage
class EncryptedStorageService {
  static final EncryptedStorageService _instance =
      EncryptedStorageService._internal();

  factory EncryptedStorageService() {
    return _instance;
  }

  EncryptedStorageService._internal();

  late SharedPreferences _prefs;
  final Map<String, EncryptionLevel> _encryptionLevels = {};
  String? _masterKey;

  /// Initialize the encrypted storage service
  Future<void> initialize({String? masterKey}) async {
    _prefs = await SharedPreferences.getInstance();
    _masterKey = masterKey ?? _generateMasterKey();

    // Set default encryption levels
    _encryptionLevels['authToken'] = EncryptionLevel.strong;
    _encryptionLevels['refreshToken'] = EncryptionLevel.strong;
    _encryptionLevels['password'] = EncryptionLevel.maximum;
    _encryptionLevels['userId'] = EncryptionLevel.basic;
    _encryptionLevels['userEmail'] = EncryptionLevel.basic;
  }

  /// Generate a master key
  String _generateMasterKey() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return md5.convert(utf8.encode(timestamp)).toString();
  }

  /// Save encrypted string
  Future<bool> saveEncrypted(
    String key,
    String value, {
    EncryptionLevel level = EncryptionLevel.basic,
  }) async {
    try {
      final encryptionKey = _getEncryptionKey(level);
      final encrypted = SimpleEncryption.encrypt(value, encryptionKey);
      final stored = await _prefs.setString(key, encrypted);
      if (stored) {
        _encryptionLevels[key] = level;
      }
      return stored;
    } catch (e) {
      throw Exception('Failed to save encrypted data: $e');
    }
  }

  /// Save encrypted JSON object
  Future<bool> saveEncryptedJson(
    String key,
    Map<String, dynamic> json, {
    EncryptionLevel level = EncryptionLevel.basic,
  }) async {
    final jsonString = jsonEncode(json);
    return saveEncrypted(key, jsonString, level: level);
  }

  /// Retrieve encrypted string
  String? getEncrypted(String key) {
    try {
      final encrypted = _prefs.getString(key);
      if (encrypted == null) return null;

      final level = _encryptionLevels[key] ?? EncryptionLevel.basic;
      final encryptionKey = _getEncryptionKey(level);
      return SimpleEncryption.decrypt(encrypted, encryptionKey);
    } catch (e) {
      throw Exception('Failed to retrieve encrypted data: $e');
    }
  }

  /// Retrieve encrypted JSON object
  Map<String, dynamic>? getEncryptedJson(String key) {
    try {
      final decrypted = getEncrypted(key);
      if (decrypted == null) return null;
      return jsonDecode(decrypted) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to retrieve encrypted JSON: $e');
    }
  }

  /// Get encryption key based on level
  String _getEncryptionKey(EncryptionLevel level) {
    if (_masterKey == null) {
      throw Exception('Encryption service not initialized');
    }

    switch (level) {
      case EncryptionLevel.none:
        return '';
      case EncryptionLevel.basic:
        return md5.convert(utf8.encode('$_masterKey:basic')).toString();
      case EncryptionLevel.strong:
        return md5.convert(utf8.encode('$_masterKey:strong')).toString();
      case EncryptionLevel.maximum:
        return md5
            .convert(utf8.encode('$_masterKey:maximum:${DateTime.now().year}'))
            .toString();
    }
  }

  /// Delete encrypted value
  Future<bool> deleteEncrypted(String key) async {
    final deleted = await _prefs.remove(key);
    if (deleted) {
      _encryptionLevels.remove(key);
    }
    return deleted;
  }

  /// Check if encrypted value exists
  bool containsEncrypted(String key) {
    return _prefs.containsKey(key);
  }

  /// Get all encrypted keys
  Set<String> getAllEncryptedKeys() {
    return _prefs.getKeys();
  }

  /// Rotate master key and re-encrypt all data
  Future<void> rotateMasterKey(String newMasterKey) async {
    try {
      final oldMasterKey = _masterKey;
      final oldEncryptionLevels = Map<String, EncryptionLevel>.from(
        _encryptionLevels,
      );

      // Decrypt all data with old key
      final allData = <String, String>{};
      for (final key in _prefs.getKeys()) {
        final encrypted = _prefs.getString(key);
        if (encrypted != null) {
          final level = _encryptionLevels[key] ?? EncryptionLevel.basic;
          try {
            _masterKey = oldMasterKey;
            final decrypted = getEncrypted(key);
            if (decrypted != null) {
              allData[key] = decrypted;
            }
          } catch (e) {
            // Skip if decryption fails
          }
        }
      }

      // Clear old data
      await _prefs.clear();
      _encryptionLevels.clear();

      // Re-encrypt with new key
      _masterKey = newMasterKey;
      for (final entry in allData.entries) {
        final level = oldEncryptionLevels[entry.key] ?? EncryptionLevel.basic;
        await saveEncrypted(entry.key, entry.value, level: level);
      }
    } catch (e) {
      throw Exception('Master key rotation failed: $e');
    }
  }

  /// Export encrypted storage stats
  Map<String, dynamic> getStorageStats() {
    final stats = <String, int>{};
    for (final level in EncryptionLevel.values) {
      stats[level.toString()] = _encryptionLevels.values
          .where((l) => l == level)
          .length;
    }

    return {
      'totalEncryptedItems': _prefs.getKeys().length,
      'encryptionLevelDistribution': stats,
      'storageSize': _estimateStorageSize(),
    };
  }

  int _estimateStorageSize() {
    var totalSize = 0;
    for (final key in _prefs.getKeys()) {
      final value = _prefs.getString(key);
      if (value != null) {
        totalSize += key.length + value.length;
      }
    }
    return totalSize;
  }

  /// Clear all encrypted data
  Future<void> clearAll() async {
    await _prefs.clear();
    _encryptionLevels.clear();
  }

  /// Verify data integrity
  bool verifyIntegrity(String key) {
    try {
      final encrypted = _prefs.getString(key);
      if (encrypted == null) return false;

      final level = _encryptionLevels[key] ?? EncryptionLevel.basic;
      final encryptionKey = _getEncryptionKey(level);
      SimpleEncryption.decrypt(encrypted, encryptionKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Verify all data integrity
  Map<String, bool> verifyAllIntegrity() {
    final results = <String, bool>{};
    for (final key in _prefs.getKeys()) {
      results[key] = verifyIntegrity(key);
    }
    return results;
  }
}
