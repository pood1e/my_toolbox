import 'package:sync_api/sync_api.dart';

import '../launcher/launcher_dao.dart';
import '../launcher/launcher_dto.dart';
import '../launcher/launcher_mapper.dart';

class LauncherSyncDelegate extends SyncStandardDelegate<LauncherSyncPayload> {
  final Future<LauncherDao> Function() _daoGetter;

  LauncherSyncDelegate({
    required super.api,
    required Future<LauncherDao> Function() daoGetter,
  }) : _daoGetter = daoGetter;

  @override
  String get resourceId => 'launcher';

  @override
  bool isEmpty(LauncherSyncPayload payload) => payload.usages.isEmpty;

  @override
  Future<LauncherSyncPayload?> load(int? cursor) async {
    final dao = await _daoGetter();
    final dirtyRows = await dao.getDirtyEntries(cursor);

    if (dirtyRows.isEmpty) return null;
    return LauncherSyncPayload(
      usages: dirtyRows.map((e) => e.toDto()).toList(),
    );
  }

  @override
  Future<void> merge(LauncherSyncPayload changes) async {
    final dao = await _daoGetter();
    await dao.mergeEntries(changes.usages.map((d) => d.toEntity()).toList());
  }
}
