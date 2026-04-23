import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/book_project.dart';
import '../../core/constants/app_dimensions.dart';
import 'package:intl/intl.dart';

class ProjectCard extends StatelessWidget {
  final BookProject project;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onPreview;
  final VoidCallback? onExport;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    required this.onDelete,
    this.onPreview,
    this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Row(
            children: [
              // Cover thumbnail
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: project.coverPath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                        child: Image.file(
                          File(project.coverPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.book,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.book,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              // Project info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      project.author,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(project.updatedAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete();
                  } else if (value == 'preview' && onPreview != null) {
                    onPreview!();
                  } else if (value == 'export' && onExport != null) {
                    onExport!();
                  }
                },
                itemBuilder: (context) => [
                  if (onPreview != null)
                    PopupMenuItem(
                      value: 'preview',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text('预览', style: TextStyle(color: theme.colorScheme.primary)),
                        ],
                      ),
                    ),
                  if (onExport != null)
                    PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(Icons.ios_share, color: theme.colorScheme.secondary, size: 20),
                          const SizedBox(width: 8),
                          Text('导出', style: TextStyle(color: theme.colorScheme.secondary)),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: theme.colorScheme.error, size: 20),
                        const SizedBox(width: 8),
                        Text('删除', style: TextStyle(color: theme.colorScheme.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
