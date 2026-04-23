import 'package:get_it/get_it.dart';
import 'data/datasources/file_storage.dart';
import 'data/repositories/project_repository.dart';
import 'domain/services/image_service.dart';
import 'domain/services/epub_builder.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Data sources
  getIt.registerLazySingleton<FileStorage>(() => FileStorage());

  // Repositories
  getIt.registerLazySingleton<ProjectRepository>(
    () => ProjectRepository(
      fileStorage: getIt<FileStorage>(),
    ),
  );

  // Services
  getIt.registerLazySingleton<ImageService>(() => ImageService());
  getIt.registerLazySingleton<EpubBuilder>(() => EpubBuilder());
}
