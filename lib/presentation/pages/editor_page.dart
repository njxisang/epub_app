import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_dimensions.dart';
import '../../domain/services/image_service.dart';
import '../bloc/editor/editor_bloc.dart';
import '../bloc/editor/editor_event.dart';
import '../bloc/editor/editor_state.dart';
import '../widgets/chapter_list_tile.dart';
import '../widgets/editor_toolbar.dart';
import '../widgets/image_block_widget.dart';

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

  @override
  void dispose() {
    _quillController?.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditorBloc, EditorState>(
      listener: (context, state) {
        if (state is EditorLoaded && state.selectedChapter != null) {
          _initializeQuillController(state.selectedChapter!.blocks);
        }
      },
      builder: (context, state) {
        if (state is EditorLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is EditorError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(state.message)),
          );
        }

        if (state is EditorLoaded) {
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
                              onTap: () => context
                                  .read<EditorBloc>()
                                  .add(SelectChapter(chapter.id)),
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

  Widget _buildEditor(BuildContext context, EditorLoaded state) {
    return Column(
      children: [
        EditorToolbar(
          controller: _quillController!,
          onInsertImage: () => _insertImage(context, state.selectedChapterId!),
        ),
        Expanded(
          child: _quillController != null
              ? QuillEditor.basic(
                  controller: _quillController!,
                  focusNode: _focusNode,
                  scrollController: _scrollController,
                )
              : const Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }

  void _initializeQuillController(List blocks) {
    _quillController?.dispose();
    _quillController = QuillController.basic();
    // TODO: Parse blocks and populate editor
  }

  void _insertImage(BuildContext context, String chapterId) async {
    final imageService = context.read<ImageService>();

    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text(AppStrings.fromGallery),
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text(AppStrings.fromCamera),
            onTap: () => Navigator.pop(context, 'camera'),
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
        context.read<EditorBloc>().add(InsertImage(
              chapterId: chapterId,
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
