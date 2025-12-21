import 'package:mmkv/mmkv.dart';

abstract class KvStore {
  Future<String?> getKey(String key);

  Future<void> saveKey(String key, String value);

  Future<void> clearKey(String key);

  Future<void> clear();
}

class MMKVStore implements KvStore {
  final MMKV _box;

  MMKVStore({required String boxId}) : _box = MMKV(boxId);

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
}
