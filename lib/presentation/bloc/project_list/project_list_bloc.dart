import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/book_project.dart';
import '../../../data/repositories/project_repository.dart';
import 'project_list_event.dart';
import 'project_list_state.dart';

class ProjectListBloc extends Bloc<ProjectListEvent, ProjectListState> {
  final ProjectRepository _repository;
  final _uuid = const Uuid();

  ProjectListBloc({required ProjectRepository repository})
      : _repository = repository,
        super(ProjectListInitial()) {
    on<LoadProjects>(_onLoadProjects);
    on<CreateProject>(_onCreateProject);
    on<DeleteProject>(_onDeleteProject);
  }

  Future<void> _onLoadProjects(
    LoadProjects event,
    Emitter<ProjectListState> emit,
  ) async {
    emit(ProjectListLoading());
    try {
      final projects = await _repository.getAllProjects();
      emit(ProjectListLoaded(projects));
    } catch (e) {
      emit(ProjectListError(e.toString()));
    }
  }

  Future<void> _onCreateProject(
    CreateProject event,
    Emitter<ProjectListState> emit,
  ) async {
    try {
      final project = BookProject.empty(
        id: _uuid.v4(),
        title: event.title,
        author: event.author,
      );
      await _repository.saveProject(project);
      emit(ProjectCreated(project));
      // Reload the list
      final projects = await _repository.getAllProjects();
      emit(ProjectListLoaded(projects));
    } catch (e) {
      emit(ProjectListError(e.toString()));
    }
  }

  Future<void> _onDeleteProject(
    DeleteProject event,
    Emitter<ProjectListState> emit,
  ) async {
    try {
      await _repository.deleteProject(event.projectId);
      // Reload the list
      final projects = await _repository.getAllProjects();
      emit(ProjectListLoaded(projects));
    } catch (e) {
      emit(ProjectListError(e.toString()));
    }
  }
}
