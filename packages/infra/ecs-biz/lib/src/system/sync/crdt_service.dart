import 'package:app_core/object.dart';

import '../meta/property_meta_service.dart';

part 'crdt_service.freezed.dart';

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

/// crdt sync
abstract class CrdtSyncService {
  /// diff
}
