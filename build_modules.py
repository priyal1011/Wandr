import os

files = {
    "lib/features/trip/presentation/cubit/trip_cubit.dart": """import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/in_memory_store.dart';
import '../../../../main.dart';
import 'package:equatable/equatable.dart';

abstract class TripState {}
class TripInitial extends TripState {}
class TripLoading extends TripState {}
class TripLoaded extends TripState {
  final TripModel trip;
  TripLoaded(this.trip);
}
class TripError extends TripState {
  final String message;
  TripError(this.message);
}

class TripCubit extends Cubit<TripState> {
  TripCubit() : super(TripInitial());

  void loadTrip(String id) {
    final store = getIt<InMemoryStore>();
    final trip = store.trips.firstWhere((t) => t.id == id, orElse: () => throw Exception('Trip not found'));
    emit(TripLoaded(trip));
  }
}""",
    "lib/features/trip/presentation/pages/trip_create_edit_screen.dart": """import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TripCreateEditScreen extends StatelessWidget {
  final String? tripId;
  const TripCreateEditScreen({super.key, this.tripId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tripId == null ? 'Create Trip' : 'Edit Trip')),
      body: Center(child: ElevatedButton(
        child: const Text('Save Trip'),
        onPressed: () => context.go('/home'),
      )),
    );
  }
}""",
    "lib/features/trip/presentation/pages/trip_detail_screen.dart": """import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TripDetailScreen extends StatelessWidget {
  final String tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Detail'),
      actions: [IconButton(icon: const Icon(Icons.edit), onPressed: () => context.push('/trip/$tripId/edit'))]),
      body: const Center(child: Text('Trip Tabs (Itinerary, Budget, Photos, Map)')),
    );
  }
}""",
    "lib/features/settings/presentation/pages/settings_screen.dart": """import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/in_memory_store.dart';
import '../../../../main.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(title: const Text('Edit Profile'), onTap: () => context.push('/settings/edit-profile')),
          ListTile(title: const Text('Change Password'), onTap: () => context.push('/settings/change-password')),
          ListTile(title: const Text('Logout'), onTap: () {
            getIt<InMemoryStore>().currentUser = null;
            context.go('/login');
          }),
        ],
      ),
    );
  }
}""",
    "lib/features/settings/presentation/pages/edit_profile_screen.dart": """import 'package:flutter/material.dart';
class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Edit Profile')));
  }
}""",
    "lib/features/settings/presentation/pages/change_password_screen.dart": """import 'package:flutter/material.dart';
class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Change Password')));
  }
}""",
    "lib/features/all_places/presentation/pages/all_places_screen.dart": """import 'package:flutter/material.dart';
class AllPlacesScreen extends StatelessWidget {
  const AllPlacesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('All Places')));
  }
}""",
    "lib/core/routing/app_router.dart": """import 'package:go_router/go_router.dart';
import '../../features/onboarding/presentation/pages/onboarding_screen.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/pages/signup_screen.dart';
import '../../features/home/presentation/pages/home_screen.dart';
import '../../features/trip/presentation/pages/trip_create_edit_screen.dart';
import '../../features/trip/presentation/pages/trip_detail_screen.dart';
import '../../features/settings/presentation/pages/settings_screen.dart';
import '../../features/settings/presentation/pages/edit_profile_screen.dart';
import '../../features/settings/presentation/pages/change_password_screen.dart';
import '../../features/all_places/presentation/pages/all_places_screen.dart';
import '../in_memory_store.dart';
import '../../main.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final store = getIt<InMemoryStore>();
    final hasSeenOnboarding = store.hasSeenOnboarding;
    final isLoggedIn = store.currentUser != null;

    final isLoginRoute = state.uri.path == '/login' || state.uri.path == '/signup';
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
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/trip/create', builder: (context, state) => const TripCreateEditScreen()),
    GoRoute(path: '/trip/:id/edit', builder: (context, state) => TripCreateEditScreen(tripId: state.pathParameters['id'])),
    GoRoute(path: '/trip/:id', builder: (context, state) => TripDetailScreen(tripId: state.pathParameters['id']!)),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    GoRoute(path: '/settings/edit-profile', builder: (context, state) => const EditProfileScreen()),
    GoRoute(path: '/settings/change-password', builder: (context, state) => const ChangePasswordScreen()),
    GoRoute(path: '/all-places', builder: (context, state) => const AllPlacesScreen()),
  ],
);"""
}

for filepath, content in files.items():
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
print("Files generated!")
