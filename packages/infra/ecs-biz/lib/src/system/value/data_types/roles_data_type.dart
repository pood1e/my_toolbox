import '../value_service.dart';

class RolesDataType implements DataType<Map<String, bool>> {
  @override
  Map<String, bool>? fromDb(raw) {
    final result = <String, bool>{};
    raw.forEach((key, value) {
      result[key] = value == true;
    });
    return result;
  }

  @override
  String get id => 'roles';

  @override
  toDb(Map<String, bool> value) => value;
}
