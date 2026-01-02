import 'package:dio/dio.dart';
import 'package:framework_api/framework_api.dart';

import '../dtos/sync_dtos.dart';
import '../lifeflow_database.dart';
import 'sync_entity_controller.dart';

class LifeflowSyncDelegate implements SyncDelegate {
  final Future<void> Function(Future<void> Function(LifeflowDatabase)) _dbUse;
  final Dio _dio;

  final List<SyncEntityController> _controllers;

  LifeflowSyncDelegate({
    required Future<void> Function(Future<void> Function(LifeflowDatabase))
    dbUse,
    required Dio dio,
    required List<SyncEntityController> controllers,
  }) : _dbUse = dbUse,
       _dio = dio,
       _controllers = controllers;

  @override
  String get resourceId => 'lifeflow_reality';

  @override
  Future<void> sync() async {
    await _dbUse((db) async {
      // =================================================================
      // 1. 准备 (Prepare) - 传入 db
      // =================================================================
      await Future.wait(_controllers.map((c) => c.prepare(db)));

      // =================================================================
      // 2. 网络交互 (Dynamic Payload Construction)
      // =================================================================
      final requestBody = {
        'cursors': Map.fromEntries(_controllers.map((c) => c.cursorEntry)),
        'changes': Map.fromEntries(_controllers.map((c) => c.pushJsonEntry)),
      };

      final dioResponse = await _dio.post(
        '/lifeflow/sync/reality',
        data: requestBody,
      );
      final response = SyncResponse.fromJson(dioResponse.data['data']);

      // =================================================================
      // 3. 回写 (Commit) - 传入 db
      // =================================================================
      await db.transaction(() async {
        for (final ctrl in _controllers) {
          await ctrl.handleResponse(db, response);
        }
      });

      // =================================================================
      // 4. GC - 传入 db
      // =================================================================
      await Future.wait(_controllers.map((c) => c.performGc(db)));
    });
  }
}
