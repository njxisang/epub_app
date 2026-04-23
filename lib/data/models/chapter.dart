import 'package:equatable/equatable.dart';
import 'content_block.dart';

class Chapter extends Equatable {
  final String id;
  final String title;
  final List<ContentBlock> blocks;

  const Chapter({
    required this.id,
    required this.title,
    required this.blocks,
  });

  Chapter copyWith({
    String? id,
    String? title,
    List<ContentBlock>? blocks,
  }) {
    return Chapter(
      id: id ?? this.id,
      title: title ?? this.title,
      blocks: blocks ?? this.blocks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'blocks': blocks.map((b) => b.toJson()).toList(),
    };
  }

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] as String,
      title: json['title'] as String,
      blocks: (json['blocks'] as List<dynamic>)
          .map((b) => ContentBlock.fromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, title, blocks];
}
