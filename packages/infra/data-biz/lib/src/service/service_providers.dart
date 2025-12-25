import 'package:app_core/di.dart';
import 'package:auth_api/auth_api.dart';
import 'package:data_api/data_api.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/scope_type.dart';
import 'data_scope_service.dart';
import 'impl/data_scope_service_impl.dart';

part 'service_providers.g.dart';

@Riverpod(keepAlive: true)
Future<DataScopeService> dataScopeService(Ref ref) async {
  final storageDirectory = await getApplicationDocumentsDirectory();
  return DataScopeServiceImpl(root: join(storageDirectory.path, 'my-toolbox'));
}

@Riverpod(keepAlive: true)
Future<DataScope> globalDataScope(Ref ref) async {
  final manager = await ref.watch(dataScopeServiceProvider.future);
  return manager.get(GlobalScope().id);
}

@Riverpod(keepAlive: true)
Future<DataScope> currentUserDataScope(Ref ref) async {
  final manager = await ref.watch(dataScopeServiceProvider.future);
  // 监听用户身份变化，自动切换 Scope
  final userId = await ref.watch(currentUserIdentityProvider.future);
  final scopeId = userId == null ? GuestScope() : UserScope(identity: userId);
  return manager.get(scopeId.id);
}
