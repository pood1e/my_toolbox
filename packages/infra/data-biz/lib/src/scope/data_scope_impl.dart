import 'dart:io';

import 'package:app_core/logger.dart';
import 'package:data_api/data_api.dart';

class DataScopeImpl implements DataScope {
  final String _scopePath;

  final Map<String, _ActiveResource> _resources = {};

  DataScopeImpl({required String scopePath}) : _scopePath = scopePath;

  @override
  Future<T> get<T>(StorageDefinition<T> source) async {
    final key = source.key;
    if (_resources.containsKey(key)) {
      return _resources[key]!.instance as T;
    }
    final instance = await source.create(_scopePath);
    logger.i('data resource $_scopePath:$key created.');

    _resources[key] = _ActiveResource(source, instance);
    return instance;
  }

  @override
  Future<void> close() async {
    // 并行销毁所有资源
    await Future.wait(
      _resources.values.map((resource) async {
        try {
          await resource.definition.dispose(resource.instance);
          logger.i(
            'data resource $_scopePath:${resource.definition.key} disposed.',
          );
        } catch (e) {
          logger.e('Error disposing resource ${resource.definition.key}: $e');
        }
      }),
    );
    _resources.clear();
  }

  @override
  Future<void> delete() async {
    await close();
    final dir = Directory(_scopePath);
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  @override
  Future<void> dispose(StorageDefinition<dynamic> source) async {
    final key = source.key;

    if (_resources.containsKey(key)) {
      final resource = _resources[key]!;
      try {
        await source.dispose(resource.instance);
        logger.i('data resource $_scopePath:$key disposed.');
      } catch (e) {
        logger.e('Error disposing resource $key: $e');
      }
      _resources.remove(key);
    }
  }
}

class _ActiveResource {
  final StorageDefinition definition;
  final dynamic instance;

  _ActiveResource(this.definition, this.instance);
}
