import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/router/app_router.dart';
import 'package:music_app/core/state_logger.dart';
import 'package:music_app/core/theme/app_theme.dart';

void main() {
  runApp(
    ProviderScope(
      observers: [StateLogger()],
      child: const MusicApp(),
    ),
  );
}

class MusicApp extends ConsumerWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Music App',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
