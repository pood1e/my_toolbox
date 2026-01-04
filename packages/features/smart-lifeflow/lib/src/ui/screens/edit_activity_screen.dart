import 'package:app_core/di.dart';
import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';

import '../components/activity/edit_activity_controller.dart';
import '../components/activity/edit_activity_form_body.dart';

class EditActivityScreen extends ConsumerStatefulWidget {
  final String? activityId;

  const EditActivityScreen({super.key, this.activityId});

  bool get isEditing => activityId != null;

  @override
  ConsumerState<EditActivityScreen> createState() => _EditActivityScreenState();
}

class _EditActivityScreenState extends ConsumerState<EditActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  // 用于标记是否已经初始化过 textController，防止由 build 触发的重绘覆盖用户输入
  bool _isTextInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // --- Actions ---

  Future<void> _onSave(EditActivityController controller) async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await controller.save(_nameController.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnack('保存失败: $e');
    }
  }

  Future<void> _onDelete(EditActivityController controller) async {
    // ... 保持原有弹窗逻辑不变 ...
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colorScheme.surface,
        title: const Text('确认删除?'),
        content: const Text('删除后，该活动及其历史记录将受到影响。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              '删除',
              style: TextStyle(color: context.colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await controller.delete();
        if (mounted) Navigator.pop(context);
      } catch (e) {
        _showSnack('删除失败: $e');
      }
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: context.colorScheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. 获取 generated provider
    // 注意：Riverpod Generator 生成的 provider 会自动带有参数
    final asyncState = ref.watch(
      editActivityControllerProvider(widget.activityId),
    );
    final controller = ref.read(
      editActivityControllerProvider(widget.activityId).notifier,
    );

    return Scaffold(
      backgroundColor: context.pageBackground,
      appBar: AppBar(
        title: Text(widget.isEditing ? '编辑活动' : '新建活动'),
        backgroundColor: context.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: context.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: context.colorScheme.onSurface,
        ),
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: context.colorScheme.error,
              ),
              onPressed: () => _onDelete(controller),
            ),
          Gaps.h4,
          // 只有当数据加载完成时，保存按钮才可用
          TextButton(
            onPressed: asyncState.isLoading ? null : () => _onSave(controller),
            child: Text(
              '保存',
              style: context.textTheme.titleMedium?.copyWith(
                // Loading 时变灰
                color: asyncState.isLoading
                    ? context.colorScheme.outline
                    : context.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Gaps.h8,
        ],
      ),
      // 2. 使用 .when 处理 AsyncValue
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (state) {
          // 3. 数据同步逻辑
          // 仅在第一次加载完数据，且从未初始化过时，设置 controller 的 text
          if (widget.isEditing &&
              state.initialData != null &&
              !_isTextInitialized) {
            _nameController.text = state.initialData!.name;
            _isTextInitialized = true; // 标记已初始化，防止后续 setState 覆盖用户正在输入的内容
          }

          return Form(
            key: _formKey,
            child: EditActivityFormBody(
              nameController: _nameController,
              selectedIcon: state.selectedIcon,
              selectedColorHex: state.selectedColorHex,
              // Callbacks
              onNameChanged: (_) => setState(() {}),
              // 刷新预览
              onColorSelected: controller.setColor,
              onIconSelected: controller.setIcon,
            ),
          );
        },
      ),
    );
  }
}
