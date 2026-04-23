import 'dart:io';
import '../models/book_project.dart';
import '../datasources/local_database.dart';
import '../datasources/file_storage.dart';

class ProjectRepository {
  final LocalDatabase _localDatabase;
  final FileStorage _fileStorage;

  ProjectRepository({
    required LocalDatabase localDatabase,
    required FileStorage fileStorage,
  })  : _localDatabase = localDatabase,
        _fileStorage = fileStorage;

  Future<List<BookProject>> getAllProjects() async {
    return _localDatabase.getAllProjects();
  }

  Future<BookProject?> getProjectById(String id) async {
    // Try file storage first (more up to date)
    final project = await _fileStorage.loadProject(id);
    if (project != null) return project;

    // Fall back to database
    return _localDatabase.getProjectById(id);
  }

  Future<void> saveProject(BookProject project) async {
    // Save to both file storage and database
    await _fileStorage.saveProject(project.id, project);
    await _localDatabase.insertProject(project);
  }

  Future<void> deleteProject(String id) async {
    await _fileStorage.deleteProject(id);
    await _localDatabase.deleteProject(id);
  }

  Future<String> saveImage(String projectId, File imageFile) async {
    return _fileStorage.saveImage(projectId, imageFile);
  }

  Future<String> saveCover(String projectId, File coverFile) async {
    return _fileStorage.saveCover(projectId, coverFile);
  }

  Future<void> deleteImage(String imagePath) async {
    await _fileStorage.deleteImage(imagePath);
  }
}
