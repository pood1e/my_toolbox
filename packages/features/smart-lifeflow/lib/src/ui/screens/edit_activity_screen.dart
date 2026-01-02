import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../domain/reality_models.dart';
import '../../service/service_providers.dart';

class EditActivityScreen extends ConsumerStatefulWidget {
  final String? activityId;

  const EditActivityScreen({super.key, this.activityId});

  bool get isEditing => activityId != null;

  @override
  ConsumerState<EditActivityScreen> createState() => _EditActivityScreenState();
}

class _EditActivityScreenState extends ConsumerState<EditActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  // 假设的 Icon 和 Color Picker 的 state
  String? _selectedIcon;
  String? _selectedColorHex;

  Activity? _initialActivity;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();

    if (widget.isEditing) {
      // 如果是编辑模式，异步获取初始数据
      _loadInitialData();
    }
  }

  Future<void> _loadInitialData() async {
    final service = await ref.read(activityServiceProvider.future);
    final activity = await service.getActivityById(widget.activityId!);
    if (activity != null && mounted) {
      setState(() {
        _initialActivity = activity;
        _nameController.text = activity.name;
        _selectedIcon = activity.icon;
        _selectedColorHex = activity.colorHex;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final service = await ref.read(activityServiceProvider.future);

    try {
      if (widget.isEditing) {
        // 更新模式
        final updatedActivity = _initialActivity!.copyWith(
          name: _nameController.text.trim(),
          icon: _selectedIcon,
          colorHex: _selectedColorHex,
        );
        await service.updateActivityDetails(updatedActivity);
      } else {
        // 新建模式
        await service.createNewActivity(
          name: _nameController.text.trim(),
          icon: _selectedIcon,
          colorHex: _selectedColorHex,
        );
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      // 显示错误提示
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? '编辑活动' : '新建活动'),
        actions: [IconButton(icon: const Icon(Icons.done), onPressed: _onSave)],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '活动名称',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '名称不能为空';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            // 简化的 Icon 和 Color Picker
            // 在实际项目中，你会用第三方包来做这个
            ListTile(
              title: const Text('选择图标'),
              trailing: Text(_selectedIcon ?? '未选择'),
              onTap: () => setState(() => _selectedIcon = '💼'), // 示例
            ),
            ListTile(
              title: const Text('选择颜色'),
              trailing: CircleAvatar(
                backgroundColor: Color(
                  int.parse('0xFF${_selectedColorHex ?? 'CCCCCC'}'),
                ),
              ),
              onTap: () => setState(() => _selectedColorHex = 'F44336'), // 示例
            ),
          ],
        ),
      ),
    );
  }
}
