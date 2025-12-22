import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:mmkv/mmkv.dart';

import '../domain/kv_store.dart';
import '../domain/mmkv_store.dart';
import 'data_scope.dart';

class DataScopeImpl implements DataScope {
  @override
  final String id;
  @override
  final String rootPath;

  // [修改点 1]: 缓存所有活跃的 KV 实例
  // Key: KV 的名称 (如 'settings'), Value: 实例
  final Map<String, KVStore> _activeKvs = {};

  // DB 实例缓存
  GeneratedDatabase? _db;

  DataScopeImpl({required this.id, required this.rootPath});

  @override
  KVStore getKv(String name) {
    if (_activeKvs.containsKey(name)) {
      return _activeKvs[name]!;
    }
    final mmkv = MMKV(name, rootDir: rootPath);
    final store = MMKVStore(mmkv);
    _activeKvs[name] = store;
    return store;
  }

  @override
  T getDatabase<T extends GeneratedDatabase>(
    T Function(QueryExecutor e) factory,
  ) {
    // 如果已经有缓存，直接返回
    if (_db != null) {
      if (_db is T) {
        return _db as T;
      } else {
        throw StateError(
          'Scope $id already holds a database of type ${_db.runtimeType}, but requested $T',
        );
      }
    }

    final executor = driftDatabase(
      name: 'app',
      native: DriftNativeOptions(
        databasePath: () async => rootPath,
        isolateDebugLog: true,
      ),
    );

    // 通过工厂创建具体的 Database 类 (如 AppDatabase)
    final instance = factory(executor);
    _db = instance;
    return instance;
  }

  @override
  Future<void> close() async {
    // [修改点 3]: 遍历关闭所有 KV
    // 并行关闭以提高效率
    await Future.wait(_activeKvs.values.map((kv) => kv.close()));
    _activeKvs.clear();

    // 关闭数据库
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  @override
  Future<void> delete() async {
    // 1. 关闭资源 (释放文件锁)
    await close();

    // 2. 物理删除
    final dir = Directory(rootPath);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
