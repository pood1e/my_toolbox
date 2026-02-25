import '../role_service.dart';

class RoleRegistryImpl implements RoleRegistry {
  final Map<String, Role> _roleMap;

  RoleRegistryImpl({required List<Role> roles})
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
  List<Role> getSugguestedRoles(Set<String> metas) => _roleMap.values
      .where(
        (roles) => metas.containsAll(
          roles.constraints.map((constraint) => constraint.metaId).toSet(),
        ),
      )
      .toList();

  @override
  Role? getById(String id) => _roleMap[id];
}
