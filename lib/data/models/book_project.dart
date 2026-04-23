import 'package:equatable/equatable.dart';
import 'chapter.dart';
import 'epub_metadata.dart';

enum BlockType { text, image }

class BookProject extends Equatable {
  final String id;
  final String title;
  final String author;
  final String? coverPath;
  final List<Chapter> chapters;
  final EpubMetadata metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BookProject({
    required this.id,
    required this.title,
    required this.author,
    this.coverPath,
    required this.chapters,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  BookProject copyWith({
    String? id,
    String? title,
    String? author,
    String? coverPath,
    List<Chapter>? chapters,
    EpubMetadata? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookProject(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      coverPath: coverPath ?? this.coverPath,
      chapters: chapters ?? this.chapters,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'coverPath': coverPath,
      'chapters': chapters.map((c) => c.toJson()).toList(),
      'metadata': metadata.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory BookProject.fromJson(Map<String, dynamic> json) {
    return BookProject(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      coverPath: json['coverPath'] as String?,
      chapters: (json['chapters'] as List<dynamic>)
          .map((c) => Chapter.fromJson(c as Map<String, dynamic>))
          .toList(),
      metadata: EpubMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  factory BookProject.empty({
    required String id,
    required String title,
    required String author,
  }) {
    final now = DateTime.now();
    return BookProject(
      id: id,
      title: title,
      author: author,
      chapters: [
        Chapter(id: id, title: '第一章', blocks: []),
      ],
      metadata: EpubMetadata.empty(),
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  List<Object?> get props => [id, title, author, coverPath, chapters, metadata, createdAt, updatedAt];
}
