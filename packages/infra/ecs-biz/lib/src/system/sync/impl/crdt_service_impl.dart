import 'package:drift/drift.dart';

import '../../meta/property_meta_service.dart';
import '../../storage/ecs_database.dart';
import '../crdt_service.dart';
import '../data/crdt_dao.dart';

class CrdtServiceImpl implements CrdtService {
  final CrdtDao _dao;

  CrdtServiceImpl({required CrdtDao dao}) : _dao = dao;

  @override
  Future<void> upsert(List<CrdtSync> crdtSyncs) => _dao.upsertBatch(
    crdtSyncs
        .map(
          (crdt) => PropertyConfigCrdtsCompanion(
            nodeId: Value(crdt.propertyId.nodeId),
            metaId: Value(crdt.propertyId.metaId),
            syncKey: Value(crdt.syncKey),
            updatedAt: Value(crdt.updatedAt),
            deletedAt: Value(crdt.deletedAt),
          ),
        )
        .toList(),
  );

  @override
  Future<void> softDelete(PropertyId id, int deletedAt) =>
      _dao.softDeleteByPropertyId(id, deletedAt);
}
