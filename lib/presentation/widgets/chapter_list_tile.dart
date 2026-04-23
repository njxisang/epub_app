import 'package:flutter/material.dart';

class ChapterListTile extends StatelessWidget {
  final dynamic chapter;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const ChapterListTile({
    super.key,
    required this.chapter,
    required this.isSelected,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: isSelected ? theme.colorScheme.primaryContainer : null,
      child: ListTile(
        leading: Icon(
          Icons.article_outlined,
          color: isSelected ? theme.colorScheme.onPrimaryContainer : null,
        ),
        title: Text(
          chapter.title,
          style: TextStyle(
            color: isSelected ? theme.colorScheme.onPrimaryContainer : null,
            fontWeight: isSelected ? FontWeight.bold : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${chapter.blocks.length} 块',
          style: TextStyle(
            fontSize: 12,
            color: isSelected
                ? theme.colorScheme.onPrimaryContainer.withOpacity(0.7)
                : theme.colorScheme.outline,
          ),
        ),
        onTap: onTap,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'rename') {
              onRename();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'rename', child: Text('重命名')),
            PopupMenuItem(
              value: 'delete',
              child: Text('删除', style: TextStyle(color: theme.colorScheme.error)),
            ),
          ],
        ),
      ),
    );
  }
}
