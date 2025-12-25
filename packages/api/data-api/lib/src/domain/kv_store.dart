abstract class KVStore {
  Future<String?> getString(String key);

  Future<void> saveString(String key, String value);

  Future<bool> getBool(String key, {bool defaultValue = false});

  Future<void> saveBool(String key, bool value);

  Future<int> getInt(String key, {int defaultValue = 0});

  Future<void> saveInt(String key, int value);

  Future<void> clearKey(String key);

  Future<void> clear();

  Future<void> close();
}
