import 'package:data_api/data_api.dart';
import 'package:mmkv/mmkv.dart';

class MMKVStore implements KVStore {
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
  Future<void> close() async {
    _box.close();
  }

  @override
  Future<int> getInt(String key, {int defaultValue = 0}) async {
    return _box.decodeInt(key, defaultValue: defaultValue);
  }

  @override
  Future<String?> getString(String key) async {
    return _box.decodeString(key);
  }

  @override
  Future<void> saveInt(String key, int value) async {
    _box.encodeInt(key, value);
  }

  @override
  Future<void> saveString(String key, String value) async {
    _box.encodeString(key, value);
  }

  @override
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    return _box.decodeBool(key, defaultValue: defaultValue);
  }

  @override
  Future<void> saveBool(String key, bool value) async {
    _box.encodeBool(key, value);
  }
}
