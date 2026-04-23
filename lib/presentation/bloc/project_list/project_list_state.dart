import 'package:equatable/equatable.dart';
import '../../../data/models/book_project.dart';

abstract class ProjectListState extends Equatable {
  const ProjectListState();

  @override
  List<Object?> get props => [];
}

class ProjectListInitial extends ProjectListState {}

class ProjectListLoading extends ProjectListState {}

class ProjectListLoaded extends ProjectListState {
  final List<BookProject> projects;

  const ProjectListLoaded(this.projects);

  @override
  List<Object?> get props => [projects];
}

class ProjectListError extends ProjectListState {
  final String message;

  const ProjectListError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProjectCreated extends ProjectListState {
  final BookProject project;

  const ProjectCreated(this.project);

  @override
  List<Object?> get props => [project];
}
