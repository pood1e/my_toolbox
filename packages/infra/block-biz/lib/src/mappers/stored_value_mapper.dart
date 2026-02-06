import '../domain/stored_value.dart';

extension StoredValues on StoredValue {
  static StoredValue boolean({required bool value}) {
    return StoredValue.normal(value: value, storageType: StorageType.bool);
  }

  static StoredValue integer({required int value}) {
    return StoredValue.normal(value: value, storageType: StorageType.int);
  }

  static StoredValue real({required double value}) {
    return StoredValue.normal(value: value, storageType: StorageType.real);
  }

  static StoredValue text({required String value}) {
    return StoredValue.normal(value: value, storageType: StorageType.text);
  }

  static StoredValue json({required String value}) {
    return StoredValue.normal(value: value, storageType: StorageType.json);
  }
}
