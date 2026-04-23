import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class EditorToolbar extends StatelessWidget {
  final QuillController controller;
  final VoidCallback onInsertImage;

  const EditorToolbar({
    super.key,
    required this.controller,
    required this.onInsertImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withAlpha(51),
          ),
        ),
      ),
      child: QuillSimpleToolbar(
        controller: controller,
        config: const QuillSimpleToolbarConfig(
          showAlignmentButtons: false,
          showBackgroundColorButton: false,
          showCenterAlignment: false,
          showCodeBlock: false,
          showColorButton: false,
          showDirection: false,
          showFontFamily: false,
          showFontSize: false,
          showHeaderStyle: true,
          showIndent: false,
          showInlineCode: false,
          showJustifyAlignment: false,
          showLeftAlignment: false,
          showLink: false,
          showQuote: false,
          showRightAlignment: false,
          showSearchButton: false,
          showSmallButton: false,
          showStrikeThrough: true,
          showSubscript: false,
          showSuperscript: false,
          showUndo: true,
          showRedo: true,
          showListBullets: true,
          showListNumbers: true,
          showListCheck: false,
          showClearFormat: true,
          multiRowsDisplay: false,
        ),
      ),
    );
  }
}
