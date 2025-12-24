import 'package:app_core/core.dart';

abstract class LauncherService {
  Stream<List<AppDefinition>> watchApps();

  Future<List<AppDefinition>> search(String text);

  Future<void> record(String id);
}
