import 'package:equatable/equatable.dart';
import '../../../data/models/book_project.dart';
import '../../../data/models/chapter.dart';

abstract class EditorState extends Equatable {
  const EditorState();

  @override
  List<Object?> get props => [];
}

class EditorInitial extends EditorState {}

class EditorLoading extends EditorState {}

class EditorLoaded extends EditorState {
  final BookProject project;
  final String? selectedChapterId;
  final bool hasUnsavedChanges;
  final DateTime? lastSaved;

  const EditorLoaded({
    required this.project,
    this.selectedChapterId,
    this.hasUnsavedChanges = false,
    this.lastSaved,
  });

  EditorLoaded copyWith({
    BookProject? project,
    String? selectedChapterId,
    bool? hasUnsavedChanges,
    DateTime? lastSaved,
  }) {
    return EditorLoaded(
      project: project ?? this.project,
      selectedChapterId: selectedChapterId ?? this.selectedChapterId,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      lastSaved: lastSaved ?? this.lastSaved,
    );
  }

  Chapter? get selectedChapter {
    if (selectedChapterId == null) return null;
    try {
      return project.chapters.firstWhere((c) => c.id == selectedChapterId);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [project, selectedChapterId, hasUnsavedChanges, lastSaved];
}

class EditorError extends EditorState {
  final String message;

  const EditorError(this.message);

  @override
  List<Object?> get props => [message];
}

class EditorSaving extends EditorState {}

class EditorSaved extends EditorState {
  final DateTime savedAt;

  const EditorSaved(this.savedAt);

  @override
  List<Object?> get props => [savedAt];
}
