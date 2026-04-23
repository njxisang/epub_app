import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_dimensions.dart';
import '../../data/models/content_block.dart';
import '../../domain/services/image_service.dart';
import '../bloc/editor/editor_bloc.dart';
import '../bloc/editor/editor_event.dart';
import '../bloc/editor/editor_state.dart' as editor;

class EditorPage extends StatelessWidget {
  final String projectId;

  const EditorPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditorBloc(
        repository: context.read(),
      )..add(LoadProject(projectId)),
      child: const EditorPageView(),
    );
  }
}

class EditorPageView extends StatefulWidget {
  const EditorPageView({super.key});

  @override
  State<EditorPageView> createState() => _EditorPageViewState();
}

class _EditorPageViewState extends State<EditorPageView> {
  QuillController? _quillController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  String? _currentChapterId;
  bool _isPreviewMode = false;

  @override
  void dispose() {
    _saveCurrentChapter();
    _quillController?.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _saveCurrentChapter() {
    if (_quillController != null && mounted && _currentChapterId != null) {
      final blocks = _documentToBlocks(_quillController!.document);
      context.read<EditorBloc>().add(UpdateChapterContent(
        _currentChapterId!,
        blocks,
      ));
    }
  }

  List<ContentBlock> _documentToBlocks(Document document) {
    final blocks = <ContentBlock>[];
    final delta = document.toDelta();
    final operations = delta.toList();

    for (final op in operations) {
      if (op.data is String) {
        final text = op.data as String;
        if (text.trim().isNotEmpty) {
          blocks.add(ContentBlock.text(
            id: const Uuid().v4(),
            content: text,
          ));
        }
      } else if (op.data is Map) {
        final map = op.data as Map;
        if (map.containsKey(BlockEmbed.imageType)) {
          final imagePath = map[BlockEmbed.imageType] as String;
          blocks.add(ContentBlock.image(
            id: const Uuid().v4(),
            imagePath: imagePath,
          ));
        }
      }
    }

    return blocks;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditorBloc, editor.EditorState>(
      listener: (context, state) {
        if (state is editor.EditorLoaded && state.selectedChapter != null) {
          if (state.selectedChapterId != _currentChapterId) {
            _currentChapterId = state.selectedChapterId;
            _initializeQuillController(state.selectedChapter!.blocks);
          }
        }
      },
      builder: (context, state) {
        if (state is editor.EditorLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8F6F2),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is editor.EditorError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(state.message)),
          );
        }

        if (state is editor.EditorLoaded) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F6F2),
            appBar: _buildAppBar(context, state),
            body: Column(
              children: [
                Expanded(
                  child: _isPreviewMode
                      ? _buildPreview(state)
                      : _buildEditor(state),
                ),
                if (!_isPreviewMode) _buildBottomToolbar(context, state),
              ],
            ),
            drawer: _buildChapterDrawer(context, state),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, editor.EditorLoaded state) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.black87),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.project.title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.normal,
            ),
          ),
          if (state.selectedChapter != null)
            Text(
              state.selectedChapter!.title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
      actions: [
        if (state.hasUnsavedChanges)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '未保存',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange,
              ),
            ),
          ),
        IconButton(
          icon: Icon(
            _isPreviewMode ? Icons.edit : Icons.preview,
            color: Colors.black87,
          ),
          onPressed: () {
            setState(() {
              _isPreviewMode = !_isPreviewMode;
            });
          },
          tooltip: _isPreviewMode ? '编辑' : '预览',
        ),
        IconButton(
          icon: const Icon(Icons.save, color: Colors.black87),
          onPressed: () {
            _saveCurrentChapter();
            context.read<EditorBloc>().add(SaveProject());
          },
          tooltip: '保存',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.black87),
          onSelected: (value) {
            if (value == 'export') {
              context.push('/export/${state.project.id}');
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 20),
                  SizedBox(width: 12),
                  Text('导出设置'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChapterDrawer(BuildContext context, editor.EditorLoaded state) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              color: Theme.of(context).primaryColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📖 章节管理',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.project.title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${state.project.chapters.length} 个章节',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddChapterDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('新建'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: state.project.chapters.length,
                itemBuilder: (context, index) {
                  final chapter = state.project.chapters[index];
                  final isSelected = chapter.id == state.selectedChapterId;
                  return ListTile(
                    leading: Icon(
                      Icons.article_outlined,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                    ),
                    title: Text(
                      chapter.title,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.black87,
                      ),
                    ),
                    selected: isSelected,
                    selectedTileColor:
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    onTap: () {
                      _saveCurrentChapter();
                      context
                          .read<EditorBloc>()
                          .add(SelectChapter(chapter.id));
                      Navigator.pop(context);
                    },
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onSelected: (value) {
                        if (value == 'rename') {
                          _showRenameChapterDialog(
                              context, chapter.id, chapter.title);
                        } else if (value == 'delete') {
                          _showDeleteChapterDialog(
                              context, chapter.id, chapter.title);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'rename',
                          child: Text('重命名'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('删除', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor(editor.EditorLoaded state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _quillController != null
            ? QuillEditor(
                controller: _quillController!,
                focusNode: _focusNode,
                scrollController: _scrollController,
                config: QuillEditorConfig(
                  autoFocus: false,
                  expands: true,
                  scrollable: true,
                  padding: const EdgeInsets.all(20),
                  placeholder: '开始写作...',
                  embedBuilders: [
                    ImageEmbedBuilder(),
                  ],
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildPreview(editor.EditorLoaded state) {
    final chapter = state.selectedChapter;
    if (chapter == null) {
      return const Center(child: Text('请选择一个章节'));
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chapter.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            ...chapter.blocks.map((block) {
              if (block.type == BlockType.text && block.textContent != null) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    block.textContent!,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.8,
                      color: Colors.black87,
                    ),
                  ),
                );
              } else if (block.type == BlockType.image &&
                  block.imagePath != null) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(block.imagePath!),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 150,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomToolbar(
      BuildContext context, editor.EditorLoaded state) {
    if (_quillController == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _ToolbarButton(
              icon: Icons.format_bold,
              isActive: _quillController!.getSelectionStyle().containsKey(Attribute.bold.key),
              onPressed: () => _toggleFormat(Attribute.bold),
            ),
            _ToolbarButton(
              icon: Icons.format_italic,
              isActive: _quillController!.getSelectionStyle().containsKey(Attribute.italic.key),
              onPressed: () => _toggleFormat(Attribute.italic),
            ),
            _ToolbarButton(
              icon: Icons.format_underline,
              isActive: _quillController!.getSelectionStyle().containsKey(Attribute.underline.key),
              onPressed: () => _toggleFormat(Attribute.underline),
            ),
            const VerticalDivider(width: 16),
            _ToolbarButton(
              icon: Icons.title,
              onPressed: () => _toggleHeader(),
            ),
            _ToolbarButton(
              icon: Icons.format_list_bulleted,
              isActive: _quillController!.getSelectionStyle().containsKey(Attribute.list.key),
              onPressed: () => _toggleFormat(Attribute.list),
            ),
            _ToolbarButton(
              icon: Icons.format_list_numbered,
              onPressed: () => _toggleFormat(Attribute.ol),
            ),
            const Spacer(),
            _ToolbarButton(
              icon: Icons.image,
              onPressed: () => _insertImage(context),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleFormat(Attribute attribute) {
    final style = _quillController!.getSelectionStyle();
    if (style.containsKey(attribute.key)) {
      _quillController!.formatSelection(Attribute.clone(attribute, null));
    } else {
      _quillController!.formatSelection(attribute);
    }
    setState(() {});
  }

  void _toggleHeader() {
    final style = _quillController!.getSelectionStyle();
    if (style.containsKey(Attribute.header.key)) {
      _quillController!.formatSelection(Attribute.clone(Attribute.header, null));
    } else {
      _quillController!.formatSelection(Attribute.h1);
    }
    setState(() {});
  }

  void _initializeQuillController(List blocks) {
    _quillController?.dispose();

    final document = _blocksToDocument(blocks);
    _quillController = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );

    _quillController!.document.changes.listen((event) {
      _saveCurrentChapter();
      setState(() {});
    });
  }

  Document _blocksToDocument(List blocks) {
    if (blocks.isEmpty) {
      return Document();
    }

    final doc = Document();
    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      if (block.type == BlockType.text && block.textContent != null) {
        doc.insert(doc.length - 1, block.textContent!);
      } else if (block.type == BlockType.image && block.imagePath != null) {
        doc.insert(doc.length - 1, BlockEmbed.image(block.imagePath!));
      }
      if (i < blocks.length - 1) {
        doc.insert(doc.length - 1, '\n');
      }
    }

    return doc;
  }

  Future<void> _insertImage(BuildContext context) async {
    if (_quillController == null || _currentChapterId == null) return;

    final imageService = context.read<ImageService>();

    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('拍照'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final file = source == 'gallery'
          ? await imageService.pickImageFromGallery()
          : await imageService.takePhoto();

      if (file != null && mounted) {
        final savedPath = await imageService.saveImage(
            GoRouter.of(context).routeInformationProvider.value.uri.pathSegments[2], file);

        final index = _quillController!.selection.baseOffset;
        _quillController!.document.insert(index, BlockEmbed.image(savedPath));
        _quillController!.updateSelection(
          TextSelection.collapsed(offset: index + 1),
          ChangeSource.local,
        );

        context.read<EditorBloc>().add(InsertImage(
          chapterId: _currentChapterId!,
          imagePath: savedPath,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('插入图片失败: $e')),
        );
      }
    }
  }

  void _showAddChapterDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('新建章节'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '章节名称',
            hintText: '例如：第一章',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isNotEmpty) {
                context.read<EditorBloc>().add(AddChapter(title));
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _showRenameChapterDialog(
      BuildContext context, String chapterId, String currentTitle) {
    final controller = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('重命名章节'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '章节名称'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isNotEmpty) {
                context
                    .read<EditorBloc>()
                    .add(RenameChapter(chapterId, title));
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDeleteChapterDialog(
      BuildContext context, String chapterId, String title) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除章节'),
        content: Text('确定要删除 "$title" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              context.read<EditorBloc>().add(DeleteChapter(chapterId));
              Navigator.pop(dialogContext);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    this.isActive = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive
          ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 22,
            color: isActive
                ? Theme.of(context).primaryColor
                : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

/// Custom embed builder for images in QuillEditor
class ImageEmbedBuilder extends EmbedBuilder {
  @override
  String get key => BlockEmbed.imageType;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final imagePath = embedContext.node.value.data as String;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: () => _showImageOptions(context, embedContext),
        child: _buildImageWidget(imagePath),
      ),
    );
  }

  Widget _buildImageWidget(String imagePath) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorPlaceholder();
        },
      );
    } else {
      return Image.file(
        File(imagePath),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorPlaceholder();
        },
      );
    }
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      height: 100,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
      ),
    );
  }

  void _showImageOptions(BuildContext context, EmbedContext embedContext) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除图片', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                final delta = embedContext.controller.document.toDelta();
                int embedIndex = -1;
                for (int i = 0; i < delta.length; i++) {
                  final op = delta[i];
                  if (op.data is Map &&
                      (op.data as Map).containsKey(BlockEmbed.imageType)) {
                    embedIndex = i;
                    break;
                  }
                }
                if (embedIndex >= 0) {
                  embedContext.controller.replaceText(
                    embedIndex,
                    1,
                    '',
                    const TextSelection.collapsed(offset: 0),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
