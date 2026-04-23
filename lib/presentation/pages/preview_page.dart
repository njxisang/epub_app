import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/book_project.dart';
import '../../data/models/content_block.dart';
import '../../data/repositories/project_repository.dart';

class PreviewPage extends StatefulWidget {
  final String projectId;

  const PreviewPage({super.key, required this.projectId});

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
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
          _error = project == null ? 'Project not found' : null;
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
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _project == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.previewTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(child: Text(_error ?? 'Project not found')),
      );
    }

    return _buildScaffold(context, _project!);
  }

  Widget _buildScaffold(BuildContext context, BookProject project) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.previewTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            onPressed: () => _showTableOfContents(context, project),
            tooltip: AppStrings.tableOfContents,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _PreviewPageView(project: project),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              '拖动翻页',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTableOfContents(BuildContext context, BookProject project) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.tableOfContents,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: project.chapters.length,
                itemBuilder: (context, index) {
                  final chapter = project.chapters[index];
                  return ListTile(
                    leading: Text('${index + 1}'),
                    title: Text(chapter.title),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Preview page view with navigation support for table of contents
class _PreviewPageView extends StatefulWidget {
  final BookProject project;

  const _PreviewPageView({required this.project});

  @override
  State<_PreviewPageView> createState() => _PreviewPageViewState();
}

class _PreviewPageViewState extends State<_PreviewPageView> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = _generatePages();

    if (pages.isEmpty) {
      return const Center(child: Text('暂无内容'));
    }

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: pages.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              return _buildPage(context, pages[index]);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '第 ${_currentPage + 1} / ${pages.length} 页',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ),
      ],
    );
  }

  List<_PageContent> _generatePages() {
    final pages = <_PageContent>[];
    final chapters = widget.project.chapters;

    for (var i = 0; i < chapters.length; i++) {
      final chapter = chapters[i];
      if (chapter.blocks.isEmpty) {
        pages.add(_PageContent(
          chapterIndex: i,
          chapterTitle: chapter.title,
          blocks: [],
        ));
      } else {
        for (final block in chapter.blocks) {
          pages.add(_PageContent(
            chapterIndex: i,
            chapterTitle: chapter.title,
            blocks: [block],
          ));
        }
      }
    }

    return pages;
  }

  Widget _buildPage(BuildContext context, _PageContent page) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.bookmark,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    page.chapterTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildContent(context, page.blocks),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<ContentBlock> blocks) {
    if (blocks.isEmpty) {
      return Text(
        '（空章节）',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.outline,
              fontStyle: FontStyle.italic,
            ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.map((block) {
        if (block.type == BlockType.text) {
          return Text(
            block.textContent ?? '',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.8,
                ),
          );
        } else if (block.type == BlockType.image && block.imagePath != null) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(block.imagePath!),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }
}

class _PageContent {
  final int chapterIndex;
  final String chapterTitle;
  final List<ContentBlock> blocks;

  _PageContent({
    required this.chapterIndex,
    required this.chapterTitle,
    required this.blocks,
  });
}
