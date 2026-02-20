import 'package:app_core/di.dart';
import 'package:app_core/object.dart';

import '../meta/property_meta_service.dart';
import 'data/crdt_dao.dart';
import 'impl/crdt_service_impl.dart';

part 'crdt_service.freezed.dart';
part 'crdt_service.g.dart';

@freezed
abstract class CrdtSync with _$CrdtSync {
  const factory CrdtSync({
    required PropertyId propertyId,
    required String syncKey,
    required int updatedAt,
    int? deletedAt,
  }) = _CrdtSync;
}

abstract class CrdtService {
  Future<void> upsert(List<CrdtSync> crdtSyncs);

  Future<void> softDelete(PropertyId id, int deletedAt);
}

@riverpod
Future<CrdtService> crdtService(Ref ref) async {
  final dao = await ref.watch(crdtDaoProvider.future);
  return CrdtServiceImpl(dao: dao);
}
