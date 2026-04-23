import 'package:equatable/equatable.dart';

class EpubMetadata extends Equatable {
  final String? language;
  final String? publisher;
  final String? description;
  final String? isbn;
  final List<String> tags;

  const EpubMetadata({
    this.language,
    this.publisher,
    this.description,
    this.isbn,
    this.tags = const [],
  });

  EpubMetadata copyWith({
    String? language,
    String? publisher,
    String? description,
    String? isbn,
    List<String>? tags,
  }) {
    return EpubMetadata(
      language: language ?? this.language,
      publisher: publisher ?? this.publisher,
      description: description ?? this.description,
      isbn: isbn ?? this.isbn,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'publisher': publisher,
      'description': description,
      'isbn': isbn,
      'tags': tags,
    };
  }

  factory EpubMetadata.fromJson(Map<String, dynamic> json) {
    return EpubMetadata(
      language: json['language'] as String?,
      publisher: json['publisher'] as String?,
      description: json['description'] as String?,
      isbn: json['isbn'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  factory EpubMetadata.empty() {
    return const EpubMetadata(
      language: 'zh-CN',
      publisher: null,
      description: null,
      isbn: null,
      tags: [],
    );
  }

  @override
  List<Object?> get props => [language, publisher, description, isbn, tags];
}
