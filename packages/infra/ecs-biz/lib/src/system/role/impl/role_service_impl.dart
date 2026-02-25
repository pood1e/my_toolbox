import '../role_service.dart';

class RoleServiceImpl implements RoleService {
  final Map<String, Role> _roleMap;

  RoleServiceImpl({required List<Role> roles})
    : _roleMap = {for (final role in roles) role.id: role};

  @override
  Set<String> analyzeRequiredMetas(Set<String> roleIds) => roleIds
      .expand((roleId) => _roleMap[roleId]!.constraints)
      .where((constraint) => constraint.isMandatory)
      .map((constraint) => constraint.metaId)
      .toSet();

  @override
  List<Role> getAllRoles() => _roleMap.values.toList();

  @override
  List<Role> getSugguestedRoles(Set<String> metas) {
    // TODO: implement getSugguestedRoles
    throw UnimplementedError();
  }

  @override
  Role? getById(String id) => _roleMap[id];
}
