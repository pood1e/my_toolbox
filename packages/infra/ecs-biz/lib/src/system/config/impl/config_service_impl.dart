import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import '../../meta/property_meta_service.dart';
import '../../relation/relation_service.dart';
import '../../storage/ecs_database.dart';
import '../../sync/crdt_service.dart';
import '../../value/value_service.dart';
import '../config_service.dart';
import '../data/property_config_dao.dart';
import 'crdt_utils.dart';

class ConfigServiceImpl implements ConfigService {
  final PropertyConfigsDao _dao;
  final PropertyMetaService _metaService;
  final CrdtService _crdtService;
  final ServerTimeService _timeService;
  final ValueService _valueService;
  final RelationService _relationService;

  ConfigServiceImpl({
    required PropertyConfigsDao dao,
    required PropertyMetaService metaService,
    required CrdtService crdtService,
    required ServerTimeService timeService,
    required ValueService valueService,
    required RelationService relationService,
  }) : _dao = dao,
       _metaService = metaService,
       _crdtService = crdtService,
       _timeService = timeService,
       _valueService = valueService,
       _relationService = relationService;

  @override
  Future<void> create(PropertyId propertyId, dynamic config) async {
    final now = _timeService.nowMs;
    final meta = _metaService.getById(propertyId.metaId)!;

    if (meta is! PropertyConfigMeta) {
      return;
    }

    final dbMap = meta.toDb(config);
    final rules = meta.buildUpdateMap(config, null);

    final flattened = ConfigFlattenUtil.flatten(dbMap, rules);

    await _dao.transaction(() async {
      await _dao.insertConfig(
        PropertyConfigsCompanion.insert(
          nodeId: propertyId.nodeId,
          metaId: propertyId.metaId,
          config: dbMap,
          updatedAt: now,
          deletedAt: const Value(null),
          isDirty: const Value(true),
        ),
      );

      await _crdtService.upsert(
        flattened.keys
            .map(
              (key) => CrdtSync(
                propertyId: propertyId,
                syncKey: key,
                updatedAt: now,
              ),
            )
            .toList(),
      );

      if (meta is PropertyRelationMeta) {
        final relations = (meta as PropertyRelationMeta).buildRelations(config);
        await _relationService.create(relations);
      }
      if (meta is PropertyValueMeta) {
        await _valueService.update(
          propertyId,
          const PropertyVal(status: ValueStatus.dirty),
        );
      }
    });
  }

  @override
  Future<void> update(
    PropertyId propertyId,
    dynamic snapshot,
    dynamic config,
  ) async {
    final meta = _metaService.getById(propertyId.metaId)!;

    if (meta is! PropertyConfigMeta) {
      return;
    }
    final rules = meta.buildUpdateMap(config, snapshot);
    final delta = ConfigDiffTool.calculateDelta(
      meta: meta,
      snapshot: snapshot,
      config: config,
      rules: rules,
    );

    if (delta.isEmpty) return;
    final now = _timeService.nowMs;

    await _dao.transaction(() async {
      final dbEntity = await _dao.findByNodeAndMeta(propertyId);
      final dbRawMap = dbEntity?.config ?? <String, dynamic>{};
      final mergedConfig = ConfigDiffTool.mergeDeltaToDbConfig(
        dbRawMap: dbRawMap,
        deltaMap: delta.deltaMap,
        rules: rules,
      );

      await _dao.updateConfig(
        propertyId,
        PropertyConfigsCompanion(
          config: Value(mergedConfig),
          updatedAt: Value(now),
          isDirty: const Value(true),
        ),
      );

      if (delta.keysToSync.isNotEmpty) {
        await _crdtService.upsert(
          delta.keysToSync
              .map(
                (key) => CrdtSync(
                  propertyId: propertyId,
                  syncKey: key,
                  updatedAt: now,
                ),
              )
              .toList(),
        );
      }
      Set<PropertyId> affects = {propertyId};
      if (meta is PropertyRelationMeta) {
        final relations = (meta as PropertyRelationMeta).buildRelations(config);
        await _relationService.replaceById(propertyId, relations);
        final downstream = await _relationService.findAffects([propertyId]);
        affects.addAll(downstream);
      }
      if (meta is PropertyValueMeta) {
        await _valueService.markAsDirty(affects);
      }
    });
  }

  @override
  Future<void> delete(PropertyId id) async {
    final now = _timeService.nowMs;
    final meta = _metaService.getById(id.metaId)!;
    await _dao.transaction(() async {
      await _dao.softDeleteById(id, now);
      await _crdtService.softDelete(id, now);
      if (meta is PropertyRelationMeta) {
        final downstream = await _relationService.findAffects([id]);
        await _valueService.markAsDirty(downstream);
        await _relationService.deleteById(id);
      }
      if (meta is PropertyValueMeta) {
        await _valueService.delete(id);
      }
    });
  }

  @override
  Future<dynamic> get(PropertyId propertyId) async {
    final meta = _metaService.getById(propertyId.metaId)!;
    if (meta is! PropertyConfigMeta) {
      return null;
    }
    final config = await _dao.findByNodeAndMeta(propertyId);
    if (config == null) {
      return null;
    }
    return meta.fromDb(config.config);
  }

  @override
  Stream<dynamic> watch(PropertyId propertyId) async* {
    final meta = _metaService.getById(propertyId.metaId)!;
    if (meta is! PropertyConfigMeta) {
      yield null;
    } else {
      yield* _dao.watchByProperty(propertyId).map((config) {
        if (config == null) {
          return null;
        }
        return meta.fromDb(config.config);
      });
    }
  }

  @override
  Stream<Set<String>> watchMetasByNode(String nodeId) =>
      _dao.watchPropertiesByNode(nodeId);
}
