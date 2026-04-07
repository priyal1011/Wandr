import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/trip_models.dart';
import '../providers/trip_provider.dart';

class TripDetailScreen extends ConsumerStatefulWidget {
  final String tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final trips = ref.watch(mockTripsProvider);
    final trip = trips.firstWhere((t) => t.id == widget.tripId);
    final formattedDate = '${DateFormat('MMM d').format(trip.startDate)} - ${DateFormat('MMM d, yyyy').format(trip.endDate)}';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            stretch: true,
            backgroundColor: Theme.of(context).colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'trip-image-${trip.id}',
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(trip.coverImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
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
                  ),
                ),
              ),
              title: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.title,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
                  ],
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 48, bottom: 16, right: 16),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabs: const [
                  Tab(text: 'Itinerary'),
                  Tab(text: 'Budget'),
                  Tab(text: 'Photos'),
                ],
              ),
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildItinerary(trip),
                _buildBudget(trip),
                _buildPhotos(trip),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItinerary(Trip trip) {
    if (trip.itinerary.isEmpty) {
      return Center(
        child: Text('No itinerary planned yet.'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: trip.itinerary.length,
      itemBuilder: (context, index) {
        final day = trip.itinerary[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Day ${index + 1} - ${DateFormat('EEEE, MMM d').format(day.date)}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            ...day.places.map((place) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.time,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (place.notes != null)
                          Text(
                            place.notes!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 24),
          ],
        );
      },
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1);
  }

  Widget _buildBudget(Trip trip) {
    final formatCurrency = NumberFormat.simpleCurrency();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spent',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  formatCurrency.format(trip.budget.spent),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Total Budget',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  formatCurrency.format(trip.budget.total),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
        const SizedBox(height: 24),
        LinearProgressIndicator(
          value: trip.budget.spent / trip.budget.total,
          minHeight: 12,
          borderRadius: BorderRadius.circular(6),
        ).animate().fadeIn(delay: 200.ms).scaleX(begin: 0, alignment: Alignment.centerLeft),
        const SizedBox(height: 32),
        Text('Expenses', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        if (trip.budget.expenses.isEmpty)
          const Text('No expenses recorded.')
        else
          ...trip.budget.expenses.map((expense) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              child: Icon(Icons.receipt_long),
            ),
            title: Text(expense.name),
            subtitle: Text(DateFormat('MMM d').format(expense.date)),
            trailing: Text(
              formatCurrency.format(expense.amount),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          )),
      ],
    );
  }

  Widget _buildPhotos(Trip trip) {
    if (trip.photos.isEmpty) {
      return const Center(child: Text('No photos yet.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: trip.photos.length,
      itemBuilder: (context, index) {
        final photo = trip.photos[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: photo.url,
            fit: BoxFit.cover,
          ),
        ).animate().fadeIn(delay: (index * 100).ms).scale(curve: Curves.easeOut);
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar, {required this.color});

  final TabBar _tabBar;
  final Color color;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: color,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
