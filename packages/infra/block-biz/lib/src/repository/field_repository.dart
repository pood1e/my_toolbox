import 'package:app_core/di.dart';

import '../data/daos/field_dao.dart';
import '../data/mappers.dart';
import '../models/models.dart';

part 'field_repository.g.dart';

/// todo: 重新审视生命周期
@riverpod
Future<FieldRepository> fieldRepository(Ref ref) async {
  return FieldRepository(await ref.watch(fieldDaoProvider.future));
}

class FieldRepository {
  final FieldDao _dao;

  FieldRepository(this._dao);

  // 获取某个 Trait 下的字段列表
  Future<List<Field>> getTraitFields(String traitId) async {
    final entities = await _dao.getFieldsByTrait(traitId);
    return entities.map((e) => e.toDomain()).toList();
  }

  Stream<List<Field>> watchTraitFields(String traitId) {
    return _dao
        .watchFieldsByTrait(traitId)
        .map((list) => list.map((e) => e.toDomain()).toList());
  }

  // 更新字段值 (用户输入)
  Future<void> updateValue(String fieldId, dynamic newValue) async {
    // 简单包装为 Map
    await _dao.updateFieldData(fieldId, newValue);
  }

  // 更新字段配置
  Future<void> updateConfig(
    String fieldId,
    Map<String, dynamic> newConfig,
  ) async {
    await _dao.updateFieldConfig(fieldId, newConfig);
  }
}
