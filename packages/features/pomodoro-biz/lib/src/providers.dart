import 'package:app_core/di.dart';
import 'package:framework_api/framework_api.dart';

import 'data/pomodoro_dao.dart';
import 'data/pomodoro_repository.dart';
import 'data/pomodoro_repository_impl.dart';
import 'pomodoro_service.dart';
import 'pomodoro_service_impl.dart';

part 'providers.g.dart';

@riverpod
Future<PomodoroRepository> pomodoroRepository(Ref ref) async {
  final dao = await ref.watch(pomodoroDaoProvider.future);
  final sessionDao = await ref.watch(pomodoroSessionDaoProvider.future);
  return PomodoroRepositoryImpl(pomodoroDao: dao, sessionDao: sessionDao);
}

@riverpod
Future<PomodoroService> pomodoroService(Ref ref) async {
  return PomodoroServiceImpl(
    repo: await ref.watch(pomodoroRepositoryProvider.future),
    serverTimeService: await ref.watch(serverTimeServiceProvider.future),
  );
}
