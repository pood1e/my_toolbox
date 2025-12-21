import 'package:core/di.dart';
import 'package:path_provider/path_provider.dart';

import 'data_path_service.dart';
import 'database_service.dart';
import 'impl/data_path_service_impl.dart';
import 'impl/database_service_impl.dart';

part 'service_providers.g.dart';

@Riverpod(keepAlive: true)
Future<DataPathService> dataPathService(Ref ref) async {
  final storageDirectory = await getApplicationDocumentsDirectory();
  return DataPathServiceImpl(storagePath: storageDirectory.path);
}

@Riverpod(keepAlive: true)
Future<DatabaseService> databaseService(Ref ref) async {
  final pathService = await ref.read(dataPathServiceProvider.future);
  return DatabaseServiceImpl(pathService: pathService);
}
