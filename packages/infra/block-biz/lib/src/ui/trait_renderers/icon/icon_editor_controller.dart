import 'package:app_core/di.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../../../data/daos/field_dao.dart';
import '../../../data/node_database.dart';
import 'icon_editor_state.dart';

part 'icon_editor_controller.g.dart';

@riverpod
class IconEditorController extends _$IconEditorController {
  @override
  Stream<IconEditorData> build(String traitId) async* {
    // CQRS
    final dao = await ref.watch(fieldDaoProvider.future);
    final configColumn = dao.fields.config;
    final isValidColumn = dao.fields.isValid;

    final query = dao.selectOnly(dao.fields)
      ..addColumns([configColumn, isValidColumn])
      ..where(dao.fields.traitId.equals(traitId))
      ..limit(1);

    yield* query.watchSingle().map((result) {
      final config = result.readWithConverter<Map<String, dynamic>?, String>(
        configColumn,
      );

      return IconEditorData(
        config: config?.toIconData() ?? Icons.question_mark,
        isValid: result.read(isValidColumn) ?? true,
      );
    });
  }

  /// 选中图标后直接调用此方法保存
  Future<void> updateIcon(IconData icon) async {
    final dao = await ref.read(fieldDaoProvider.future);
    final newConfig = icon.toJson();
    final query = dao.update(dao.fields)
      ..where((t) => t.traitId.equals(traitId));

    await query.write(
      FieldsCompanion(config: Value(newConfig), isValid: Value(true)),
    );
  }
}
