import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../bloc/project_list/project_list_bloc.dart';
import '../bloc/project_list/project_list_event.dart';
import '../bloc/project_list/project_list_state.dart';
import '../widgets/project_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProjectListBloc(
        repository: context.read(),
      )..add(LoadProjects()),
      child: const HomePageView(),
    );
  }
}

class HomePageView extends StatelessWidget {
  const HomePageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
      ),
      body: BlocConsumer<ProjectListBloc, ProjectListState>(
        listener: (context, state) {
          if (state is ProjectCreated) {
            context.push('/editor/${state.project.id}');
          }
        },
        builder: (context, state) {
          if (state is ProjectListLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProjectListError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<ProjectListBloc>().add(LoadProjects()),
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          if (state is ProjectListLoaded) {
            if (state.projects.isEmpty) {
              return const EmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.projects.length,
              itemBuilder: (context, index) {
                final project = state.projects[index];
                return ProjectCard(
                  project: project,
                  onTap: () => context.push('/editor/${project.id}'),
                  onDelete: () => _showDeleteDialog(context, project.id, project.title),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.createProject),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final titleController = TextEditingController();
    final authorController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.createProject),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: AppStrings.bookTitle,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: authorController,
              decoration: const InputDecoration(
                labelText: AppStrings.author,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              final author = authorController.text.trim();
              if (title.isNotEmpty && author.isNotEmpty) {
                context.read<ProjectListBloc>().add(
                      CreateProject(title: title, author: author),
                    );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String projectId, String projectTitle) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.deleteConfirmTitle),
        content: Text('确定要删除《$projectTitle》吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              context.read<ProjectListBloc>().add(DeleteProject(projectId));
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

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            AppStrings.emptyStateTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.emptyStateSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}
