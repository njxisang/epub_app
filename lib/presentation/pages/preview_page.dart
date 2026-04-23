import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../bloc/editor/editor_bloc.dart';
import '../bloc/editor/editor_state.dart';
import '../widgets/book_page_view.dart';

class PreviewPage extends StatelessWidget {
  final String projectId;

  const PreviewPage({super.key, required this.projectId});

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
            title: const Text(AppStrings.previewTitle),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.menu_book),
                onPressed: () => _showTableOfContents(context, state),
                tooltip: AppStrings.tableOfContents,
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: BookPageView(
                  project: state.project,
                ),
              ),
              // Page indicator
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
      },
    );
  }

  void _showTableOfContents(BuildContext context, EditorLoaded state) {
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
                itemCount: state.project.chapters.length,
                itemBuilder: (context, index) {
                  final chapter = state.project.chapters[index];
                  return ListTile(
                    leading: Text('${index + 1}'),
                    title: Text(chapter.title),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to chapter
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
