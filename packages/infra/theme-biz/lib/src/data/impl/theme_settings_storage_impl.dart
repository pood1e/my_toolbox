import 'package:flutter/material.dart';
import 'package:framework_api/framework_api.dart';

import '../../domain/theme_settings.dart';
import '../theme_settings_storage.dart';

class ThemeSettingsStorageImpl implements ThemeSettingsStorage {
  final KVStore _store;

  ThemeSettingsStorageImpl({required KVStore store}) : _store = store;

  @override
  Future<ThemeSettings> load() async {
    final mode = await _store.getInt('mode', defaultValue: 0);
    final follow = await _store.getBool('follow', defaultValue: true);
    final seed = await _store.getInt('seed', defaultValue: 0xFF6750A4);
    return ThemeSettings(
      themeMode: ThemeMode.values[mode],
      followSystemColor: follow,
      seedColorValue: seed,
    );
  }

  @override
  Future<void> save(ThemeSettings newSettings) async {
    await _store.saveInt('mode', newSettings.themeMode.index);
    await _store.saveBool('follow', newSettings.followSystemColor);
    await _store.saveInt('seed', newSettings.seedColorValue);
  }
}
