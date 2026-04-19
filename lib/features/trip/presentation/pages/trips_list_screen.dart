import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/in_memory_store.dart';
import '../../../../main.dart';
import '../../../../core/widgets/wandr_image.dart';
import '../../../../models/trip_model.dart';

class TripsListScreen extends StatelessWidget {
  final bool isUpcoming;
  const TripsListScreen({super.key, required this.isUpcoming});

  @override
  Widget build(BuildContext context) {
    final store = getIt<InMemoryStore>();
    final trips = store.trips;
    final now = DateTime.now();

    final filteredTrips = isUpcoming
        ? trips.where((t) => !t.endDate.isBefore(now)).toList()
        : trips.where((t) => t.endDate.isBefore(now)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isUpcoming ? 'Upcoming Adventures' : 'Past Journeys',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          ListenableBuilder(
            listenable: getIt<InMemoryStore>(),
            builder: (context, _) {
              if (!getIt<InMemoryStore>().isSyncingCloud) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: const Hero(
                    tag: 'sync_indicator',
                    child: Icon(Icons.cloud_sync_outlined, size: 20, color: Colors.lightBlueAccent),
                  ),
                ).animate(onPlay: (c) => c.repeat()).shimmer(duration: const Duration(seconds: 2)),
              );
            },
          ),
        ],
      ),
      body: Skeletonizer(
        enabled: trips
            .isEmpty, // Only show if we have zero data (e.g. initial cloud sync)
        child:
            filteredTrips.isEmpty &&
                trips
                    .isNotEmpty // If not truly empty but filtered is empty
            ? Center(
                child: Text(
                  'No journeys to show here.',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: filteredTrips.isEmpty ? 3 : filteredTrips.length,
                separatorBuilder: (context, index) => const Gap(20),
                itemBuilder: (context, index) {
                  if (filteredTrips.isEmpty) {
                    // Provide a dummy trip for skeleton
                    return _FullTripCard(
                      trip: TripModel(
                        id: '',
                        name: 'Exploring the Unknown',
                        destination: 'Mystery Location',
                        startDate: now,
                        endDate: now,
                        totalBudget: 0,
                        currency: r'$',
                      ),
                    );
                  }
                  final trip = filteredTrips[index];
                  return _FullTripCard(trip: trip);
                },
              ),
      ),
    );
  }
}

class _FullTripCard extends StatelessWidget {
  final TripModel trip;
  const _FullTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/trip/${trip.id}'),
      borderRadius: BorderRadius.circular(28),
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
            WandrImage(
              source: trip.coverPhoto,
              width: double.infinity,
              height: 180,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              heroTag: 'trip_cover_${trip.id}',
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const Gap(6),
                        Row(
                          children: [
                            Icon(
                              Icons.place_outlined,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const Gap(4),
                            Text(
                              trip.destination,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${DateFormat('MMM d').format(trip.startDate)} - ${DateFormat('MMM d').format(trip.endDate)}',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        '${getIt<InMemoryStore>().currentCurrency}${trip.totalBudget.toStringAsFixed(0)} Budget',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
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
