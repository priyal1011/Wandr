import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/presentation/pages/onboarding_screen.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/pages/signup_screen.dart';
import '../../features/home/presentation/pages/home_screen.dart';
import '../../features/trip/presentation/pages/trip_create_edit_screen.dart';
import '../../features/trip/presentation/pages/trip_detail_screen.dart';
import '../../features/settings/presentation/pages/settings_screen.dart';
import '../../features/settings/presentation/pages/edit_profile_screen.dart';
import '../../features/memories/presentation/pages/memory_detail_screen.dart';
import '../../features/settings/presentation/pages/avatar_studio_screen.dart';
import '../../features/trip/presentation/pages/trips_list_screen.dart';

import '../widgets/main_scaffold.dart';
import '../../features/auth/presentation/pages/forgot_password_screen.dart';
import '../../features/memories/presentation/pages/memories_screen.dart';
import '../in_memory_store.dart';
import '../../main.dart';
import '../../features/onboarding/presentation/pages/splash_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final store = getIt<InMemoryStore>();
    final hasSeenOnboarding = store.hasSeenOnboarding;
    final isLoggedIn = store.currentUser != null;

    final isLoginRoute =
        state.uri.path == '/login' ||
        state.uri.path == '/signup' ||
        state.uri.path == '/forgot-password';
    final isOnboardingRoute = state.uri.path == '/onboarding';
    final isSplashRoute = state.uri.path == '/splash';

    if (isSplashRoute) return null;
    if (!hasSeenOnboarding && !isOnboardingRoute) return '/onboarding';
    if (hasSeenOnboarding && !isLoggedIn && !isLoginRoute) return '/login';
    if (isLoggedIn && (isLoginRoute || isOnboardingRoute)) return '/home';
    if (state.uri.path == '/') return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),

    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => ListenableBuilder(
            listenable: getIt<InMemoryStore>(),
            builder: (context, _) => const HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/memories',
          builder: (context, state) => const MemoriesScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/trip/create',
          builder: (context, state) => const TripCreateEditScreen(),
        ),
        GoRoute(
          path: '/trip/:id/edit',
          builder: (context, state) =>
              TripCreateEditScreen(tripId: state.pathParameters['id']),
        ),
      ],
    ),

    // Truly full-screen (Destructive/Immersive)
    GoRoute(
      path: '/memory/:photoId',
      builder: (context, state) {
        final photoId = state.pathParameters['photoId'];
        final store = getIt<InMemoryStore>();
        final matches = store.photos.where((p) => p.id == photoId);

        if (matches.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/memories');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return MemoryDetailScreen(photo: matches.first);
      },
    ),
    GoRoute(
      path: '/trip/:id',
      builder: (context, state) =>
          TripDetailScreen(tripId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/settings/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/settings/avatar-studio',
      builder: (context, state) => const AvatarStudioScreen(),
    ),

    // Trip Lists
    GoRoute(
      path: '/trips/upcoming',
      builder: (context, state) => const TripsListScreen(isUpcoming: true),
    ),
    GoRoute(
      path: '/trips/past',
      builder: (context, state) => const TripsListScreen(isUpcoming: false),
    ),

    GoRoute(
      path: '/all-places',
      builder: (context, state) => const MemoriesScreen(),
    ),
  ],
);
