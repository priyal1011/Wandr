import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../../core/in_memory_store.dart';
import '../../../../main.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = getIt<InMemoryStore>();
    final user = store.currentUser;
    final trips = store.trips;
    
    final now = DateTime.now();
    final upcomingTrips = trips.where((t) => !t.endDate.isBefore(now)).toList();
    final pastTrips = trips.where((t) => t.endDate.isBefore(now)).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _HomeAppBar(user: user),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _StatsBoard(
                      tripCount: trips.length,
                      placeCount: trips.fold<int>(0, (sum, t) => sum + (t.itinerary == null ? 0 : t.itinerary!.fold<int>(0, (s, d) => s + d.places.length))),
                      photoCount: trips.fold<int>(0, (sum, t) => sum + (t.photos?.length ?? 0)),
                    ),
                  ),
                  const Gap(24),
                  _SectionHeader(
                    title: 'Upcoming Adventures',
                    onSeeAll: () => context.push('/trips/upcoming'),
                  ),
                  const Gap(12),
                  _UpcomingHorizontalList(trips: upcomingTrips),
                  const Gap(24),
                  _SectionHeader(
                    title: 'Past Journeys',
                    onSeeAll: () => context.push('/trips/past'),
                  ),
                  const Gap(12),
                  _PastVerticalList(trips: pastTrips.take(3).toList()),
                  const Gap(100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeAppBar extends StatelessWidget {
  final UserModel? user;
  const _HomeAppBar({this.user});

  ImageProvider _getAvatarImage(UserModel? user) {
    if (user?.photoUrl == null) return const NetworkImage('https://i.pravatar.cc/150?u=wandr');
    if (user!.photoUrl!.startsWith('http')) return NetworkImage(user.photoUrl!);
    return FileImage(File(user.photoUrl!));
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
                  'Where shall we wandr?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 400.ms),
              ],
            ),
            GestureDetector(
              onTap: () => context.push('/settings'),
              child: Hero(
                tag: 'profile_avatar',
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  backgroundImage: _getAvatarImage(user),
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
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: onSeeAll,
            child: Text('See All', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
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
    if (trips.isEmpty) return _EmptySection(msg: 'No upcoming trips planned.');
    
    return SizedBox(
      height: 280,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          return Container(
            width: 300,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: _TripCard(trip: trip, isHorizontal: true),
          ).animate(delay: Duration(milliseconds: index * 100)).fadeIn(duration: 400.ms).flipH(begin: -0.1, end: 0, duration: 600.ms, curve: Curves.easeOutQuart).slideX(begin: 0.2);
        },
      ),
    );
  }
}

class _PastVerticalList extends StatelessWidget {
  final List<TripModel> trips;
  const _PastVerticalList({required this.trips});

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) return _EmptySection(msg: 'No past journeys yet.');
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: trips.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _TripCard(trip: trips[index]),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String msg;
  const _EmptySection({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Text(msg, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3))),
    );
  }
}

class _TripCard extends StatelessWidget {
  final TripModel trip;
  final bool isHorizontal;
  const _TripCard({required this.trip, this.isHorizontal = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/trip/${trip.id}'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
             ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: trip.coverPhoto != null && !trip.coverPhoto!.startsWith('http')
                    ? Image.file(
                        File(trip.coverPhoto!),
                        width: double.infinity,
                        height: isHorizontal ? 180 : 120,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(height: 180, color: Colors.grey.shade300, child: const Icon(Icons.broken_image, color: Colors.grey)),
                      )
                    : Image.network(
                        trip.coverPhoto ?? 'https://images.unsplash.com/photo-1501785888041-af3ef285b470',
                        width: double.infinity,
                        height: isHorizontal ? 180 : 120,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(height: 180, color: Colors.grey.shade300, child: const Icon(Icons.broken_image, color: Colors.grey)),
                      ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(trip.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Gap(4),
                        Row(
                          children: [
                            Icon(Icons.place_outlined, size: 12, color: Theme.of(context).colorScheme.primary),
                            const Gap(4),
                            Text(trip.destination, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('MMM d').format(trip.startDate),
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('MMM d').format(trip.endDate),
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsBoard extends StatelessWidget {
  final int tripCount;
  final int photoCount;
  final int placeCount;

  const _StatsBoard({required this.tripCount, required this.photoCount, required this.placeCount});

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
          _StatItem(label: 'Trips', value: tripCount.toString(), icon: Icons.map_outlined, color: Colors.indigo),
          _StatItem(label: 'Places', value: placeCount.toString(), icon: Icons.location_on_outlined, color: Colors.teal),
          _StatItem(label: 'Photos', value: photoCount.toString(), icon: Icons.photo_library_outlined, color: Colors.amber),
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

  const _StatItem({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const Gap(12),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: -0.5),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
