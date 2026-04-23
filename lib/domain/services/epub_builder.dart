import 'dart:io';
import 'package:epub/epub.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../data/models/book_project.dart';
import '../../data/models/chapter.dart';
import '../../data/models/content_block.dart';

class EpubBuilder {
  Future<File> buildEpub(BookProject project, {String? outputPath}) async {
    final book = EpubBook();

    // Set metadata
    book.Title = project.title;
    book.Author = project.author;
    book.Language = project.metadata.language ?? 'zh-CN';
    book.Publisher = project.metadata.publisher;
    book.Description = project.metadata.description;
    book.Identifier = project.metadata.isbn ?? project.id;

    // Cover image
    if (project.coverPath != null) {
      final coverFile = File(project.coverPath!);
      if (await coverFile.exists()) {
        book.CoverImage = EpubCoverImage(
          p.basename(project.coverPath!),
          await coverFile.readAsBytes(),
        );
      }
    }

    // Chapters
    final chapters = <EpubChapter>[];
    for (var i = 0; i < project.chapters.length; i++) {
      final chapter = project.chapters[i];
      final epubChapter = _buildChapter(chapter, i);
      chapters.add(epubChapter);
    }
    book.Chapters = chapters;

    // Content
    book.Content = EpubContent();

    // Images
    final imageFiles = <String, EpubImage>{};
    for (final chapter in project.chapters) {
      for (final block in chapter.blocks) {
        if (block.type == BlockType.image && block.imagePath != null) {
          final imageFile = File(block.imagePath!);
          if (await imageFile.exists()) {
            final name = p.basename(block.imagePath!);
            if (!imageFiles.containsKey(name)) {
              imageFiles[name] = EpubImage(
                name,
                await imageFile.readAsBytes(),
              );
            }
          }
        }
      }
    }
    book.Content.Images = imageFiles;

    // Styles
    final cssContent = _getDefaultStyles();
    book.Content.Css = {
      'styles.css': EpubCssFile(
        'styles.css',
        cssContent,
      ),
    };

    // Write EPUB file
    final outputDir = outputPath != null
        ? Directory(outputPath)
        : await getApplicationDocumentsDirectory();
    final fileName = '${_sanitizeFileName(project.title)}.epub';
    final outputFile = File(p.join(outputDir.path, fileName));

    await outputDir.create(recursive: true);

    final epubWriter = EpubWriter();
    final bytes = await epubWriter.write(book);
    await outputFile.writeAsBytes(bytes);

    return outputFile;
  }

  EpubChapter _buildChapter(Chapter chapter, int index) {
    final content = StringBuffer();
    content.writeln('<html xmlns="http://www.w3.org/1999/xhtml">');
    content.writeln('<head>');
    content.writeln('<title>${_escapeXml(chapter.title)}</title>');
    content.writeln('<link rel="stylesheet" type="text/css" href="styles.css" />');
    content.writeln('</head>');
    content.writeln('<body>');
    content.writeln('<h1>${_escapeXml(chapter.title)}</h1>');

    for (final block in chapter.blocks) {
      if (block.type == BlockType.text && block.textContent != null) {
        content.writeln(block.textContent);
      } else if (block.type == BlockType.image && block.imagePath != null) {
        final fileName = p.basename(block.imagePath!);
        content.writeln('<div class="image-block">');
        content.writeln('<img src="$fileName" alt="image" />');
        content.writeln('</div>');
      }
    }

    content.writeln('</body>');
    content.writeln('</html>');

    return EpubChapter(
      HtmlContent: content.toString(),
      Title: chapter.title,
      ContentFileName: 'chapter_${index + 1}.xhtml',
    );
  }

  String _getDefaultStyles() {
    return '''
body {
  font-family: serif;
  margin: 5%;
  line-height: 1.6;
  text-align: justify;
}

h1 {
  text-align: center;
  margin-bottom: 1em;
}

h2 {
  margin-top: 1.5em;
}

p {
  text-indent: 2em;
  margin: 0.5em 0;
}

.image-block {
  text-align: center;
  margin: 1em 0;
}

.image-block img {
  max-width: 100%;
  height: auto;
}
''';
  }

  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }
}
