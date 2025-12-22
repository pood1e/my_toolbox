import '../domain/app_definition.dart';

abstract class LauncherService {
  Stream<List<AppDefinition>> watchApps();

  Future<List<AppDefinition>> search(String text);

  Future<void> record(String id);
}
