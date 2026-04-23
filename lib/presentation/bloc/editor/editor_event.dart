import 'package:equatable/equatable.dart';
import '../../../data/models/chapter.dart';
import '../../../data/models/content_block.dart';

abstract class EditorEvent extends Equatable {
  const EditorEvent();

  @override
  List<Object?> get props => [];
}

class LoadProject extends EditorEvent {
  final String projectId;

  const LoadProject(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

class SaveProject extends EditorEvent {}

class AddChapter extends EditorEvent {
  final String title;

  const AddChapter(this.title);

  @override
  List<Object?> get props => [title];
}

class DeleteChapter extends EditorEvent {
  final String chapterId;

  const DeleteChapter(this.chapterId);

  @override
  List<Object?> get props => [chapterId];
}

class RenameChapter extends EditorEvent {
  final String chapterId;
  final String newTitle;

  const RenameChapter(this.chapterId, this.newTitle);

  @override
  List<Object?> get props => [chapterId, newTitle];
}

class ReorderChapters extends EditorEvent {
  final int oldIndex;
  final int newIndex;

  const ReorderChapters(this.oldIndex, this.newIndex);

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

class SelectChapter extends EditorEvent {
  final String chapterId;

  const SelectChapter(this.chapterId);

  @override
  List<Object?> get props => [chapterId];
}

class UpdateChapterContent extends EditorEvent {
  final String chapterId;
  final List<ContentBlock> blocks;

  const UpdateChapterContent(this.chapterId, this.blocks);

  @override
  List<Object?> get props => [chapterId, blocks];
}

class InsertImage extends EditorEvent {
  final String chapterId;
  final String imagePath;
  final int? imageWidth;
  final int? imageHeight;

  const InsertImage({
    required this.chapterId,
    required this.imagePath,
    this.imageWidth,
    this.imageHeight,
  });

  @override
  List<Object?> get props => [chapterId, imagePath, imageWidth, imageHeight];
}

class DeleteBlock extends EditorEvent {
  final String chapterId;
  final String blockId;

  const DeleteBlock(this.chapterId, this.blockId);

  @override
  List<Object?> get props => [chapterId, blockId];
}

class MoveBlock extends EditorEvent {
  final String chapterId;
  final String blockId;
  final int direction; // -1 = up, 1 = down

  const MoveBlock(this.chapterId, this.blockId, this.direction);

  @override
  List<Object?> get props => [chapterId, blockId, direction];
}

class UpdateMetadata extends EditorEvent {
  final String? title;
  final String? author;
  final String? coverPath;

  const UpdateMetadata({this.title, this.author, this.coverPath});

  @override
  List<Object?> get props => [title, author, coverPath];
}
