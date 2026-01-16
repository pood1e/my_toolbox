import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../providers.dart';
import '../state/ui_state.dart';

class CreateSessionDialog extends ConsumerStatefulWidget {
  const CreateSessionDialog({super.key});

  /// 静态辅助方法，方便外部调用
  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const CreateSessionDialog(),
    );
  }

  @override
  ConsumerState<CreateSessionDialog> createState() =>
      _CreateSessionDialogState();
}

class _CreateSessionDialogState extends ConsumerState<CreateSessionDialog> {
  // 用于表单验证
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _noteController;

  // 提交时的加载状态，防止重复提交
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleStart() async {
    // 1. 校验表单
    if (!_formKey.currentState!.validate()) return;

    // 2. 设置加载状态
    setState(() => _isSubmitting = true);

    try {
      // 3. 获取异步 Service
      final service = await ref.read(pomodoroServiceProvider.future);

      // 4. 调用业务逻辑
      await service.startSession(
        _nameController.text.trim(),
        _noteController.text.trim(),
      );

      if (mounted) {
        // 5. 成功后关闭弹窗
        Navigator.of(context).pop();
        Future.delayed(const Duration(milliseconds: 100), () {
          // 安全检查：虽然通常不会出错，但加上 try-catch 更稳健
          try {
            // 读取全局控制器
            final controller = ref.read(pomodoroSheetControllerProvider);

            // 只有当 Sheet 确实渲染出来了(isAttached)，才执行动画
            if (controller.isAttached) {
              controller.animateTo(
                1.0, // 1.0 代表全屏展开
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutQuart,
              );
            }
          } catch (e) {
            debugPrint('无法自动展开面板: $e');
          }
        });
      }
    } catch (e) {
      // 6. 错误处理
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('启动失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('开启新专注'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- 任务名称输入 ---
              TextFormField(
                controller: _nameController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '要做什么?',
                  hintText: '例如：阅读 Flutter 文档',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.check_circle_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入任务名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- 备注输入 ---
              TextFormField(
                controller: _noteController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: '备注 (可选)',
                  hintText: '记录当前的想法...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
                onFieldSubmitted: (_) => _handleStart(), // 回车直接提交
              ),
            ],
          ),
        ),
      ),
      actions: [
        // --- 取消按钮 ---
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),

        // --- 开始按钮 (带 Loading 态) ---
        FilledButton(
          onPressed: _isSubmitting ? null : _handleStart,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('开始'),
        ),
      ],
    );
  }
}
