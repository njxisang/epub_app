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
import '../widgets/chapter_list_tile.dart';
import '../widgets/editor_toolbar.dart';

class EditorPage extends StatelessWidget {
  final String projectId;

  const EditorPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditorBloc(
        repository: context.read(),
      )..add(LoadProject(projectId)),
      child: EditorPageView(projectId: projectId),
    );
  }
}

class EditorPageView extends StatefulWidget {
  final String projectId;

  const EditorPageView({super.key, required this.projectId});

  @override
  State<EditorPageView> createState() => _EditorPageViewState();
}

class _EditorPageViewState extends State<EditorPageView> {
  QuillController? _quillController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  String? _currentChapterId;

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
    final plainText = document.toPlainText().trim();
    if (plainText.isNotEmpty) {
      blocks.add(ContentBlock.text(
        id: const Uuid().v4(),
        content: plainText,
      ));
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
            appBar: AppBar(
              title: Text(state.project.title),
              actions: [
                if (state.hasUnsavedChanges)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Center(
                      child: Text('未保存', style: TextStyle(color: Colors.orange)),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () {
                    _saveCurrentChapter();
                    context.read<EditorBloc>().add(SaveProject());
                  },
                  tooltip: '保存',
                ),
                IconButton(
                  icon: const Icon(Icons.preview),
                  onPressed: () => context.push('/preview/${widget.projectId}'),
                  tooltip: '预览',
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => context.push('/export/${widget.projectId}'),
                  tooltip: '导出设置',
                ),
              ],
            ),
            body: Row(
              children: [
                // Chapter list sidebar
                Container(
                  width: 200,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(AppDimensions.paddingM),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '章节',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _showAddChapterDialog(context),
                              tooltip: AppStrings.addChapter,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: state.project.chapters.length,
                          itemBuilder: (context, index) {
                            final chapter = state.project.chapters[index];
                            return ChapterListTile(
                              chapter: chapter,
                              isSelected: chapter.id == state.selectedChapterId,
                              onTap: () {
                                _saveCurrentChapter();
                                context
                                    .read<EditorBloc>()
                                    .add(SelectChapter(chapter.id));
                              },
                              onRename: () =>
                                  _showRenameChapterDialog(context, chapter.id, chapter.title),
                              onDelete: () =>
                                  _showDeleteChapterDialog(context, chapter.id, chapter.title),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Editor area
                Expanded(
                  child: Column(
                    children: [
                      if (state.selectedChapter != null)
                        Expanded(
                          child: _buildEditor(context, state),
                        )
                      else
                        const Center(child: Text('请选择一个章节')),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEditor(BuildContext context, editor.EditorLoaded state) {
    return Column(
      children: [
        EditorToolbar(
          controller: _quillController!,
          onInsertImage: () => _insertImage(context),
        ),
        Expanded(
          child: _quillController != null
              ? QuillEditor(
                  controller: _quillController!,
                  focusNode: _focusNode,
                  scrollController: _scrollController,
                  config: QuillEditorConfig(
                    autoFocus: false,
                    expands: true,
                    scrollable: true,
                    embedBuilders: [
                      ImageEmbedBuilder(),
                    ],
                  ),
                )
              : const Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }

  void _initializeQuillController(List blocks) {
    _quillController?.dispose();

    final document = _blocksToDocument(blocks);
    _quillController = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );

    // Listen for document changes and save
    _quillController!.document.changes.listen((event) {
      _saveCurrentChapter();
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
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text(AppStrings.fromGallery),
            onTap: () => Navigator.pop(ctx, 'gallery'),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text(AppStrings.fromCamera),
            onTap: () => Navigator.pop(ctx, 'camera'),
          ),
        ],
      ),
    );

    if (source == null || !mounted) return;

    try {
      final file = source == 'gallery'
          ? await imageService.pickImageFromGallery()
          : await imageService.takePhoto();

      if (file != null && mounted) {
        final savedPath = await imageService.saveImage(widget.projectId, file);

        // Insert image into Quill document
        final index = _quillController!.selection.baseOffset;
        _quillController!.document.insert(index, BlockEmbed.image(savedPath));
        _quillController!.updateSelection(
          TextSelection.collapsed(offset: index + 1),
          ChangeSource.local,
        );

        // Also update the bloc state for persistence
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
        title: const Text(AppStrings.addChapter),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: AppStrings.chapterName),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isNotEmpty) {
                context.read<EditorBloc>().add(AddChapter(title));
                Navigator.pop(dialogContext);
              }
            },
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    );
  }

  void _showRenameChapterDialog(BuildContext context, String chapterId, String currentTitle) {
    final controller = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.renameChapter),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: AppStrings.chapterName),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isNotEmpty) {
                context.read<EditorBloc>().add(RenameChapter(chapterId, title));
                Navigator.pop(dialogContext);
              }
            },
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
  }

  void _showDeleteChapterDialog(BuildContext context, String chapterId, String title) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.deleteChapter),
        content: Text('确定要删除"$title"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              context.read<EditorBloc>().add(DeleteChapter(chapterId));
              Navigator.pop(dialogContext);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text(AppStrings.delete),
          ),
        ],
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
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('删除图片'),
            onTap: () {
              Navigator.pop(ctx);
              // Find and replace the image embed with empty text
              final delta = embedContext.controller.document.toDelta();
              int embedIndex = -1;
              for (int i = 0; i < delta.length; i++) {
                final op = delta[i];
                if (op.data is Map && (op.data as Map).containsKey(BlockEmbed.imageType)) {
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
    );
  }
}
