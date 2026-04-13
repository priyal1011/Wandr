import 'dart:io';
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
            
            return ListenableBuilder(
              listenable: getIt<InMemoryStore>(),
              builder: (context, _) {
                 // We still listen to store for global edits (like name change in Edit Screen)
                 context.read<TripCubit>().refreshFromStore();
                 
                 return Scaffold(
                  body: NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) => [
                      SliverAppBar(
                        expandedHeight: 320,
                        pinned: true,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                        actions: [
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
                              _buildHeroTitle(trip),
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
                            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            tabs: const [
                              Tab(icon: Icon(Icons.calendar_month_outlined, size: 20), text: 'Itinerary'),
                              Tab(icon: Icon(Icons.payments_outlined, size: 20), text: 'Budget'),
                              Tab(icon: Icon(Icons.photo_library_outlined, size: 20), text: 'Memories'),
                              Tab(icon: Icon(Icons.map_outlined, size: 20), text: 'Map'),
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
                    padding: const EdgeInsets.all(0), // Removed bottom: 30 to fix positioning
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
              },
            );
          }
          
          return const Scaffold(body: Center(child: Text('Trip not found')));
        },
      ),
    );
  }

  Widget _buildHeroImage(TripModel trip) {
    return Hero(
      tag: 'trip_cover_${trip.id}',
      child: trip.coverPhoto != null && trip.coverPhoto!.startsWith('http')
          ? Image.network(trip.coverPhoto!, fit: BoxFit.cover)
          : (trip.coverPhoto != null ? Image.file(File(trip.coverPhoto!), fit: BoxFit.cover) : Container(color: Colors.black)),
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

  Widget _buildHeroTitle(TripModel trip) {
    return Positioned(
      bottom: 30,
      left: 24,
      right: 24,
      child: Text(
        trip.name,
        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
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
            onPressed: () {
              cubit.deleteTrip();
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Skeletonizer(
        enabled: true,
        child: Column(
          children: [
            Container(height: 320, color: Colors.grey.shade900),
            const Gap(16),
            Expanded(
              child: ListView.builder(
                itemCount: 4, 
                itemBuilder: (context, i) => ListTile(
                  title: Container(height: 100, decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(24))),
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
