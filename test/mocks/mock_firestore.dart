import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';

/// Mock Firestore implementation for testing without Firebase
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {
  final Map<String, Map<String, dynamic>> _store = {};

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return MockCollectionReference(this, collectionPath);
  }

  void setDocument(String collection, String docId, Map<String, dynamic> data) {
    if (!_store.containsKey(collection)) {
      _store[collection] = {};
    }
    _store[collection]![docId] = data;
  }

  Map<String, dynamic>? getDocument(String collection, String docId) {
    return _store[collection]?[docId];
  }

  List<Map<String, dynamic>> getCollection(String collection) {
    return _store[collection]?.values.toList() ?? [];
  }

  void deleteDocument(String collection, String docId) {
    _store[collection]?.remove(docId);
  }

  void clear() {
    _store.clear();
  }
}

/// Mock CollectionReference for testing
class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {
  final MockFirebaseFirestore _firestore;
  final String _collectionPath;

  MockCollectionReference(this._firestore, this._collectionPath);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return MockDocumentReference(_firestore, _collectionPath, path ?? 'doc');
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get() async {
    final docs = _firestore.getCollection(_collectionPath);
    return MockQuerySnapshot(docs);
  }

  @override
  Query<Map<String, dynamic>> where(
    Object fieldPath, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    List<Object?>? arrayContainsAny,
    List<Object?>? whereIn,
    bool? isNull,
  }) {
    return MockQuery(_firestore, _collectionPath, fieldPath as String, isEqualTo);
  }

  @override
  Query<Map<String, dynamic>> orderBy(
    Object fieldPath, {
    bool descending = false,
  }) {
    return MockQuery(_firestore, _collectionPath, null, null);
  }

  @override
  Query<Map<String, dynamic>> limit(int limit) {
    return MockQuery(_firestore, _collectionPath, null, null);
  }
}

/// Mock DocumentReference for testing
class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {
  final MockFirebaseFirestore _firestore;
  final String _collectionPath;
  final String _docPath;

  MockDocumentReference(this._firestore, this._collectionPath, this._docPath);

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    _firestore.setDocument(_collectionPath, _docPath, data);
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get() async {
    final data = _firestore.getDocument(_collectionPath, _docPath);
    return MockDocumentSnapshot(_docPath, data);
  }

  @override
  Future<void> update(Map<String, dynamic> data) async {
    final existing = _firestore.getDocument(_collectionPath, _docPath) ?? {};
    existing.addAll(data);
    _firestore.setDocument(_collectionPath, _docPath, existing);
  }

  @override
  Future<void> delete() async {
    _firestore.deleteDocument(_collectionPath, _docPath);
  }
}

/// Mock QuerySnapshot for testing
class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {
  final List<Map<String, dynamic>> _docs;

  MockQuerySnapshot(this._docs);

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs {
    return _docs
        .asMap()
        .entries
        .map((e) => MockQueryDocumentSnapshot('doc_${e.key}', e.value))
        .toList();
  }

  @override
  int get size => _docs.length;
}

/// Mock QueryDocumentSnapshot for testing
class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  final String _id;
  final Map<String, dynamic> _data;

  MockQueryDocumentSnapshot(this._id, this._data);

  @override
  String get id => _id;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  Map<String, dynamic> get metadata {
    return {
      'hasPendingWrites': false,
      'isFromCache': false,
    };
  }
}

/// Mock DocumentSnapshot for testing
class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {
  final String _id;
  final Map<String, dynamic>? _data;

  MockDocumentSnapshot(this._id, this._data);

  @override
  String get id => _id;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  bool get exists => _data != null;

  @override
  Map<String, dynamic> get metadata {
    return {
      'hasPendingWrites': false,
      'isFromCache': false,
    };
  }
}

/// Mock Query for testing
class MockQuery extends Mock implements Query<Map<String, dynamic>> {
  final MockFirebaseFirestore _firestore;
  final String _collectionPath;
  final String? _whereField;
  final Object? _whereValue;

  MockQuery(this._firestore, this._collectionPath, this._whereField, this._whereValue);

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get() async {
    var allDocs = _firestore.getCollection(_collectionPath);

    // Apply where filter if specified
    if (_whereField != null && _whereValue != null) {
      allDocs = allDocs.where((doc) {
        return doc[_whereField] == _whereValue;
      }).toList();
    }

    return MockQuerySnapshot(allDocs);
  }

  @override
  Query<Map<String, dynamic>> where(
    Object fieldPath, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    List<Object?>? arrayContainsAny,
    List<Object?>? whereIn,
    bool? isNull,
  }) {
    return MockQuery(
      _firestore,
      _collectionPath,
      fieldPath as String,
      isEqualTo,
    );
  }

  @override
  Query<Map<String, dynamic>> orderBy(
    Object fieldPath, {
    bool descending = false,
  }) {
    return this;
  }

  @override
  Query<Map<String, dynamic>> limit(int limit) {
    return this;
  }
}

/// Mock for Timestamp conversion
class MockTimestamp extends Mock implements Timestamp {
  final DateTime _dateTime;

  MockTimestamp(this._dateTime);

  @override
  DateTime toDate() => _dateTime;

  static MockTimestamp fromDate(DateTime dateTime) {
    return MockTimestamp(dateTime);
  }
}

/// FieldValue mock for increment operations
class MockFieldValue extends Mock {
  static MockFieldValue increment(num value) {
    return MockFieldValue();
  }
}
