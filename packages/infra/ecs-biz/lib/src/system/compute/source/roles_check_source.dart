import 'package:app_core/di.dart';

import '../../config/config_service.dart';
import '../../meta/property_meta_service.dart';
import '../../meta/registry/roles_meta.dart';
import '../../role/role_service.dart';
import '../../value/value_service.dart';
import '../impl/compute_node.dart';

part 'roles_check_source.g.dart';

class RolesCheckSource extends Source<RolesConfig, Map<String, bool>> {
  final RoleService _roleService;
  final PropertyMetaService _metaService;
  final ConfigService _configService;
  final ValueService _valueService;

  RolesCheckSource({
    required RoleService roleService,
    required PropertyMetaService metaService,
    required ConfigService configService,
    required ValueService valueService,
  }) : _roleService = roleService,
       _metaService = metaService,
       _configService = configService,
       _valueService = valueService;

  @override
  String get computeId => 'roles_check_source';

  @override
  Future<Map<String, bool>> create(PropertyId self, RolesConfig config) async {
    final roles = config.roleMap.keys
        .map((id) => _roleService.getById(id)!)
        .toList();

    final metaIds = roles
        .expand((role) => role.constraints)
        .where((constraint) => constraint.isMandatory)
        .map((constraint) => constraint.metaId)
        .toSet();
    final metaMap = {
      for (final metaId in metaIds) metaId: _metaService.getById(metaId),
    };

    final propertyConfigExists = await _configService.checkExist(
      metaIds
          .map((metaId) => PropertyId(nodeId: self.nodeId, metaId: metaId))
          .toSet(),
    );
    final metaExists = propertyConfigExists
        .map((propertyIds) => propertyIds.metaId)
        .toSet();

    final filteredValues = await _valueService.filterValueValid(
      metaMap.values
          .whereType<PropertyValueMeta>()
          .map((meta) => PropertyId(nodeId: self.nodeId, metaId: meta.metaId))
          .toSet(),
    );

    final valueValids = filteredValues
        .map((propertyIds) => propertyIds.metaId)
        .toSet();

    return {
      for (var role in roles)
        role.id: role.constraints
            .where((constraint) => constraint.isMandatory)
            .every((constraint) {
              final meta = metaMap[constraint.metaId]!;
              if (meta is PropertyValueMeta &&
                  !valueValids.contains(meta.metaId)) {
                return false;
              }
              return metaExists.contains(meta.metaId);
            }),
    };
  }
}

@riverpod
Future<RolesCheckSource> rolesCheckSource(Ref ref) async {
  final valueService = await ref.watch(valueServiceProvider.future);
  final metaService = ref.watch(propertyMetaServiceProvider);
  final configService = await ref.watch(configServiceProvider.future);
  final roleService = ref.watch(roleServiceProvider);
  return RolesCheckSource(
    roleService: roleService,
    metaService: metaService,
    configService: configService,
    valueService: valueService,
  );
}
