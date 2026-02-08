import 'package:app_core/object.dart';

part 'property_editor_state.freezed.dart';

@freezed
abstract class PropertyEditorState<T> with _$PropertyEditorState<T> {
  const PropertyEditorState._();

  const factory PropertyEditorState({
    /// [草稿] 用户当前编辑的值
    required T current,

    /// [远程基准] 从 Repo 同步的最新值
    required T remote,

    /// [过时/冲突] 当 remote 更新时，若用户有未保存的修改 (isDirty)，此项为 true
    @Default(false) bool isStale,

    /// 是否正在保存
    @Default(false) bool isSaving,

    /// 校验错误信息 (null 表示通过)
    String? validationError,
  }) = _PropertyEditorState<T>;

  /// 是否有未保存的修改
  bool get isDirty => current != remote;

  /// 校验是否通过
  bool get isValid => validationError == null;

  /// 是否可以保存 (有修改、已通过校验、且不在保存中)
  bool get canSave => isDirty && isValid && !isSaving;
}
