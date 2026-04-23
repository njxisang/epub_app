import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_dimensions.dart';
import '../../domain/services/epub_builder.dart';
import '../../domain/services/image_service.dart';
import '../bloc/editor/editor_bloc.dart';
import '../bloc/editor/editor_event.dart';
import '../bloc/editor/editor_state.dart';

class ExportPage extends StatefulWidget {
  final String projectId;

  const ExportPage({super.key, required this.projectId});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _languageController = TextEditingController();
  final _publisherController = TextEditingController();
  final _isbnController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  void _loadMetadata() {
    final state = context.read<EditorBloc>().state;
    if (state is EditorLoaded) {
      _titleController.text = state.project.title;
      _authorController.text = state.project.author;
      _languageController.text = state.project.metadata.language ?? 'zh-CN';
      _publisherController.text = state.project.metadata.publisher ?? '';
      _isbnController.text = state.project.metadata.isbn ?? '';
      _descriptionController.text = state.project.metadata.description ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _languageController.dispose();
    _publisherController.dispose();
    _isbnController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditorBloc, EditorState>(
      builder: (context, state) {
        if (state is! EditorLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.exportTitle),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover Section
                Text(
                  AppStrings.coverImage,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _buildCoverPicker(context, state),
                const SizedBox(height: 24),

                // Metadata Section
                Text(
                  AppStrings.metadata,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _buildMetadataForm(),
                const SizedBox(height: 32),

                // Export Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isExporting ? null : () => _exportEpub(context, state),
                    icon: _isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.book),
                    label: Text(_isExporting ? AppStrings.exporting : AppStrings.exportEpub),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoverPicker(BuildContext context, EditorLoaded state) {
    final coverPath = state.project.coverPath;

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: coverPath != null
          ? Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  child: Image.asset(
                    coverPath,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderCover(context),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      IconButton.filled(
                        onPressed: () => _pickCover(context),
                        icon: const Icon(Icons.edit),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: () => context.read<EditorBloc>().add(
                              const UpdateMetadata(coverPath: null),
                            ),
                        icon: const Icon(Icons.delete),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : InkWell(
              onTap: () => _pickCover(context),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              child: _buildPlaceholderCover(context),
            ),
    );
  }

  Widget _buildPlaceholderCover(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.selectCover,
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
        ),
      ],
    );
  }

  Widget _buildMetadataForm() {
    return Column(
      children: [
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(labelText: AppStrings.bookTitle),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _authorController,
          decoration: const InputDecoration(labelText: AppStrings.author),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _languageController,
          decoration: const InputDecoration(labelText: AppStrings.language),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _publisherController,
          decoration: const InputDecoration(labelText: AppStrings.publisher),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _isbnController,
          decoration: const InputDecoration(labelText: AppStrings.isbn),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(labelText: AppStrings.description),
          maxLines: 3,
        ),
      ],
    );
  }

  void _pickCover(BuildContext context) async {
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

    if (source == null) return;

    try {
      final file = source == 'gallery'
          ? await imageService.pickImageFromGallery()
          : await imageService.takePhoto();

      if (file != null && mounted) {
        final savedPath = await imageService.saveImage(widget.projectId, file, isCover: true);
        context.read<EditorBloc>().add(UpdateMetadata(coverPath: savedPath));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择封面失败: $e')),
        );
      }
    }
  }

  void _exportEpub(BuildContext context, EditorLoaded state) async {
    // Update metadata first
    context.read<EditorBloc>().add(UpdateMetadata(
          title: _titleController.text,
          author: _authorController.text,
        ));

    setState(() => _isExporting = true);

    try {
      final epubBuilder = EpubBuilder();
      final project = state.project.copyWith(
        title: _titleController.text,
        author: _authorController.text,
      );

      final outputFile = await epubBuilder.buildEpub(project);

      if (mounted) {
        setState(() => _isExporting = false);

        // Offer to share
        await Share.shareXFiles(
          [XFile(outputFile.path)],
          text: '《${project.title}》EPUB电子书',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.exportSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.exportFailed}: $e')),
        );
      }
    }
  }
}
