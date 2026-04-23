import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'injection_container.dart';
import 'data/repositories/project_repository.dart';
import 'domain/services/image_service.dart';

class EpubStudioApp extends StatelessWidget {
  const EpubStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ProjectRepository>(
          create: (_) => getIt<ProjectRepository>(),
        ),
        RepositoryProvider<ImageService>(
          create: (_) => getIt<ImageService>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'EpubStudio',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
