import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/chapter.dart';
import '../../../data/models/content_block.dart';
import '../../../data/repositories/project_repository.dart';
import '../../../core/constants/app_dimensions.dart';
import 'editor_event.dart';
import 'editor_state.dart';

class EditorBloc extends Bloc<EditorEvent, EditorState> {
  final ProjectRepository _repository;
  final _uuid = const Uuid();
  Timer? _autoSaveTimer;

  EditorBloc({required ProjectRepository repository})
      : _repository = repository,
        super(EditorInitial()) {
    on<LoadProject>(_onLoadProject);
    on<SaveProject>(_onSaveProject);
    on<AddChapter>(_onAddChapter);
    on<DeleteChapter>(_onDeleteChapter);
    on<RenameChapter>(_onRenameChapter);
    on<ReorderChapters>(_onReorderChapters);
    on<SelectChapter>(_onSelectChapter);
    on<UpdateChapterContent>(_onUpdateChapterContent);
    on<InsertImage>(_onInsertImage);
    on<DeleteBlock>(_onDeleteBlock);
    on<MoveBlock>(_onMoveBlock);
    on<UpdateMetadata>(_onUpdateMetadata);
  }

  @override
  Future<void> close() {
    _autoSaveTimer?.cancel();
    return super.close();
  }

  void _startAutoSaveTimer() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(
      const Duration(seconds: AppDimensions.autoSaveInterval),
      () => add(SaveProject()),
    );
  }

  Future<void> _onLoadProject(
    LoadProject event,
    Emitter<EditorState> emit,
  ) async {
    emit(EditorLoading());
    try {
      final project = await _repository.getProjectById(event.projectId);
      if (project == null) {
        emit(const EditorError('Project not found'));
        return;
      }
      final selectedId = project.chapters.isNotEmpty ? project.chapters.first.id : null;
      emit(EditorLoaded(
        project: project,
        selectedChapterId: selectedId,
        lastSaved: DateTime.now(),
      ));
    } catch (e) {
      emit(EditorError(e.toString()));
    }
  }

  Future<void> _onSaveProject(
    SaveProject event,
    Emitter<EditorState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EditorLoaded) return;

    try {
      final updatedProject = currentState.project.copyWith(
        updatedAt: DateTime.now(),
      );
      await _repository.saveProject(updatedProject);
      emit(currentState.copyWith(
        project: updatedProject,
        hasUnsavedChanges: false,
        lastSaved: DateTime.now(),
      ));
    } catch (e) {
      emit(EditorError(e.toString()));
    }
  }

  Future<void> _onAddChapter(
    AddChapter event,
    Emitter<EditorState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EditorLoaded) return;

    final newChapter = Chapter(
      id: _uuid.v4(),
      title: event.title,
      blocks: [],
    );

    final updatedChapters = [...currentState.project.chapters, newChapter];
    final updatedProject = currentState.project.copyWith(chapters: updatedChapters);

    emit(currentState.copyWith(
      project: updatedProject,
      selectedChapterId: newChapter.id,
      hasUnsavedChanges: true,
    ));
    _startAutoSaveTimer();
  }

  Future<void> _onDeleteChapter(
    DeleteChapter event,
    Emitter<EditorState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EditorLoaded) return;

    final updatedChapters = currentState.project.chapters
        .where((c) => c.id != event.chapterId)
        .toList();

    String? newSelectedId = currentState.selectedChapterId;
    if (newSelectedId == event.chapterId) {
      newSelectedId = updatedChapters.isNotEmpty ? updatedChapters.first.id : null;
    }

    final updatedProject = currentState.project.copyWith(chapters: updatedChapters);

    emit(currentState.copyWith(
      project: updatedProject,
      selectedChapterId: newSelectedId,
      hasUnsavedChanges: true,
    ));
    _startAutoSaveTimer();
  }

  Future<void> _onRenameChapter(
    RenameChapter event,
    Emitter<EditorState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EditorLoaded) return;

    final updatedChapters = currentState.project.chapters.map((c) {
      if (c.id == event.chapterId) {
        return c.copyWith(title: event.newTitle);
      }
      return c;
    }).toList();

    final updatedProject = currentState.project.copyWith(chapters: updatedChapters);

    emit(currentState.copyWith(
      project: updatedProject,
      hasUnsavedChanges: true,
    ));
    _startAutoSaveTimer();
  }

  Future<void> _onReorderChapters(
    ReorderChapters event,
    Emitter<EditorState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EditorLoaded) return;

    final chapters = List<Chapter>.from(currentState.project.chapters);
    final chapter = chapters.removeAt(event.oldIndex);
    chapters.insert(event.newIndex, chapter);

    final updatedProject = currentState.project.copyWith(chapters: chapters);

    emit(currentState.copyWith(
      project: updatedProject,
      hasUnsavedChanges: true,
    ));
    _startAutoSaveTimer();
  }

  Future<void> _onSelectChapter(
    SelectChapter event,
    Emitter<EditorState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EditorLoaded) return;

    emit(currentState.copyWith(selectedChapterId: event.chapterId));
  }

  Future<void> _onUpdateChapterContent(
    UpdateChapterContent event,
    Emitter<EditorState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EditorLoaded) return;

    final updatedChapters = currentState.project.chapters.map((c) {
      if (c.id == event.chapterId) {
        return c.copyWith(blocks: event.blocks);
      }
      return c;
    }).toList();

    final updatedProject = currentState.project.copyWith(chapters: updatedChapters);

    emit(currentState.copyWith(
      project: updatedProject,
      hasUnsavedChanges: true,
    ));
    _startAutoSaveTimer();
  }

  Future<void> _onInsertImage(
    InsertImage event,
    Emitter<EditorState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EditorLoaded) return;

    final newBlock = ContentBlock.image(
      id: _uuid.v4(),
      imagePath: event.imagePath,
      imageWidth: event.imageWidth,
      imageHeight: event.imageHeight,
    );

    final updatedChapters = currentState.project.chapters.map((c) {
      if (c.id == event.chapterId) {
        return c.copyWith(blocks: [...c.blocks, newBlock]);
      }
      return c;
    }).toList();

    final updatedProject = currentState.project.copyWith(chapters: updatedChapters);

    emit(currentState.copyWith(
      project: updatedProject,
      hasUnsavedChanges: true,
    ));
    _startAutoSaveTimer();
  }

  Future<void> _onDeleteBlock(
    DeleteBlock event,
    Emitter<EditorState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EditorLoaded) return;

    final updatedChapters = currentState.project.chapters.map((c) {
      if (c.id == event.chapterId) {
        return c.copyWith(
          blocks: c.blocks.where((b) => b.id != event.blockId).toList(),
        );
      }
      return c;
    }).toList();

    final updatedProject = currentState.project.copyWith(chapters: updatedChapters);

    emit(currentState.copyWith(
      project: updatedProject,
      hasUnsavedChanges: true,
    ));
    _startAutoSaveTimer();
  }

  Future<void> _onMoveBlock(
    MoveBlock event,
    Emitter<EditorState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EditorLoaded) return;

    final updatedChapters = currentState.project.chapters.map((c) {
      if (c.id == event.chapterId) {
        final blocks = List<ContentBlock>.from(c.blocks);
        final index = blocks.indexWhere((b) => b.id == event.blockId);
        if (index == -1) return c;

        final newIndex = index + event.direction;
        if (newIndex < 0 || newIndex >= blocks.length) return c;

        final block = blocks.removeAt(index);
        blocks.insert(newIndex, block);
        return c.copyWith(blocks: blocks);
      }
      return c;
    }).toList();

    final updatedProject = currentState.project.copyWith(chapters: updatedChapters);

    emit(currentState.copyWith(
      project: updatedProject,
      hasUnsavedChanges: true,
    ));
    _startAutoSaveTimer();
  }

  Future<void> _onUpdateMetadata(
    UpdateMetadata event,
    Emitter<EditorState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EditorLoaded) return;

    final updatedProject = currentState.project.copyWith(
      title: event.title ?? currentState.project.title,
      author: event.author ?? currentState.project.author,
      coverPath: event.coverPath ?? currentState.project.coverPath,
    );

    emit(currentState.copyWith(
      project: updatedProject,
      hasUnsavedChanges: true,
    ));
    _startAutoSaveTimer();
  }
}
