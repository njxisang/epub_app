import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../data/models/book_project.dart';
import '../../data/models/chapter.dart';
import '../../data/models/content_block.dart';

class EpubBuilder {
  Future<File> buildEpub(BookProject project, {String? outputPath}) async {
    final archive = Archive();

    // mimetype (must be first and uncompressed)
    final mimetype = 'application/epub+zip';
    archive.addFile(ArchiveFile('mimetype', mimetype.length, utf8.encode(mimetype)));

    // META-INF/container.xml
    final containerXml = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="EPUB/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
    final containerBytes = utf8.encode(containerXml);
    archive.addFile(ArchiveFile('META-INF/container.xml', containerBytes.length, containerBytes));

    // EPUB/content.opf
    final contentOpf = _buildContentOpf(project);
    final contentOpfBytes = utf8.encode(contentOpf);
    archive.addFile(ArchiveFile('EPUB/content.opf', contentOpfBytes.length, contentOpfBytes));

    // EPUB/nav.xhtml (EPUB3 navigation)
    final navXhtml = _buildNavXhtml(project);
    final navXhtmlBytes = utf8.encode(navXhtml);
    archive.addFile(ArchiveFile('EPUB/nav.xhtml', navXhtmlBytes.length, navXhtmlBytes));

    // EPUB/toc.ncx (EPUB2 navigation)
    final tocNcx = _buildTocNcx(project);
    final tocNcxBytes = utf8.encode(tocNcx);
    archive.addFile(ArchiveFile('EPUB/toc.ncx', tocNcxBytes.length, tocNcxBytes));

    // EPUB/styles/styles.css
    final stylesCss = _getDefaultStyles();
    final stylesCssBytes = utf8.encode(stylesCss);
    archive.addFile(ArchiveFile('EPUB/styles/styles.css', stylesCssBytes.length, stylesCssBytes));

    // Cover image
    List<int>? coverBytes;
    if (project.coverPath != null) {
      final coverFile = File(project.coverPath!);
      if (await coverFile.exists()) {
        coverBytes = await coverFile.readAsBytes();
        archive.addFile(ArchiveFile('EPUB/images/cover${p.extension(project.coverPath!)}', coverBytes.length, coverBytes));
      }
    }

    // Images and chapters
    final imageFiles = <String, List<int>>{};
    for (final chapter in project.chapters) {
      for (final block in chapter.blocks) {
        if (block.type == BlockType.image && block.imagePath != null) {
          final imageFile = File(block.imagePath!);
          if (await imageFile.exists()) {
            final name = p.basename(block.imagePath!);
            if (!imageFiles.containsKey(name)) {
              imageFiles[name] = await imageFile.readAsBytes();
            }
          }
        }
      }
    }

    // Add images to archive
    for (final entry in imageFiles.entries) {
      archive.addFile(ArchiveFile('EPUB/images/${entry.key}', entry.value.length, entry.value));
    }

    // Add chapters
    for (var i = 0; i < project.chapters.length; i++) {
      final chapterXhtml = _buildChapterXhtml(project.chapters[i], i, imageFiles.keys.toList());
      final chapterBytes = utf8.encode(chapterXhtml);
      archive.addFile(ArchiveFile('EPUB/chapters/chapter_${i + 1}.xhtml', chapterBytes.length, chapterBytes));
    }

    // Write EPUB file
    final outputDir = outputPath != null
        ? Directory(outputPath)
        : await getApplicationDocumentsDirectory();
    final fileName = '${_sanitizeFileName(project.title)}.epub';
    final outputFile = File(p.join(outputDir.path, fileName));

    await outputDir.create(recursive: true);

    final encoder = ZipEncoder();
    final zipData = encoder.encode(archive);
    await outputFile.writeAsBytes(zipData);

    return outputFile;
  }

  String _buildContentOpf(BookProject project) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="uid">');
    buffer.writeln('  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">');
    buffer.writeln('    <dc:identifier id="uid">${project.metadata.isbn ?? project.id}</dc:identifier>');
    buffer.writeln('    <dc:title>${_escapeXml(project.title)}</dc:title>');
    buffer.writeln('    <dc:creator>${_escapeXml(project.author)}</dc:creator>');
    buffer.writeln('    <dc:language>${project.metadata.language ?? 'zh-CN'}</dc:language>');
    if (project.metadata.publisher != null) {
      buffer.writeln('    <dc:publisher>${_escapeXml(project.metadata.publisher!)}</dc:publisher>');
    }
    if (project.metadata.description != null) {
      buffer.writeln('    <dc:description>${_escapeXml(project.metadata.description!)}</dc:description>');
    }
    buffer.writeln('    <meta property="dcterms:modified">${DateTime.now().toIso8601String().split('.').first}Z</meta>');
    buffer.writeln('  </metadata>');
    buffer.writeln('  <manifest>');
    buffer.writeln('    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>');
    buffer.writeln('    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>');
    buffer.writeln('    <item id="css" href="styles/styles.css" media-type="text/css"/>');

    // Cover
    if (project.coverPath != null) {
      final ext = p.extension(project.coverPath!);
      final mediaType = ext == '.png' ? 'image/png' : 'image/jpeg';
      buffer.writeln('    <item id="cover" href="images/cover$ext" media-type="$mediaType" properties="cover-image"/>');
    }

    // Images
    for (final chapter in project.chapters) {
      for (final block in chapter.blocks) {
        if (block.type == BlockType.image && block.imagePath != null) {
          final name = p.basename(block.imagePath!);
          final ext = p.extension(block.imagePath!);
          final mediaType = ext == '.png' ? 'image/png' : 'image/jpeg';
          buffer.writeln('    <item id="img_${_escapeXml(name)}" href="images/$name" media-type="$mediaType"/>');
        }
      }
    }

    // Chapters
    for (var i = 0; i < project.chapters.length; i++) {
      buffer.writeln('    <item id="chapter_${i + 1}" href="chapters/chapter_${i + 1}.xhtml" media-type="application/xhtml+xml"/>');
    }

    buffer.writeln('  </manifest>');
    buffer.writeln('  <spine toc="ncx">');
    for (var i = 0; i < project.chapters.length; i++) {
      buffer.writeln('    <itemref idref="chapter_${i + 1}"/>');
    }
    buffer.writeln('  </spine>');
    buffer.writeln('</package>');

    return buffer.toString();
  }

  String _buildNavXhtml(BookProject project) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">');
    buffer.writeln('<head>');
    buffer.writeln('  <title>目录</title>');
    buffer.writeln('  <link rel="stylesheet" type="text/css" href="styles/styles.css"/>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('  <nav epub:type="toc" id="toc">');
    buffer.writeln('    <h1>目录</h1>');
    buffer.writeln('    <ol>');
    for (var i = 0; i < project.chapters.length; i++) {
      final chapter = project.chapters[i];
      buffer.writeln('      <li><a href="chapters/chapter_${i + 1}.xhtml">${_escapeXml(chapter.title)}</a></li>');
    }
    buffer.writeln('    </ol>');
    buffer.writeln('  </nav>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');
    return buffer.toString();
  }

  String _buildTocNcx(BookProject project) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">');
    buffer.writeln('  <head>');
    buffer.writeln('    <meta name="dtb:uid" content="${project.metadata.isbn ?? project.id}"/>');
    buffer.writeln('    <meta name="dtb:depth" content="1"/>');
    buffer.writeln('    <meta name="dtb:totalPageCount" content="0"/>');
    buffer.writeln('    <meta name="dtb:maxPageNumber" content="0"/>');
    buffer.writeln('  </head>');
    buffer.writeln('  <docTitle><text>${_escapeXml(project.title)}</text></docTitle>');
    buffer.writeln('  <navMap>');
    for (var i = 0; i < project.chapters.length; i++) {
      final chapter = project.chapters[i];
      buffer.writeln('    <navPoint id="navPoint${i + 1}" playOrder="${i + 1}">');
      buffer.writeln('      <navLabel><text>${_escapeXml(chapter.title)}</text></navLabel>');
      buffer.writeln('      <content src="chapters/chapter_${i + 1}.xhtml"/>');
      buffer.writeln('    </navPoint>');
    }
    buffer.writeln('  </navMap>');
    buffer.writeln('</ncx>');
    return buffer.toString();
  }

  String _buildChapterXhtml(Chapter chapter, int index, List<String> imageNames) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html xmlns="http://www.w3.org/1999/xhtml">');
    buffer.writeln('<head>');
    buffer.writeln('  <title>${_escapeXml(chapter.title)}</title>');
    buffer.writeln('  <link rel="stylesheet" type="text/css" href="../styles/styles.css"/>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('  <h1>${_escapeXml(chapter.title)}</h1>');

    for (final block in chapter.blocks) {
      if (block.type == BlockType.text && block.textContent != null) {
        buffer.writeln('  <p>${_escapeXml(block.textContent!)}</p>');
      } else if (block.type == BlockType.image && block.imagePath != null) {
        final fileName = p.basename(block.imagePath!);
        buffer.writeln('  <div class="image-block">');
        buffer.writeln('    <img src="../images/$fileName" alt="image"/>');
        buffer.writeln('  </div>');
      }
    }

    buffer.writeln('</body>');
    buffer.writeln('</html>');
    return buffer.toString();
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
