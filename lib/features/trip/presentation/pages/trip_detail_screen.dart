import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandr/features/trip/presentation/cubit/trip_cubit.dart';
import 'package:wandr/features/trip/presentation/cubit/trip_state.dart';

import 'package:wandr/core/in_memory_store.dart';
import 'package:wandr/main.dart';
import 'package:wandr/models/trip_model.dart';
import 'package:wandr/core/widgets/wandr_image.dart';
import 'package:wandr/features/trip/presentation/widgets/itinerary_view.dart';
import 'package:wandr/features/trip/presentation/widgets/expenses_view.dart';
import 'package:wandr/features/trip/presentation/widgets/memories_view.dart';
import 'package:wandr/features/trip/presentation/widgets/trip_map_view.dart';

class TripDetailScreen extends StatefulWidget {
  final String tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Keys to access child methods (Log Expense / Add Photo)
  final GlobalKey<ExpensesViewState> _expensesKey = GlobalKey<ExpensesViewState>();
  final GlobalKey<MemoriesViewState> _memoriesKey = GlobalKey<MemoriesViewState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TripCubit(widget.tripId)..loadTrip(),
      child: BlocConsumer<TripCubit, TripState>(
        listener: (context, state) {
          if (state is TripDeleted) {
             context.pop();
             context.pop();
          }
          if (state is TripError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is TripLoading || state is TripInitial) {
            return _buildSkeletonLoading();
          }
          
          if (state is TripLoaded) {
            final trip = state.trip;
            final screenHeight = MediaQuery.of(context).size.height;
            final screenWidth = MediaQuery.of(context).size.width;
            
            // Safety: Check if trip still exists in store (prevents deletion crashes)
            final exists = getIt<InMemoryStore>().trips.any((t) => t.id == trip.id);
            if (!exists) return const Scaffold(body: Center(child: CircularProgressIndicator()));

            return Scaffold(
              body: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverAppBar(
                    expandedHeight: screenHeight * 0.35, // Adaptive height
                    pinned: true,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    actions: [
                      ListenableBuilder(
                        listenable: getIt<InMemoryStore>(),
                        builder: (context, _) {
                          if (!getIt<InMemoryStore>().isSyncingCloud) return const SizedBox.shrink();
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Hero(
                              tag: 'sync_indicator',
                              child: Icon(Icons.cloud_sync_outlined, size: 20, color: Colors.lightBlueAccent),
                            ),
                          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.white),
                        onPressed: () => context.push('/edit-trip/${trip.id}'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.white),
                        onPressed: () => _confirmDelete(context),
                      ),
                      const Gap(8),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildHeroImage(trip),
                          _buildHeroGradient(),
                          _buildHeroTitle(trip, screenWidth),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverTabDelegate(
                      TabBar(
                        controller: _tabController,
                        onTap: (index) => context.read<TripCubit>().updateTabIndex(index),
                        indicatorColor: Colors.lightBlueAccent,
                        indicatorWeight: 4,
                        labelColor: Colors.lightBlueAccent,
                        unselectedLabelColor: Colors.grey,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), // Smaller for legacy screens
                        tabs: const [
                          Tab(icon: Icon(Icons.calendar_month_outlined, size: 18), text: 'Itinerary'), // Renamed from Plan
                          Tab(icon: Icon(Icons.payments_outlined, size: 18), text: 'Budget'),
                          Tab(icon: Icon(Icons.photo_library_outlined, size: 18), text: 'Memories'), // Renamed from Diary
                          Tab(icon: Icon(Icons.map_outlined, size: 18), text: 'Map'),
                        ],
                      ),
                    ),
                  ),
                ],
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    ItineraryView(
                      trip: trip,
                      onUpdate: (data) => context.read<TripCubit>().updateItinerary(data),
                    ),
                    ExpensesView(
                      key: _expensesKey,
                      trip: trip,
                      onUpdate: (data) => context.read<TripCubit>().updateExpenses(data),
                    ),
                    MemoriesView(
                      key: _memoriesKey,
                      trip: trip,
                      onUpdate: (data) => context.read<TripCubit>().updatePhotos(data),
                    ),
                    TripMapView(trip: trip),
                  ],
                ),
              ),
              floatingActionButton: Padding(
                padding: const EdgeInsets.all(0),
                child: state.activeTabIndex != 2
                    ? null 
                    : FloatingActionButton.extended(
                        onPressed: () => _memoriesKey.currentState?.addPhoto(),
                        backgroundColor: Colors.lightBlueAccent,
                        foregroundColor: Colors.black,
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: const Text('Add Photo'),
                      ).animate().scale(),
              ),
            );
          }
          
          return const Scaffold(body: Center(child: Text('Trip not found')));
        },
      ),
    );
  }

  Widget _buildHeroImage(TripModel trip) {
    return WandrImage(
      source: trip.coverPhoto,
      heroTag: 'trip_cover_${trip.id}',
    );
  }

  Widget _buildHeroGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.2), Colors.transparent, Colors.black.withValues(alpha: 0.7)],
        ),
      ),
    );
  }

  Widget _buildHeroTitle(TripModel trip, double screenWidth) {
    return Positioned(
      bottom: 30,
      left: 24,
      right: 24,
      child: ListenableBuilder(
        listenable: getIt<InMemoryStore>(),
        builder: (context, _) {
          // Sync state if returned from edit
          context.read<TripCubit>().refreshFromStore();
          final state = context.read<TripCubit>().state;
          final updatedName = state is TripLoaded ? state.trip.name : trip.name;
          
          return Text(
            updatedName,
            style: TextStyle(
              color: Colors.white, 
              fontSize: screenWidth < 360 ? 28 : 36, // Scaled for width
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final cubit = context.read<TripCubit>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Unmount UI first to trigger map dispose()
              // Cool-down period to ensure background emitters are dead
              await Future.delayed(const Duration(milliseconds: 150));
              cubit.deleteTrip();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Skeletonizer(
        enabled: true,
        child: Column(
          children: [
            Container(height: 320, color: Theme.of(context).colorScheme.surfaceContainerHighest),
            const Gap(16),
            Expanded(
              child: ListView.builder(
                itemCount: 4, 
                itemBuilder: (context, i) => ListTile(
                  title: Container(
                    height: 100, 
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest, 
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverTabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _SliverTabDelegate(this.tabBar);
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(color: Theme.of(context).colorScheme.surface, elevation: overlapsContent ? 4 : 0, child: tabBar);
  }
  @override
  bool shouldRebuild(_SliverTabDelegate oldDelegate) => false;
}
