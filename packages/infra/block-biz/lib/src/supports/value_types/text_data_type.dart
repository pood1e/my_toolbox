import '../../domain/data_type.dart';
import '../../domain/stored_value.dart';

class TextDataType implements DataTypeDefinition<String> {
  @override
  String? fromDb(value) => value;

  @override
  String get id => 'text';

  @override
  StorageType get storageType => StorageType.text;

  @override
  toDb(String value) => value;
}
