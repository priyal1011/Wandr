import 'package:go_router/go_router.dart';
import '../../features/onboarding/presentation/pages/onboarding_screen.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/pages/signup_screen.dart';
import '../../features/home/presentation/pages/home_screen.dart';
import '../../features/trip/presentation/pages/trip_create_edit_screen.dart';
import '../../features/trip/presentation/pages/trip_detail_screen.dart';
import '../../features/settings/presentation/pages/settings_screen.dart';
import '../../features/settings/presentation/pages/edit_profile_screen.dart';
import '../../features/trip/presentation/pages/trips_list_screen.dart';

import '../widgets/main_scaffold.dart';
import '../../features/auth/presentation/pages/forgot_password_screen.dart';
import '../../features/memories/presentation/pages/memories_screen.dart';
import '../in_memory_store.dart';
import '../../main.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final store = getIt<InMemoryStore>();
    final hasSeenOnboarding = store.hasSeenOnboarding;
    final isLoggedIn = store.currentUser != null;

    final isLoginRoute = state.uri.path == '/login' || state.uri.path == '/signup' || state.uri.path == '/forgot-password';
    final isOnboardingRoute = state.uri.path == '/onboarding';

    if (!hasSeenOnboarding && !isOnboardingRoute) return '/onboarding';
    if (hasSeenOnboarding && !isLoggedIn && !isLoginRoute) return '/login';
    if (isLoggedIn && (isLoginRoute || isOnboardingRoute)) return '/home';
    if (state.uri.path == '/') return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
    GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
    
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(path: '/memories', builder: (context, state) => const MemoriesScreen()),
        GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      ],
    ),
    
    // Sub-screens (no bottom bar)
    GoRoute(path: '/trip/create', builder: (context, state) => const TripCreateEditScreen()),
    GoRoute(path: '/trip/:id/edit', builder: (context, state) => TripCreateEditScreen(tripId: state.pathParameters['id'])),
    GoRoute(path: '/trip/:id', builder: (context, state) => TripDetailScreen(tripId: state.pathParameters['id']!)),
    GoRoute(path: '/settings/edit-profile', builder: (context, state) => const EditProfileScreen()),
    
    // Trip Lists
    GoRoute(path: '/trips/upcoming', builder: (context, state) => const TripsListScreen(isUpcoming: true)),
    GoRoute(path: '/trips/past', builder: (context, state) => const TripsListScreen(isUpcoming: false)),
    
    GoRoute(path: '/all-places', builder: (context, state) => const MemoriesScreen()),
  ],
);