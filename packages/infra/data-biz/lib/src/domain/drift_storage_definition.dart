import 'dart:async';

import 'package:data_api/data_api.dart';
import 'package:drift_flutter/drift_flutter.dart';

class DriftStorageDefinition<T extends GeneratedDatabase>
    implements StorageDefinition<T> {
  final String _instance;
  final DatabaseFactory<T> _factory;

  DriftStorageDefinition({
    required String instance,
    required DatabaseFactory<T> factory,
  }) : _instance = instance,
       _factory = factory;

  @override
  Future<T> create(String path) async {
    final executor = driftDatabase(
      name: key,
      native: DriftNativeOptions(databaseDirectory: () async => path),
    );
    return _factory(executor);
  }

  @override
  Future<void> dispose(T instance) async {
    instance.close();
  }

  @override
  String get key => 'db_$_instance';
}
