import 'package:data_api/data_api.dart';

import '../server_time_storage.dart';

class ServerTimeStorageImpl implements ServerTimeStorage {
  final KVStore _store;
  static const _anchorKey = 'anchor';
  static const _bootIdKey = 'boot_id';

  ServerTimeStorageImpl({required KVStore store}) : _store = store;

  @override
  Future<int> getAnchor() async {
    return await _store.getInt(_anchorKey, defaultValue: 0);
  }

  @override
  Future<String?> getBootId() async {
    return await _store.getString(_bootIdKey);
  }

  @override
  Future<void> saveAnchor(int anchor) async {
    await _store.saveInt(_anchorKey, anchor);
  }

  @override
  Future<void> saveBootId(String bootId) async {
    await _store.saveString(_bootIdKey, bootId);
  }
}
