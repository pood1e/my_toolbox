import '../../domain/data_type.dart';
import '../../domain/stored_value.dart';

class RoleDataType implements DataTypeDefinition<String> {
  @override
  String get id => 'role';

  @override
  StorageType get storageType => StorageType.json;

  @override
  String? fromDb(value) => value;

  @override
  toDb(String value) => value;
}
