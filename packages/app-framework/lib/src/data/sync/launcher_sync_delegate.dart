import 'package:flutter/foundation.dart';
import 'package:framework_api/framework_api.dart';

import '../launcher/launcher_dao.dart';
import '../launcher/launcher_dto.dart';
import '../launcher/launcher_mapper.dart';

class LauncherSyncDelegate extends SyncStandardDelegate<LauncherSyncPayload> {
  final LauncherDao _dao;

  LauncherSyncDelegate({required super.api, required LauncherDao dao})
    : _dao = dao;

  @override
  String get resourceId => 'launcher';

  @override
  bool isEmpty(LauncherSyncPayload payload) => payload.usages.isEmpty;

  @override
  Future<LauncherSyncPayload?> load(int? cursor) async {
    final dirtyRows = await _dao.getDirtyEntries(cursor);

    if (dirtyRows.isEmpty) return null;
    return LauncherSyncPayload(
      usages: dirtyRows.map((e) => e.toDto()).toList(),
    );
  }

  @override
  Future<void> merge(LauncherSyncPayload changes) async {
    await _dao.mergeEntries(changes.usages.map((d) => d.toEntity()).toList());
  }

  @override
  bool needMerge(LauncherSyncPayload pulled, LauncherSyncPayload pushed) {
    return listEquals(pulled.usages, pushed.usages);
  }
}
