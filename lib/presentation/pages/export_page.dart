import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_dimensions.dart';
import '../../injection_container.dart';
import '../../domain/services/epub_builder.dart';
import '../../domain/services/image_service.dart';
import '../../data/models/book_project.dart';
import '../../data/repositories/project_repository.dart';

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
  BookProject? _project;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    try {
      final repository = context.read<ProjectRepository>();
      final project = await repository.getProjectById(widget.projectId);
      if (mounted) {
        setState(() {
          _project = project;
          _isLoading = false;
          if (project != null) {
            _titleController.text = project.title;
            _authorController.text = project.author;
            _languageController.text = project.metadata.language ?? 'zh-CN';
            _publisherController.text = project.metadata.publisher ?? '';
            _isbnController.text = project.metadata.isbn ?? '';
            _descriptionController.text = project.metadata.description ?? '';
          } else {
            _error = 'Project not found';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _project == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.exportTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(child: Text(_error ?? 'Project not found')),
      );
    }

    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
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
            _buildCoverPicker(context),
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
                onPressed: _isExporting ? null : () => _exportEpub(context),
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
  }

  Widget _buildCoverPicker(BuildContext context) {
    final coverPath = _project?.coverPath;

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: coverPath != null
          ? Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  child: Image.file(
                    File(coverPath),
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
                          backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: () => _removeCover(),
                        icon: const Icon(Icons.delete),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error.withValues(alpha: 0.8),
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
        setState(() {
          _project = _project?.copyWith(coverPath: savedPath);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择封面失败: $e')),
        );
      }
    }
  }

  void _removeCover() {
    setState(() {
      _project = _project?.copyWith(coverPath: null);
    });
  }

  void _exportEpub(BuildContext context) async {
    if (_project == null) return;

    setState(() => _isExporting = true);

    try {
      // Use dependency injection instead of manual instantiation
      final epubBuilder = getIt<EpubBuilder>();

      // Create updated project with current form values
      final updatedProject = _project!.copyWith(
        title: _titleController.text,
        author: _authorController.text,
        metadata: _project!.metadata.copyWith(
          language: _languageController.text,
          publisher: _publisherController.text.isEmpty ? null : _publisherController.text,
          isbn: _isbnController.text.isEmpty ? null : _isbnController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        ),
      );

      final outputFile = await epubBuilder.buildEpub(updatedProject);

      if (mounted) {
        setState(() => _isExporting = false);

        // Save updated metadata to repository
        final repository = context.read<ProjectRepository>();
        await repository.saveProject(updatedProject);

        // Offer to share
        await Share.shareXFiles(
          [XFile(outputFile.path)],
          text: '《${updatedProject.title}》EPUB电子书',
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
