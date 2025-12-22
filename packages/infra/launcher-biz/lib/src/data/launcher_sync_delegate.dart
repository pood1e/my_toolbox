import 'package:sync_api/sync_api.dart';

import 'launcher_dao.dart';
import 'launcher_dto.dart';
import 'launcher_mapper.dart';

class LauncherSyncDelegate extends StandardSyncDelegate<LauncherSyncPayload> {
  final Future<LauncherDao> Function() _daoGetter;

  LauncherSyncDelegate({
    required super.dio,
    required Future<LauncherDao> Function() daoGetter,
  }) : _daoGetter = daoGetter,
       super(
         apiPath: '/settings/launcher',
         toJson: (t) => t.toJson(),
         fromJson: LauncherSyncPayload.fromJson,
       );

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
