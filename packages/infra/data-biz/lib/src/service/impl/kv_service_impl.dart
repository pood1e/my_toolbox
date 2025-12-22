import 'package:auth_biz/auth_biz.dart';
import 'package:mmkv/mmkv.dart';

import '../../domain/kv_store.dart';
import '../kv_service.dart';

class KvServiceImpl implements KvService {
  @override
  KvStore openGlobalKv() {
    return MMKVStore(MMKV.defaultMMKV());
  }

  @override
  KvStore openGuestKv() {
    return MMKVStore.withId('guest');
  }

  @override
  KvStore openUserKv(UserIdentity userId) {
    return MMKVStore.withId(userId.hash);
  }
}

class MMKVStore implements KvStore {
  final MMKV _box;

  MMKVStore(MMKV box) : _box = box;

  factory MMKVStore.withId(String boxId) {
    return MMKVStore(MMKV(boxId));
  }

  @override
  Future<void> clear() async {
    _box.clearAll();
  }

  @override
  Future<void> clearKey(String key) async {
    _box.removeValue(key);
  }

  @override
  Future<String?> getKey(String key) async {
    return _box.decodeString(key);
  }

  @override
  Future<void> saveKey(String key, String value) async {
    _box.encodeString(key, value);
  }

  @override
  Future<void> close() async {
    _box.close();
  }
}
