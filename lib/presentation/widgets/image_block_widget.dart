import 'dart:io';
import 'package:flutter/material.dart';

class ImageBlockWidget extends StatelessWidget {
  final String imagePath;
  final VoidCallback? onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  const ImageBlockWidget({
    super.key,
    required this.imagePath,
    this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Image
          GestureDetector(
            onTap: () => _showFullScreen(context),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 48,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '图片加载失败',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          // Action buttons
          if (onDelete != null || onMoveUp != null || onMoveDown != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (onMoveUp != null)
                    IconButton(
                      icon: const Icon(Icons.arrow_upward, size: 20),
                      onPressed: onMoveUp,
                      tooltip: '上移',
                    ),
                  if (onMoveDown != null)
                    IconButton(
                      icon: const Icon(Icons.arrow_downward, size: 20),
                      onPressed: onMoveDown,
                      tooltip: '下移',
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        size: 20,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: onDelete,
                      tooltip: '删除',
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
