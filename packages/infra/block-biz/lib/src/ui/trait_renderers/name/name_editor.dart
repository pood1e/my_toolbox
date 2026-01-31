import 'package:app_core/di.dart';
import 'package:common_ui/component.dart';
import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import 'name_editor_controller.dart';

class NameEditor extends ConsumerWidget {
  final String _traitId;

  const NameEditor({super.key, required String traitId}) : _traitId = traitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听模式切换
    final isEditMode = ref.watch(nameEditorModeControllerProvider(_traitId));

    return Card(
      // 使用 AnimatedSwitcher 增加切换动效（可选，提升体验）
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isEditMode
            ? _NameEditPanel(traitId: _traitId)
            : _NameReadPanel(traitId: _traitId),
      ),
    );
  }
}

class _NameReadPanel extends ConsumerWidget {
  final String _traitId;

  const _NameReadPanel({required String traitId}) : _traitId = traitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readDataAsync = ref.watch(nameReadDataProvider(_traitId));
    final statusColors = context.theme.extension<AppStatusColors>()!;

    return readDataAsync.whenUI(
      data: (data) {
        final isValid = data.isValid;
        final content = data.data ?? 'null';

        return ListTile(
          key: const ValueKey('ReadPanel'), // 帮助 AnimatedSwitcher 识别
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Symbols.id_card,
              color: isValid ? statusColors.success : statusColors.warning,
            ),
          ),
          title: Text(content),
          trailing: IconButton(
            onPressed: () {
              // 使用 read 避免不必要的 rebuild
              ref
                  .read(nameEditorModeControllerProvider(_traitId).notifier)
                  .enterEdit();
            },
            icon: const Icon(Icons.edit),
          ),
        );
      },
    );
  }
}

// 容器层：负责获取数据，处理 AsyncValue
class _NameEditPanel extends ConsumerWidget {
  final String traitId;

  const _NameEditPanel({required this.traitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerAsync = ref.watch(nameEditControllerProvider(traitId));

    return controllerAsync.whenUI(
      data: (data) {
        // 只有拿到数据后，才构建真实的表单 Widget
        // 这样做的好处是 _NameInputForm 的 initState 必定能拿到 valid 的初始值
        return _NameInputForm(
          key: const ValueKey('EditPanel'),
          initialValue: data.config['data'] ?? '',
          traitId: traitId,
        );
      },
    );
  }
}

// 表单层：负责 Controller 生命周期和交互逻辑
class _NameInputForm extends ConsumerStatefulWidget {
  final String traitId;
  final String initialValue;

  const _NameInputForm({
    super.key,
    required this.traitId,
    required this.initialValue,
  });

  @override
  ConsumerState<_NameInputForm> createState() => _NameInputFormState();
}

class _NameInputFormState extends ConsumerState<_NameInputForm> {
  late final TextEditingController _controller;

  // 用于控制保存按钮的激活状态
  late bool _canSave;

  @override
  void initState() {
    super.initState();
    // 1. 初始化 Controller
    _controller = TextEditingController(text: widget.initialValue);
    _canSave = false;

    // 2. 监听变化，优化性能（避免每次输入都 setState 整个组件，虽然这里简单写 setState 也没事）
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    // 3. 必须销毁！防止内存泄漏
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    final isChanged = text.isNotEmpty && text != widget.initialValue;

    // 只有状态改变时才刷新 UI，减少 rebuild
    if (_canSave != isChanged) {
      setState(() {
        _canSave = isChanged;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_canSave) return;

    // 失去焦点，收起键盘
    FocusScope.of(context).unfocus();

    await ref
        .read(nameEditControllerProvider(widget.traitId).notifier)
        .updateConifgData(_controller.text);

    // 检查组件是否还挂载，避免异步后操作 Context 报错（虽然这里操作 ref 是安全的）
    if (!mounted) return;

    ref
        .read(nameEditorModeControllerProvider(widget.traitId).notifier)
        .exitEdit();
  }

  void _handleCancel() {
    ref
        .read(nameEditorModeControllerProvider(widget.traitId).notifier)
        .exitEdit();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IconButton(
        onPressed: _handleCancel,
        icon: const Icon(Icons.close),
      ),
      title: TextField(
        controller: _controller,
        autofocus: true,
        // 4. 进入编辑模式自动聚焦，提升体验
        textInputAction: TextInputAction.done,
        // 键盘回车变成完成
        onSubmitted: (_) => _handleSave(),
        // 支持键盘回车提交
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          hintText: 'Enter name',
        ),
      ),
      trailing: IconButton(
        // 5. 根据状态控制按钮可用性
        onPressed: _canSave ? _handleSave : null,
        icon: Icon(
          Icons.check,
          // 可选：禁用态颜色处理，Material 3 通常自动处理 null onPressed
          color: _canSave ? context.theme.primaryColor : null,
        ),
      ),
    );
  }
}
