import 'package:equatable/equatable.dart';

enum BlockType { text, image }

class ContentBlock extends Equatable {
  final String id;
  final BlockType type;
  final String? textContent;
  final String? imagePath;
  final int? imageWidth;
  final int? imageHeight;

  const ContentBlock({
    required this.id,
    required this.type,
    this.textContent,
    this.imagePath,
    this.imageWidth,
    this.imageHeight,
  });

  ContentBlock copyWith({
    String? id,
    BlockType? type,
    String? textContent,
    String? imagePath,
    int? imageWidth,
    int? imageHeight,
  }) {
    return ContentBlock(
      id: id ?? this.id,
      type: type ?? this.type,
      textContent: textContent ?? this.textContent,
      imagePath: imagePath ?? this.imagePath,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'textContent': textContent,
      'imagePath': imagePath,
      'imageWidth': imageWidth,
      'imageHeight': imageHeight,
    };
  }

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    return ContentBlock(
      id: json['id'] as String,
      type: BlockType.values.firstWhere((e) => e.name == json['type']),
      textContent: json['textContent'] as String?,
      imagePath: json['imagePath'] as String?,
      imageWidth: json['imageWidth'] as int?,
      imageHeight: json['imageHeight'] as int?,
    );
  }

  factory ContentBlock.text({required String id, required String content}) {
    return ContentBlock(
      id: id,
      type: BlockType.text,
      textContent: content,
    );
  }

  factory ContentBlock.image({
    required String id,
    required String imagePath,
    int? imageWidth,
    int? imageHeight,
  }) {
    return ContentBlock(
      id: id,
      type: BlockType.image,
      imagePath: imagePath,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
  }

  @override
  List<Object?> get props => [id, type, textContent, imagePath, imageWidth, imageHeight];
}
