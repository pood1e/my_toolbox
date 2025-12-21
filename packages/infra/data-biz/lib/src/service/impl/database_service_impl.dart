import 'dart:io';

import 'package:auth_biz/auth_biz.dart';
import 'package:core/logger.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart';

import '../data_path_service.dart';
import '../database_service.dart';

class _DatabaseHelper {
  _DatabaseHelper._();

  static const dbDirectory = 'database';

  static QueryExecutor openConnection(String db, String path) {
    return driftDatabase(
      name: db,
      native: DriftNativeOptions(
        databasePath: () async => join(path, dbDirectory),
      ),
    );
  }

  static File dbFile(String db, String path) {
    return File(join(path, dbDirectory, '$db.sqlite'));
  }

  static Future<bool> checkFileExist(File file) async {
    return await file.exists() && await file.length() > 0;
  }

  static Future<void> removeFile(String db, String path) async {
    final file = dbFile(db, path);
    await file.delete();
  }

  static Future<void> removeDirectory(String path) async {
    final dir = Directory(join(path, dbDirectory));
    await dir.delete();
  }
}

class DatabaseServiceImpl implements DatabaseService {
  final DataPathService _pathService;

  DatabaseServiceImpl({required DataPathService pathService})
    : _pathService = pathService;

  @override
  Future<void> migrateFromGuest(
    String db,
    UserIdentity userId,
    DatabaseMigration migration, [
    bool deleteGuest = true,
  ]) async {
    final srcPath = _pathService.guestRoot;
    final dstPath = _pathService.getUserRoot(userId);
    final srcFile = _DatabaseHelper.dbFile(db, srcPath);
    // 原始数据库不存在, 认为迁移成功
    if (!(await _DatabaseHelper.checkFileExist(srcFile))) {
      logger.i('skip migration on db: $db, guest database not exist');
      return;
    }
    final dstFile = _DatabaseHelper.dbFile(db, dstPath);
    // 目标数据库不存在, 直接复制
    if (!(await _DatabaseHelper.checkFileExist(dstFile))) {
      await srcFile.copy(dstFile.path);
      logger.i('copy db($db) from guest successfully');
    } else {
      // 冲突
      final srcDb = _DatabaseHelper.openConnection(db, srcPath);
      final dstDb = _DatabaseHelper.openConnection(db, dstPath);
      await migration.onConflict(srcDb, dstDb);
      await srcDb.close();
      await dstDb.close();
      logger.i('merge db($db) from guest successfully');
    }
    if (deleteGuest) {
      await _DatabaseHelper.removeFile(db, srcPath);
      logger.i('remove guest db($db) successfully');
    }
  }

  @override
  QueryExecutor openGlobalDatabase(String db) {
    return _DatabaseHelper.openConnection(db, _pathService.root);
  }

  @override
  QueryExecutor openGuestDatabase(String db) {
    return _DatabaseHelper.openConnection(db, _pathService.guestRoot);
  }

  @override
  QueryExecutor openUserDatabase(String db, UserIdentity userId) {
    return _DatabaseHelper.openConnection(db, _pathService.getUserRoot(userId));
  }

  @override
  Future<void> clearGuest() =>
      _DatabaseHelper.removeDirectory(_pathService.guestRoot);

  @override
  Future<void> clearUser(UserIdentity userId) =>
      _DatabaseHelper.removeDirectory(_pathService.getUserRoot(userId));
}
