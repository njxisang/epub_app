import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/pages/home_page.dart';
import '../../presentation/pages/editor_page.dart';
import '../../presentation/pages/preview_page.dart';
import '../../presentation/pages/export_page.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/editor/:projectId',
        name: 'editor',
        builder: (context, state) {
          final projectId = state.pathParameters['projectId']!;
          return EditorPage(projectId: projectId);
        },
      ),
      GoRoute(
        path: '/preview/:projectId',
        name: 'preview',
        builder: (context, state) {
          final projectId = state.pathParameters['projectId']!;
          return PreviewPage(projectId: projectId);
        },
      ),
      GoRoute(
        path: '/export/:projectId',
        name: 'export',
        builder: (context, state) {
          final projectId = state.pathParameters['projectId']!;
          return ExportPage(projectId: projectId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
}
