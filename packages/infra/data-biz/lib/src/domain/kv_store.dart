import 'package:mmkv/mmkv.dart';

abstract class KvStore {
  Future<String?> getKey(String key);

  Future<void> saveKey(String key, String value);

  Future<void> clearKey(String key);

  Future<void> clear();

  Future<void> close();
}