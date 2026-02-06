import 'package:app_core/object.dart';

part 'stored_value.freezed.dart';

enum StorageType { bool, int, real, text, json }

enum ValueError {
  valueInvalid,
  configInvalid,
  referenceInvalid,
  cycleDependencies,
}

enum ValueStatus { normal, dirty, error }

@freezed
sealed class StoredValue with _$StoredValue {
  const factory StoredValue.normal({
    required dynamic value,
    required StorageType storageType,
  }) = NormalStoredValue;

  const factory StoredValue.dirty({
    dynamic value,
    required StorageType storageType,
  }) = DirtyStoredValue;

  const factory StoredValue.error({required ValueError error}) =
      ErrorStoredValue;
}
