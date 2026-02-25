import 'package:app_core/di.dart';

import '../../config/config_service.dart';
import '../../meta/property_meta_service.dart';
import '../../meta/registry/roles_meta.dart';
import '../../role/role_service.dart';
import '../../ui/property_common_ui.dart';
import '../../value/data_types/roles_data_type.dart';
import '../../value/value_service.dart';
import '../impl/compute_node.dart';

part 'roles_check_source.g.dart';

class RolesCheckSource extends Source<RolesConfig, RolesStatus> {
  final RoleRegistry _roleRegistry;
  final PropertyMetaService _metaService;
  final ConfigService _configService;
  final ValueService _valueService;

  RolesCheckSource({
    required RoleRegistry roleRegistry,
    required PropertyMetaService metaService,
    required ConfigService configService,
    required ValueService valueService,
  }) : _roleRegistry = roleRegistry,
       _metaService = metaService,
       _configService = configService,
       _valueService = valueService;

  @override
  String get computeId => 'roles_check_source';

  @override
  Future<RolesStatus> create(PropertyId self, RolesConfig config) async {
    final roles = config.roleMap.keys
        .map((id) => _roleRegistry.getById(id)!)
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

    return RolesStatus(
      status: roles.map((role) {
        final errors = <String>[];
        role.constraints.where((constraint) => constraint.isMandatory).forEach((
          constraint,
        ) {
          final meta = metaMap[constraint.metaId]!;
          final metaName = meta is PropertyUiMeta ? meta.name : meta.metaId;
          if (!metaExists.contains(meta.metaId)) {
            errors.add('缺少 $metaName');
          }
          if (meta is PropertyValueMeta && !valueValids.contains(meta.metaId)) {
            errors.add('$metaName 值异常');
          }
        });
        return RoleStatus(
          roleId: role.id,
          success: errors.isEmpty,
          reasons: errors,
        );
      }).toList(),
    );
  }
}

@riverpod
Future<RolesCheckSource> rolesCheckSource(Ref ref) async {
  final valueService = await ref.watch(valueServiceProvider.future);
  final metaService = ref.watch(propertyMetaServiceProvider);
  final configService = await ref.watch(configServiceProvider.future);
  final roleRegistry = ref.watch(roleRegistryProvider);
  return RolesCheckSource(
    roleRegistry: roleRegistry,
    metaService: metaService,
    configService: configService,
    valueService: valueService,
  );
}
