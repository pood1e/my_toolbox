import 'package:app_core/di.dart';
import 'package:appflowy_editor/appflowy_editor.dart' as flowy;
import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';

import '../../service/note_service.dart';
import '../components/editor/editor_appbar.dart';
import '../components/editor/editor_canvas.dart';
import '../components/editor/editor_title.dart';
import '../state/ui_state.dart';

// =============================================================================
// 1. Page Layer: 负责数据加载路由
// =============================================================================
class DocumentEditorPage extends ConsumerWidget {
  final String? documentId; // 为空即为新建
  final String? initialTitle;

  const DocumentEditorPage({super.key, this.documentId, this.initialTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 场景 A: 新建模式 (直接进入 View)
    if (documentId == null) {
      return _DocumentEditorView(
        initialDocumentId: null,
        initialTitle: initialTitle ?? '',
        initialContent: const {},
      );
    }

    // 场景 B: 编辑模式 (等待数据加载)
    final asyncDoc = ref.watch(documentProvider(documentId!));

    return asyncDoc.when(
      // 只有在 Loading/Error 时才需要临时的 Scaffold 占位
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (doc) {
        // 数据解包
        final startTitle = doc?.title ?? initialTitle ?? '';
        final startContent = doc?.content ?? <String, dynamic>{};

        // 数据就绪，移交 View 层
        return _DocumentEditorView(
          initialDocumentId: documentId,
          initialTitle: startTitle,
          initialContent: startContent,
        );
      },
    );
  }
}

// =============================================================================
// 2. View Layer: 负责 UI 渲染与状态管理
// =============================================================================
class _DocumentEditorView extends ConsumerStatefulWidget {
  final String? initialDocumentId;
  final String initialTitle;
  final Map<String, dynamic> initialContent;

  const _DocumentEditorView({
    required this.initialDocumentId,
    required this.initialTitle,
    required this.initialContent,
  });

  @override
  ConsumerState<_DocumentEditorView> createState() =>
      _DocumentEditorViewState();
}

class _DocumentEditorViewState extends ConsumerState<_DocumentEditorView> {
  late final TextEditingController _titleController;
  late final flowy.EditorState _editorState;

  // 核心状态：当前文档ID (新建后会从 null 变为 uuid)
  String? _currentDocId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentDocId = widget.initialDocumentId;
    _titleController = TextEditingController(text: widget.initialTitle);
    _editorState = _initEditorState(widget.initialContent);
  }

  flowy.EditorState _initEditorState(Map<String, dynamic> content) {
    if (content.isNotEmpty) {
      try {
        final doc = flowy.Document.fromJson(content);
        return flowy.EditorState(document: doc);
      } catch (e) {
        debugPrint('Parse error: $e');
      }
    }
    return flowy.EditorState(
      document: flowy.Document.blank(withInitialText: true),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: SafeArea(
        // 使用 NestedScrollView 解决 infinite constraints 错误
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              // 1. 顶部 AppBar
              EditorAppBar(
                isSaving: _isSaving,
                onSave: _handleSave,
                onClose: () => Navigator.of(context).pop(),
              ),

              // 2. 间距
              SliverToBoxAdapter(child: Gaps.v16),

              // 3. 标题输入区 (随滚动消失)
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacings.page,
                ),
                sliver: SliverToBoxAdapter(
                  child: EditorTitle(controller: _titleController),
                ),
              ),

              SliverToBoxAdapter(child: Gaps.v12),
            ];
          },
          // 4. 编辑器主体 (作为 Body，拥有有限的高度约束)
          body: EditorCanvas(editorState: _editorState),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      final title = _titleController.text.trim();
      final content = _editorState.document.toJson();
      final service = await ref.read(noteServiceProvider.future);

      if (_currentDocId == null) {
        _currentDocId = await service.createDocument(
          title: title,
          content: content,
        ); // 标记为已创建
      } else {
        // Update 逻辑
        await service.updateDocument(
          id: _currentDocId!,
          title: title,
          content: content,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已保存'),
            duration: Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
