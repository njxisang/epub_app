import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/book_project.dart';
import '../../data/models/content_block.dart';

class BookPageView extends StatefulWidget {
  final BookProject project;

  const BookPageView({super.key, required this.project});

  @override
  State<BookPageView> createState() => _BookPageViewState();
}

class _BookPageViewState extends State<BookPageView> {
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
    // Flatten all blocks from all chapters into pages
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
      // Each chapter starts a new logical section
      if (chapter.blocks.isEmpty) {
        pages.add(_PageContent(
          chapterIndex: i,
          chapterTitle: chapter.title,
          blocks: [],
        ));
      } else {
        // Group blocks into pages (simplified - one block per page for now)
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
          // Chapter title header
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
          // Content
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
