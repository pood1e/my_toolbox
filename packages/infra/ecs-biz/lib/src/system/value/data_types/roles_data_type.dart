import 'package:app_core/object.dart';

import '../value_service.dart';

part 'roles_data_type.freezed.dart';
part 'roles_data_type.g.dart';

@freezed
abstract class RolesStatus with _$RolesStatus {
  const factory RolesStatus({required List<RoleStatus> status}) = _RolesStatus;

  factory RolesStatus.fromJson(Map<String, dynamic> json) =>
      _$RolesStatusFromJson(json);
}

@freezed
abstract class RoleStatus with _$RoleStatus {
  const factory RoleStatus({
    required String roleId,
    required bool success,
    @Default([]) List<String> reasons,
  }) = _RoleStatus;

  factory RoleStatus.fromJson(Map<String, dynamic> json) =>
      _$RoleStatusFromJson(json);
}

class RolesDataType implements DataType<RolesStatus> {
  @override
  String get id => 'roles';

  @override
  RolesStatus? fromDb(value) => RolesStatus.fromJson(value);

  @override
  toDb(RolesStatus value) => value.toJson();
}
