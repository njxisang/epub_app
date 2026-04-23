import 'package:equatable/equatable.dart';

abstract class ProjectListEvent extends Equatable {
  const ProjectListEvent();

  @override
  List<Object?> get props => [];
}

class LoadProjects extends ProjectListEvent {}

class CreateProject extends ProjectListEvent {
  final String title;
  final String author;

  const CreateProject({required this.title, required this.author});

  @override
  List<Object?> get props => [title, author];
}

class DeleteProject extends ProjectListEvent {
  final String projectId;

  const DeleteProject(this.projectId);

  @override
  List<Object?> get props => [projectId];
}
