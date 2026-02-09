import 'package:app_core/object.dart';

import '../../../domain/property_config.dart';
import '../../../domain/stored_config.dart';

part 'property_editor_state.freezed.dart';

@freezed
abstract class PropertyEditorState with _$PropertyEditorState {
  const factory PropertyEditorState({
    required PropertyConfig remote, // 基准值
    required PropertyConfig draft,  // 编辑值
    @Default(false) bool isSaving,
    String? error,
  }) = _PropertyEditorState;

  const PropertyEditorState._();

  /// 是否有变更
  bool get isDirty => remote != draft;

  /// 当前处于什么模式
  SourceMode get activeMode => draft.map(
      singleStatic: (_) => SourceMode.singleStatic,
      singleRef: (_) => SourceMode.singleRef,
      multiStatic: (_) => SourceMode.multiStatic,
      multiRef: (_) => SourceMode.multiRef,
      hybrid: (_) => SourceMode.hybrid,
    );
}