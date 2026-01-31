import 'package:app_core/di.dart';

import '../data/daos/field_dao.dart';
import '../data/daos/trait_dao.dart';
import '../data/mappers.dart';
import '../models/models.dart';

part 'trait_repository.g.dart';

@riverpod
Future<TraitRepository> traitRepository(Ref ref) async {
  return TraitRepository(
    await ref.watch(traitDaoProvider.future),
    await ref.watch(fieldDaoProvider.future),
  );
}

class TraitRepository {
  final TraitDao _traitDao;
  final FieldDao _fieldDao;

  TraitRepository(this._traitDao, this._fieldDao);

  /// 监听 Node 的 Traits
  Stream<List<Trait>> watchNodeTraits(String nodeId) {
    return _traitDao
        .watchTraitsByNode(nodeId)
        .map((entities) => entities.map((e) => e.toDomain()).toList());
  }

  /// Node 的 Traits
  Future<List<Trait>> getNodeTraits(String nodeId) async {
    final result = await _traitDao.getTraitsByNode(nodeId);
    return result.map((e) => e.toDomain()).toList();
  }

  /// 核心业务：安装 Trait
  /// 1. 插入 Trait
  /// 2. 根据 Descriptor 创建初始 Fields
  Future<void> installTrait({
    required Trait trait,
    required List<Field> fields,
  }) async {
    await _traitDao.transaction(() async {
      // 1. 插入 Trait
      await _traitDao.insertTrait(trait.toCompanion());

      for (final field in fields) {
        await _fieldDao.insertField(field.toCompanion());
      }
    });
  }

  Future<void> deleteTrait(String id) => _traitDao.deleteTrait(id);
}
