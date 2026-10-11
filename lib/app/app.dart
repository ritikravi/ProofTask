import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/models.dart';
import '../core/storage.dart';
import '../features/challenges/challenge_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/stats/stats_screen.dart';
import '../features/tasks/submit_proof_screen.dart';
import '../features/tasks/task_detail_screen.dart';
import '../features/tasks/task_list_screen.dart';
import '../features/tasks/verdict_screen.dart';
import 'theme.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    redirect: (context, state) {
      final onboarded = ref.read(settingsProvider).onboarded;
      if (!onboarded && state.matchedLocation != '/welcome') return '/welcome';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const TaskListScreen()),
      GoRoute(path: '/welcome', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/stats', builder: (_, _) => const StatsScreen()),
      GoRoute(
        path: '/task/:id',
        builder: (_, s) => TaskDetailScreen(taskId: s.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'submit',
            builder: (_, s) =>
                SubmitProofScreen(taskId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: 'verdict',
            builder: (_, s) => VerdictScreen(
              taskId: s.pathParameters['id']!,
              outcome: s.extra as Outcome?,
            ),
          ),
          GoRoute(
            path: 'challenge',
            builder: (_, s) => ChallengeScreen(taskId: s.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
});

class ReceiptsApp extends ConsumerWidget {
  const ReceiptsApp({super.key, this.theme});

  /// Tests inject a theme that avoids runtime font downloads.
  final ThemeData? theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'ProofTask',
      debugShowCheckedModeBanner: false,
      theme: theme ?? buildTheme(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
