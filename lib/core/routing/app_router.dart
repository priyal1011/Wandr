import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/presentation/pages/onboarding_screen.dart';
import '../../features/onboarding/presentation/pages/splash_screen.dart';
import '../../features/home/presentation/pages/home_screen.dart';
import '../../features/trip/presentation/pages/trip_detail_screen.dart';
import '../../features/trip/presentation/pages/trip_create_edit_screen.dart';
import '../../features/memories/presentation/pages/memory_detail_screen.dart';
import '../../features/trip/presentation/pages/trips_list_screen.dart';
import '../../core/widgets/main_scaffold.dart';
import '../../core/in_memory_store.dart';
import '../../main.dart';
import '../../features/memories/presentation/pages/memories_screen.dart';
import '../../features/settings/presentation/pages/settings_screen.dart';
import '../../features/settings/presentation/pages/edit_profile_screen.dart';
import '../../features/settings/presentation/pages/avatar_studio_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    // 1. SHELL ROUTES (Screens with Bottom Navigation)
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => NoTransitionPage(
            key: ValueKey(state.uri.toString()),
            child: const HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/stats',
          pageBuilder: (context, state) => NoTransitionPage(
            key: ValueKey(state.uri.toString()),
            child: const Center(child: Text('Stats Coming Soon')),
          ),
        ),
        GoRoute(
          path: '/memories',
          pageBuilder: (context, state) => NoTransitionPage(
            key: ValueKey(state.uri.toString()),
            child: const MemoriesScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => NoTransitionPage(
            key: ValueKey(state.uri.toString()),
            child: const SettingsScreen(),
          ),
        ),
      ],
    ),

    // 2. FULL SCREEN ROUTES (Screens WITHOUT Bottom Navigation)
    GoRoute(
      path: '/create-trip',
      builder: (context, state) => const TripCreateEditScreen(),
    ),
    GoRoute(
      path: '/edit-trip/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return TripCreateEditScreen(tripId: id);
      },
    ),
    GoRoute(
      path: '/trip/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        return NoTransitionPage(
          key: ValueKey('trip_detail_$id'), // Unique key for each trip
          child: TripDetailScreen(tripId: id),
        );
      },
    ),
    GoRoute(
      path: '/memory/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        final fromTrip = state.uri.queryParameters['fromTrip'] == 'true';
        final store = getIt<InMemoryStore>();
        final photo = store.photos.firstWhere((p) => p.id == id);
        return MaterialPage(
          key: state.pageKey,
          fullscreenDialog: true,
          child: MemoryDetailScreen(photo: photo, showViewTrip: !fromTrip),
        );
      },
    ),
    GoRoute(
      path: '/trips/upcoming',
      builder: (context, state) => const TripsListScreen(isUpcoming: true),
    ),
    GoRoute(
      path: '/trips/past',
      builder: (context, state) => const TripsListScreen(isUpcoming: false),
    ),
    GoRoute(
      path: '/settings/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/settings/avatar-studio',
      builder: (context, state) => const AvatarStudioScreen(),
    ),
  ],
);
