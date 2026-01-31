import 'package:app_core/di.dart';
import 'package:drift/drift.dart';

import '../../../data/daos/field_dao.dart';
import '../../../data/node_database.dart';
import 'name_editor_state.dart';

part 'name_editor_controller.g.dart';

@riverpod
class NameEditorModeController extends _$NameEditorModeController {
  @override
  bool build(String traitId) => false;

  void enterEdit() {
    state = true;
  }

  void exitEdit() {
    state = false;
  }
}

@riverpod
Stream<NameReadData> nameReadData(Ref ref, String traitId) async* {
  // CQRS
  final dao = await ref.watch(fieldDaoProvider.future);
  final dataColumn = dao.fields.data;
  final isValidColumn = dao.fields.isValid;
  final query = dao.selectOnly(dao.fields)
    ..addColumns([dataColumn, isValidColumn])
    ..where(dao.fields.traitId.equals(traitId))
    ..limit(1);

  yield* query.watchSingle().map((result) {
    return NameReadData(
      data: result.read(dataColumn),
      isValid: result.read(isValidColumn)!,
    );
  });
}

@riverpod
class NameEditController extends _$NameEditController {
  @override
  Stream<NameEditData> build(String traitId) async* {
    // CQRS
    final dao = await ref.watch(fieldDaoProvider.future);
    final dataColumn = dao.fields.data;
    final configColumn = dao.fields.config;

    final query = dao.selectOnly(dao.fields)
      ..addColumns([dataColumn, configColumn])
      ..where(dao.fields.traitId.equals(traitId))
      ..limit(1);
    yield* query.watchSingle().map((result) {
      return NameEditData(
        data: result.read(dataColumn),
        config: result.readWithConverter<Map<String, dynamic>?, String>(
          configColumn,
        )!,
      );
    });
  }

  Future<void> updateConifgData(String data) async {
    // CQRS
    final dao = await ref.read(fieldDaoProvider.future);
    final query = dao.update(dao.fields)
      ..where((t) => t.traitId.equals(traitId));
    await query.write(
      FieldsCompanion(config: Value({'data': data}), data: Value(data)),
    );
  }
}
