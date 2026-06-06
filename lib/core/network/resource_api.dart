import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ResourceApi {
  static const _storage = FlutterSecureStorage();
  static const _dbKey = 'shido_local_data_v1';
  static const _storageTimeout = Duration(milliseconds: 500);
  static Map<String, List<Map<String, dynamic>>>? _memoryDb;
  static const _knownResources = <String>[
    'users',
    'clubs',
    'players',
    'games',
    'game_teams',
    'payments',
    'reports',
    'notifications',
    'audit_logs',
    'app_settings',
    'tournaments',
  ];

  Future<List<Map<String, dynamic>>> list(
    String resource, {
    int limit = 50,
  }) async {
    final db = await _readDb();
    final items = List<Map<String, dynamic>>.from(
      db[resource] ?? const <Map<String, dynamic>>[],
    );
    if (resource == 'users') {
      final users = items.map(_publicUser).toList();
      if (limit > 0 && users.length > limit) {
        return users.take(limit).toList();
      }
      return users;
    }
    if (limit > 0 && items.length > limit) {
      return items.take(limit).toList();
    }
    return items;
  }

  Future<Map<String, dynamic>> create(
    String resource,
    Map<String, dynamic> payload,
  ) async {
    final db = await _readDb();
    final now = _now();
    final item = <String, dynamic>{
      'id': _uuid(),
      'created_at': now,
      'updated_at': now,
      ...payload,
    };

    if (resource == 'games') {
      item.putIfAbsent('status', () => 'active');
      item.putIfAbsent('started_at', () => now);
    }

    final items = db.putIfAbsent(resource, () => <Map<String, dynamic>>[]);
    items.insert(0, item);
    await _writeDb(db);
    await _audit('create', resource, item['id'].toString());
    return item;
  }

  Future<Map<String, dynamic>> getById(String resource, String id) async {
    final db = await _readDb();
    final item = (db[resource] ?? const <Map<String, dynamic>>[]).where(
      (entry) => (entry['id'] ?? '').toString() == id,
    );
    if (item.isEmpty) {
      throw Exception('$resource record was not found locally.');
    }
    final found = Map<String, dynamic>.from(item.first);
    return resource == 'users' ? _publicUser(found) : found;
  }

  Future<Map<String, dynamic>> update(
    String resource,
    String id,
    Map<String, dynamic> payload,
  ) async {
    final db = await _readDb();
    final items = db[resource] ?? <Map<String, dynamic>>[];
    final index = items.indexWhere(
      (entry) => (entry['id'] ?? '').toString() == id,
    );
    if (index == -1) {
      throw Exception('$resource record was not found locally.');
    }

    final updated = <String, dynamic>{
      ...items[index],
      ...payload,
      'id': id,
      'updated_at': _now(),
    };
    items[index] = updated;
    db[resource] = items;
    await _writeDb(db);
    await _audit('update', resource, id);
    return resource == 'users' ? _publicUser(updated) : updated;
  }

  Future<void> remove(String resource, String id) async {
    final db = await _readDb();
    final items = db[resource] ?? <Map<String, dynamic>>[];
    final before = items.length;
    items.removeWhere((entry) => (entry['id'] ?? '').toString() == id);
    if (items.length == before) {
      throw Exception('$resource record was not found locally.');
    }
    db[resource] = items;

    if (resource == 'games') {
      final teams = db['game_teams'] ?? <Map<String, dynamic>>[];
      teams.removeWhere((entry) => (entry['game_id'] ?? '').toString() == id);
      db['game_teams'] = teams;
    }

    await _writeDb(db);
    await _audit('delete', resource, id);
  }

  Future<Map<String, List<Map<String, dynamic>>>> _readDb() async {
    if (_memoryDb != null) {
      return _cloneDb(_memoryDb!);
    }

    String? raw;
    try {
      raw = await _storage.read(key: _dbKey).timeout(_storageTimeout);
    } on TimeoutException {
      raw = null;
    } catch (_) {
      raw = null;
    }

    if (raw == null || raw.trim().isEmpty) {
      final seeded = _seedDb();
      await _writeDb(seeded);
      return seeded;
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final db = <String, List<Map<String, dynamic>>>{};
    for (final resource in _knownResources) {
      final rows = decoded[resource] as List<dynamic>? ?? <dynamic>[];
      db[resource] = rows
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    }
    _memoryDb = _cloneDb(db);
    return db;
  }

  Future<void> _writeDb(Map<String, List<Map<String, dynamic>>> db) async {
    _memoryDb = _cloneDb(db);
    try {
      await _storage
          .write(key: _dbKey, value: jsonEncode(db))
          .timeout(_storageTimeout);
    } on TimeoutException {
      return;
    } catch (_) {
      return;
    }
  }

  Future<void> _audit(String action, String resource, String resourceId) async {
    final db = await _readDb();
    final logs = db['audit_logs'] ?? <Map<String, dynamic>>[];
    logs.insert(0, {
      'id': _uuid(),
      'action': action,
      'resource': resource,
      'resource_id': resourceId,
      'user_id': 'local',
      'created_at': _now(),
    });
    db['audit_logs'] = logs;
    await _writeDb(db);
  }

  Map<String, List<Map<String, dynamic>>> _seedDb() {
    final now = _now();
    final clubId = _uuid();
    return <String, List<Map<String, dynamic>>>{
      for (final resource in _knownResources)
        resource: <Map<String, dynamic>>[],
      'users': [
        {
          'id': _uuid(),
          'full_name': 'Local User',
          'email': 'local@shido.app',
          'phone': '',
          'role': 'user',
          'is_active': true,
          'created_at': now,
          'updated_at': now,
        },
      ],
      'clubs': [
        {
          'id': clubId,
          'name': 'Shido Local Club',
          'location': 'Local storage',
          'created_at': now,
          'updated_at': now,
        },
      ],
      'notifications': [
        {
          'id': _uuid(),
          'title': 'Local mode enabled',
          'message':
              'App-ka hadda backend uma baahna; xogtu waxay ku jirtaa device-ka.',
          'is_read': false,
          'created_at': now,
        },
      ],
      'app_settings': [
        {
          'id': _uuid(),
          'setting_key': 'storage_mode',
          'setting_value': 'local',
          'description': 'Data is saved on this device without a backend.',
          'created_at': now,
          'updated_at': now,
        },
      ],
      'reports': [
        {
          'id': _uuid(),
          'report_type': 'Local summary',
          'format': 'in-app',
          'created_at': now,
        },
      ],
    };
  }

  Map<String, dynamic> _publicUser(Map<String, dynamic> user) {
    final copy = Map<String, dynamic>.from(user);
    copy.remove('password');
    return copy;
  }

  Map<String, List<Map<String, dynamic>>> _cloneDb(
    Map<String, List<Map<String, dynamic>>> db,
  ) {
    return <String, List<Map<String, dynamic>>>{
      for (final entry in db.entries)
        entry.key: entry.value
            .map((row) => Map<String, dynamic>.from(row))
            .toList(),
    };
  }

  String _now() => DateTime.now().toUtc().toIso8601String();

  String _uuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
