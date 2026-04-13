// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:wandr/core/in_memory_store.dart';
import 'package:wandr/main.dart';
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
  late TripModel _trip;
  bool _isLoading = true;
  
  // Keys to access child methods (Log Expense / Add Photo)
  final GlobalKey<ExpensesViewState> _expensesKey = GlobalKey<ExpensesViewState>();
  final GlobalKey<MemoriesViewState> _memoriesKey = GlobalKey<MemoriesViewState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadTrip();
  }

  Future<void> _loadTrip() async {
    final store = getIt<InMemoryStore>();
    try {
      final trip = store.trips.firstWhere(
        (t) => t.id == widget.tripId,
        orElse: () => store.trips.first,
      );
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() {
          _trip = trip;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) context.pop();
    }
  }

  void _updateTripData() {
    getIt<InMemoryStore>().saveToDisk();
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildSkeletonLoading();

    return ListenableBuilder(
      listenable: getIt<InMemoryStore>(),
      builder: (context, _) {
        // Refresh local trip reference from store to catch edits
        final store = getIt<InMemoryStore>();
        final freshTrip = store.trips.where((t) => t.id == widget.tripId).firstOrNull ?? _trip;
        _trip = freshTrip;

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
                    onPressed: () => context.push('/edit-trip/${_trip.id}'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    onPressed: () => _confirmDelete(),
                  ),
                  const Gap(8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildHeroImage(),
                      _buildHeroGradient(),
                      _buildHeroTitle(),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabDelegate(
                  TabBar(
                    controller: _tabController,
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
                  trip: _trip,
                  onUpdate: (data) {
                    _trip.itinerary = data;
                    _updateTripData();
                  },
                ),
                ExpensesView(
                  key: _expensesKey,
                  trip: _trip,
                  onUpdate: (data) {
                    _trip.expenses = data;
                    _updateTripData();
                  },
                ),
                MemoriesView(
                  key: _memoriesKey,
                  trip: _trip,
                  onUpdate: (data) {
                    _trip.photos = data;
                    _updateTripData();
                  },
                ),
                TripMapView(trip: _trip),
              ],
            ),
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 30), 
            child: _tabController.index != 2
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

  Widget _buildHeroImage() {
    return Hero(
      tag: 'trip_cover_${_trip.id}',
      child: _trip.coverPhoto != null && _trip.coverPhoto!.startsWith('http')
          ? Image.network(_trip.coverPhoto!, fit: BoxFit.cover)
          : (_trip.coverPhoto != null ? Image.file(File(_trip.coverPhoto!), fit: BoxFit.cover) : Container(color: Colors.black)),
    );
  }

  Widget _buildHeroGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.2), Colors.transparent, Colors.black.withOpacity(0.7)],
        ),
      ),
    );
  }

  Widget _buildHeroTitle() {
    return Positioned(
      bottom: 30,
      left: 24,
      right: 24,
      child: Text(
        _trip.name,
        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              getIt<InMemoryStore>().deleteTrip(_trip.id);
              context.pop();
              context.pop();
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
