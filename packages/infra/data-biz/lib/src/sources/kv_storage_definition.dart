import 'dart:async';

import 'package:mmkv/mmkv.dart';

import '../domain/storage_definition.dart';
import '../domain/kv_store.dart';
import '../domain/mmkv_store.dart';

class KvStorageDefinition implements StorageDefinition<KVStore> {
  final String _instance;

  KvStorageDefinition({required String instance}) : _instance = instance;

  @override
  Future<KVStore> create(String path) async {
    final mmkv = MMKV(key, rootDir: path);
    return MMKVStore(mmkv);
  }

  @override
  Future<void> dispose(KVStore instance) async {
    instance.close();
  }

  @override
  String get key => 'kv_$_instance';
}
