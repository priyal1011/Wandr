import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttermoji/fluttermoji.dart';
import '../../../../core/in_memory_store.dart';
import '../../../../main.dart';
import '../../../../models/trip_model.dart';
import '../../../../models/user_model.dart';
import '../../../../theme/app_theme.dart';
import 'package:skeletonizer/skeletonizer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = getIt<InMemoryStore>();

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final user = store.currentUser;
        final trips = store.trips;

        final now = DateTime.now();
        final upcomingTrips = trips
            .where((t) => !t.endDate.isBefore(now))
            .toList();
        final pastTrips = trips.where((t) => t.endDate.isBefore(now)).toList();

        return Scaffold(
          body: Skeletonizer(
            enabled: trips.isEmpty && user == null,
            child: CustomScrollView(
              slivers: [
                _HomeAppBar(user: user),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: _StatsBoard(
                                tripCount: trips.length,
                                placeCount: trips.fold<int>(
                                  0,
                                  (sum, t) =>
                                      sum +
                                      (t.itinerary == null
                                          ? 0
                                          : t.itinerary!.fold<int>(
                                              0,
                                              (s, d) => s + d.places.length,
                                            )),
                                ),
                                photoCount: trips.fold<int>(
                                  0,
                                  (sum, t) => sum + (t.photos?.length ?? 0),
                                ),
                                currency: store.currentCurrency,
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .slideY(begin: 0.1, end: 0),
                        const Gap(24),
                        _SectionHeader(
                          title: 'Upcoming Adventures',
                          onSeeAll: () => context.push('/trips/upcoming'),
                        ),
                        const Gap(12),
                        _UpcomingHorizontalList(trips: upcomingTrips),
                        const Gap(24),
                        _SectionHeader(
                          title: 'Memorable Journeys',
                          onSeeAll: () => context.push('/trips/past'),
                        ),
                        const Gap(12),
                        _PastJourneysCarousel(
                          trips: pastTrips.take(5).toList(),
                        ),
                        const Gap(100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HomeAppBar extends StatelessWidget {
  final UserModel? user;
  const _HomeAppBar({this.user});

  Widget _getAvatar(BuildContext context) {
    if (user?.photoUrl != null && user!.photoUrl!.isNotEmpty) {
      final photoUrl = user!.photoUrl!;
      final image = photoUrl.startsWith('http')
          ? NetworkImage(photoUrl)
          : FileImage(File(photoUrl)) as ImageProvider;
      return CircleAvatar(radius: 20, backgroundImage: image);
    }

    return FluttermojiCircleAvatar(
      radius: 20,
      backgroundColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${user?.name ?? 'Explorer'}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'WANDR'.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => context.push('/settings'),
              child: Hero(
                tag: 'profile_avatar',
                child: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  child: _getAvatar(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;
  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              'See All',
              style: TextStyle(
                color: AppTheme.accentCyan,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingHorizontalList extends StatelessWidget {
  final List<TripModel> trips;
  const _UpcomingHorizontalList({required this.trips});

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 200,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: trips.length,
        separatorBuilder: (context, index) => const Gap(16),
        itemBuilder: (context, index) {
          final trip = trips[index];
          return GestureDetector(
            onTap: () => context.push('/trip/${trip.id}'),
            child: Hero(
              tag: 'trip_cover_${trip.id}',
              child: Container(
                width: 280,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background Image
                    trip.coverPhoto != null && trip.coverPhoto!.isNotEmpty
                        ? (trip.coverPhoto!.startsWith('http')
                              ? Image.network(
                                  trip.coverPhoto!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) =>
                                      Container(color: Colors.grey.shade900),
                                )
                              : Image.file(
                                  File(trip.coverPhoto!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) =>
                                      Container(color: Colors.grey.shade900),
                                ))
                        : Container(color: Colors.grey.shade900),

                    // Dark Gradient Overlay
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            trip.destination,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.2);
        },
      ),
    );
  }
}

class _PastJourneysCarousel extends StatelessWidget {
  final List<TripModel> trips;
  const _PastJourneysCarousel({required this.trips});

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 40,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.2),
              ),
              const Gap(12),
              Text(
                "Your first adventure awaits!",
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.3),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: trips.length,
        separatorBuilder: (context, index) => const Gap(12),
        itemBuilder: (context, index) {
          final trip = trips[index];
          return GestureDetector(
            onTap: () => context.push('/trip/${trip.id}'),
            child: Container(
              width: 240,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        trip.coverPhoto != null && trip.coverPhoto!.isNotEmpty
                        ? (trip.coverPhoto!.startsWith('http')
                              ? Image.network(
                                  trip.coverPhoto!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey.shade300,
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 20,
                                    ),
                                  ),
                                )
                              : Image.file(
                                  File(trip.coverPhoto!),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey.shade300,
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 20,
                                    ),
                                  ),
                                ))
                        : Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey.shade300,
                            child: const Icon(
                              Icons.image_outlined,
                              size: 20,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          DateFormat('MMM yyyy').format(trip.startDate),
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.2);
        },
      ),
    ).animate().fadeIn();
  }
}

class _StatsBoard extends StatelessWidget {
  final int tripCount;
  final int photoCount;
  final int placeCount;
  final String currency;

  const _StatsBoard({
    required this.tripCount,
    required this.photoCount,
    required this.placeCount,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: 'Trips',
            value: tripCount.toString(),
            icon: Icons.map_outlined,
            color: AppTheme.accentCyan,
          ),
          _StatItem(
            label: 'Places',
            value: placeCount.toString(),
            icon: Icons.location_on_outlined,
            color: AppTheme.accentBlue,
          ),
          _StatItem(
            label: 'Photos',
            value: photoCount.toString(),
            icon: Icons.photo_library_outlined,
            color: AppTheme.accentEmerald,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const Gap(12),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.4),
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
