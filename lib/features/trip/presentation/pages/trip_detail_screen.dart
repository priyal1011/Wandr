import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:image_picker/image_picker.dart';
import '../../../../core/in_memory_store.dart';
import '../../../../core/widgets/interactive_dialog.dart';
import '../../../../main.dart';

class TripDetailScreen extends StatefulWidget {
  final String tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TripModel _trip;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final store = getIt<InMemoryStore>();
    final match = store.trips.where((t) => t.id == widget.tripId);
    if (match.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/home');
      });
      _trip = TripModel(id: '', name: '', destination: '', startDate: DateTime.now(), endDate: DateTime.now(), totalBudget: 0, currency: r'$');
      return;
    }
    _trip = match.first;
  }

  void _deleteTrip() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Journey?'),
        content: const Text('Are you sure you want to permanently delete this trip and all its memories? This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error, foregroundColor: Colors.white),
            onPressed: () {
              getIt<InMemoryStore>().trips.removeWhere((t) => t.id == _trip.id);
              getIt<InMemoryStore>().saveToDisk();
              ctx.pop(); // Close dialog
              context.go('/home'); // Return to home
            },
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(_trip.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              background: Hero(
                tag: 'trip_image_${_trip.id}',
                child: _trip.coverPhoto != null && !_trip.coverPhoto!.startsWith('http')
                    ? Image.file(
                        File(_trip.coverPhoto!),
                        fit: BoxFit.cover,
                        color: Colors.black.withValues(alpha: 0.4),
                        colorBlendMode: BlendMode.darken,
                        errorBuilder: (c, e, s) => Container(color: Colors.grey.shade900, child: const Icon(Icons.broken_image, color: Colors.grey)),
                      )
                    : Image.network(
                        _trip.coverPhoto ?? 'https://images.unsplash.com/photo-1501785888041-af3ef285b470',
                        fit: BoxFit.cover,
                        color: Colors.black.withValues(alpha: 0.4),
                        colorBlendMode: BlendMode.darken,
                        errorBuilder: (c, e, s) => Container(color: Colors.grey.shade900, child: const Icon(Icons.broken_image, color: Colors.grey)),
                      ),
              ),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: () => context.push('/trip/${_trip.id}/edit')),
              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white), onPressed: _deleteTrip),
            ],
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelPadding: const EdgeInsets.symmetric(horizontal: 24),
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 4,
                tabs: const [
                  Tab(text: 'Itinerary', icon: Icon(Icons.calendar_month_outlined)),
                  Tab(text: 'Budget', icon: Icon(Icons.payments_outlined)),
                  Tab(text: 'Memories', icon: Icon(Icons.photo_library_outlined)),
                  Tab(text: 'Map', icon: Icon(Icons.map_outlined)),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _ItineraryView(trip: _trip),
            _BudgetView(tripId: _trip.id),
            _MemoriesView(tripId: _trip.id),
            _MapView(tripId: _trip.id),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height + 8;
  @override
  double get maxExtent => _tabBar.preferredSize.height + 8;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

// --- Views ---

class _ItineraryView extends StatefulWidget {
  final TripModel trip;
  const _ItineraryView({required this.trip});

  @override
  State<_ItineraryView> createState() => _ItineraryViewState();
}

class _ItineraryViewState extends State<_ItineraryView> {
  late List<DayData> _itinerary;
  int _selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    _itinerary = widget.trip.itinerary ?? [];
  }

  void _addDay() {
    setState(() {
      final nextDate = widget.trip.startDate.add(Duration(days: _itinerary.length));
      if (nextDate.isAfter(widget.trip.endDate)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot add more days than trip duration.')));
        return;
      }
      _itinerary.add(DayData(date: nextDate));
      widget.trip.itinerary = _itinerary;
      _selectedDayIndex = _itinerary.length - 1;
    });
    getIt<InMemoryStore>().saveToDisk();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ...List.generate(_itinerary.length, (index) {
                  final isSelected = _selectedDayIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: () => setState(() => _selectedDayIndex = index),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? Colors.transparent : Theme.of(context).dividerColor),
                          boxShadow: isSelected ? [BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))] : null,
                        ),
                        child: Column(
                          children: [
                            Text('Day ${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface)),
                            Text(DateFormat('MMM d').format(_itinerary[index].date), style: TextStyle(fontSize: 11, color: isSelected ? Colors.white.withValues(alpha: 0.8) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                _AddIconButton(onTap: _addDay, label: 'Add Day'),
              ],
            ),
          ),
          const Gap(16),
          Expanded(
            child: _itinerary.isEmpty
                ? const Center(child: Text('Start planning your adventure day by day.'))
                : _buildDayPlaces(_itinerary[_selectedDayIndex]),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _itinerary.isEmpty ? _addDay : () => _addPlace(_itinerary[_selectedDayIndex]),
        label: Text(_itinerary.isEmpty ? 'Add Day First' : 'Add Place', style: const TextStyle(fontWeight: FontWeight.bold)),
        icon: Icon(_itinerary.isEmpty ? Icons.calendar_today : Icons.add_location_alt_rounded),
      ).animate().scale(delay: 500.ms),
    );
  }

  Widget _buildDayPlaces(DayData day) {
    if (day.places.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.place_outlined, size: 48, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
            const Gap(12),
            const Text('No places added for this day yet.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      itemCount: day.places.length,
      itemBuilder: (context, index) {
        final place = day.places[index];
        return Dismissible(
          key: Key(place.name + place.time),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
          ),
          onDismissed: (_) {
            setState(() => day.places.removeAt(index));
            getIt<InMemoryStore>().saveToDisk();
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
                  child: Icon(_getIconForPlace(place.type), color: Theme.of(context).colorScheme.primary, size: 24),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(place.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (place.notes != null && place.notes!.isNotEmpty) ...[
                        const Gap(2),
                        Text(place.notes!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                      ],
                      const Gap(4),
                      Text(place.type, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Text(place.time, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: index * 100)).slideX(begin: 0.05),
        );
      },
    );
  }

  IconData _getIconForPlace(String type) {
    switch (type) {
      case 'Activity': return Icons.explore_outlined;
      case 'Restaurant': return Icons.restaurant_outlined;
      case 'Transport': return Icons.directions_bus_outlined;
      case 'Hotel': return Icons.hotel_outlined;
      default: return Icons.place_outlined;
    }
  }

  void _addPlace(DayData day) {
    final nameCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    final customTypeCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String type = 'Activity';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => InteractiveDialog(
          title: 'Add a Destination',
          icon: Icons.place_outlined,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Place Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
              const Gap(16),
              TextField(controller: timeCtrl, decoration: InputDecoration(labelText: 'Time (e.g. 10:00 AM)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
              const Gap(16),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: InputDecoration(labelText: 'Category', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                items: ['Activity', 'Restaurant', 'Transport', 'Hotel', 'Other'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setDialogState(() => type = v!),
              ),
              if (type == 'Other') ...[const Gap(16), TextField(controller: customTypeCtrl, decoration: InputDecoration(labelText: 'Custom Category', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))))],
              const Gap(16),
              TextField(controller: notesCtrl, decoration: InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
            ],
          ),
          actions: [
            TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final finalType = type == 'Other' ? customTypeCtrl.text : type;
                setState(() => day.places.add(PlaceData(name: nameCtrl.text, time: timeCtrl.text, type: finalType, notes: notesCtrl.text)));
                getIt<InMemoryStore>().saveToDisk();
                context.pop();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  const _AddIconButton({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor, style: BorderStyle.none), borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
             Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary),
             Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          ],
        ),
      ),
    );
  }
}

class _BudgetView extends StatefulWidget {
  final String tripId;
  const _BudgetView({required this.tripId});

  @override
  State<_BudgetView> createState() => _BudgetViewState();
}

class _BudgetViewState extends State<_BudgetView> {
  late List<ExpenseModel> _expenses;
  late double _totalSpent;
  late TripModel _trip;

  @override
  void initState() {
    super.initState();
    _trip = getIt<InMemoryStore>().trips.firstWhere((t) => t.id == widget.tripId, orElse: () => TripModel(id: '', name: '', destination: '', startDate: DateTime.now(), endDate: DateTime.now(), totalBudget: 0, currency: r'$'));
    _expenses = _trip.expenses ?? [];
    _totalSpent = _expenses.fold(0, (sum, item) => sum + item.amount);
  }

  void _addExpense() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String category = 'Food';

    showDialog(
      context: context,
      builder: (context) => InteractiveDialog(
        title: 'Track Expense',
        icon: Icons.payments_outlined,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Expense Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
            const Gap(16),
            TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Amount (\$)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text) ?? 0.0;
              setState(() {
                _expenses.add(ExpenseModel(id: DateTime.now().toString(), tripId: widget.tripId, name: nameCtrl.text, amount: amount, category: category, date: DateTime.now()));
                _totalSpent += amount;
                _trip.expenses = _expenses;
              });
              getIt<InMemoryStore>().saveToDisk();
              context.pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalBudget = _trip.totalBudget;
    final percentUsed = totalBudget > 0 ? (_totalSpent / totalBudget) : 0.0;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfessionalBudgetCard(totalSpent: _totalSpent, totalBudget: totalBudget, percentUsed: percentUsed),
            const Gap(32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Expenses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                TextButton.icon(onPressed: _addExpense, icon: const Icon(Icons.add, size: 18), label: const Text('Add Expense')),
              ],
            ),
            const Gap(16),
            if (_expenses.isEmpty)
              Center(child: Padding(padding: const EdgeInsets.only(top: 40), child: Text('No expenses recorded yet.', style: TextStyle(color: Colors.grey.withValues(alpha: 0.5)))))
            else
              ..._expenses.map((exp) => _ExpenseItem(expense: exp, onDelete: () {
                    setState(() {
                      _expenses.remove(exp);
                      _totalSpent -= exp.amount;
                      _trip.expenses = _expenses;
                    });
                    getIt<InMemoryStore>().saveToDisk();
                  })).toList().animate(interval: 50.ms).fadeIn().slideX(begin: 0.05),
          ],
        ),
      ),
    );
  }
}

class _ProfessionalBudgetCard extends StatelessWidget {
  final double totalSpent;
  final double totalBudget;
  final double percentUsed;
  const _ProfessionalBudgetCard({required this.totalSpent, required this.totalBudget, required this.percentUsed});

  @override
  Widget build(BuildContext context) {
    final remaining = totalBudget - totalSpent;
    final isOverBudget = remaining < 0;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text('Trip Budget', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                   Text('Track your spending', style: TextStyle(fontSize: 12, color: Colors.grey.withValues(alpha: 0.8))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                   Text('\$${totalSpent.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: isOverBudget ? Colors.redAccent : Colors.indigo)),
                   Text('of \$${totalBudget.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const Gap(24),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentUsed.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(isOverBudget ? Colors.redAccent : Theme.of(context).colorScheme.primary),
            ),
          ),
          const Gap(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text('${(percentUsed * 100).toStringAsFixed(1)}% spent', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
               Text(isOverBudget ? '\$${(-remaining).toStringAsFixed(0)} overspent' : '\$${remaining.toStringAsFixed(0)} remaining', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isOverBudget ? Colors.redAccent : Colors.teal)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpenseItem extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback onDelete;
  const _ExpenseItem({required this.expense, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
        ),
        child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05), shape: BoxShape.circle),
            child: Icon(_getIcon(expense.category), size: 20, color: Theme.of(context).colorScheme.primary),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(DateFormat('MMM d, y').format(expense.date), style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Text('\$${expense.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
      ),
    );
  }

  IconData _getIcon(String category) {
    switch (category) {
      case 'Food': return Icons.restaurant;
      case 'Transport': return Icons.directions_car;
      case 'Hotel': return Icons.hotel;
      default: return Icons.payments_outlined;
    }
  }
}

class _MemoriesView extends StatefulWidget {
  final String tripId;
  const _MemoriesView({required this.tripId});

  @override
  State<_MemoriesView> createState() => _MemoriesViewState();
}

class _MemoriesViewState extends State<_MemoriesView> {
  late List<PhotoModel> _memories;
  late TripModel _trip;

  @override
  void initState() {
    super.initState();
    _trip = getIt<InMemoryStore>().trips.firstWhere((t) => t.id == widget.tripId, orElse: () => TripModel(id: '', name: '', destination: '', startDate: DateTime.now(), endDate: DateTime.now(), totalBudget: 0, currency: r'$'));
    _memories = _trip.photos ?? [];
  }

  Future<void> _addMemory() async {
    final captionCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String? pickedPath;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => InteractiveDialog(
          title: 'Capture Memory',
          icon: Icons.auto_awesome_outlined,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final source = await showModalBottomSheet<ImageSource>(
                    context: ctx,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                    builder: (c) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Camera'), onTap: () => Navigator.pop(c, ImageSource.camera)),
                          ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () => Navigator.pop(c, ImageSource.gallery)),
                        ],
                      ),
                    ),
                  );
                  if (source == null) return;
                  final image = await ImagePicker().pickImage(source: source);
                  if (image != null) setDialogState(() => pickedPath = image.path);
                },
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(ctx).dividerColor),
                    image: pickedPath != null ? DecorationImage(image: FileImage(File(pickedPath!)), fit: BoxFit.cover) : null,
                  ),
                  child: pickedPath == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 36, color: Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.4)),
                            const Gap(8),
                            Text('Tap to upload photo', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        )
                      : null,
                ),
              ),
              const Gap(16),
              TextField(
                controller: captionCtrl,
                decoration: InputDecoration(
                  labelText: 'Caption',
                  hintText: 'e.g. Sunset at the temple',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const Gap(12),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Any thoughts or details...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: pickedPath == null ? null : () => Navigator.pop(ctx, true),
              child: const Text('Save Memory'),
            ),
          ],
        ),
      ),
    );

    if (result == true && pickedPath != null) {
      setState(() {
        final newPhoto = PhotoModel(
          id: DateTime.now().toString(),
          tripId: widget.tripId,
          url: pickedPath!,
          caption: captionCtrl.text.isEmpty ? 'Journey Photo' : captionCtrl.text,
        );
        _memories.insert(0, newPhoto);
        _trip.photos = _memories;
        getIt<InMemoryStore>().photos.insert(0, newPhoto);
      });
      getIt<InMemoryStore>().saveToDisk();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _memories.isEmpty
          ? Center(child: Text('No memories yet.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3))))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1),
              itemCount: _memories.length,
              itemBuilder: (context, index) {
                 final photo = _memories[index];
                 return ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: photo.url.startsWith('http') 
                      ? Image.network(photo.url, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade300, child: const Icon(Icons.broken_image)))
                      : Image.file(File(photo.url), fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade300, child: const Icon(Icons.broken_image))),
                ).animate().fadeIn(delay: Duration(milliseconds: index * 50)).scale(begin: const Offset(0.9, 0.9));
              },
            ),
      floatingActionButton: FloatingActionButton.extended(onPressed: _addMemory, label: const Text('Capture'), icon: const Icon(Icons.add_photo_alternate_rounded)),
    );
  }
}

class _MapView extends StatefulWidget {
  final String tripId;
  const _MapView({required this.tripId});

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  final MapController _mapController = MapController();
  late List<Marker> _markers;
  late TripModel _trip;

  @override
  void initState() {
    super.initState();
    _trip = getIt<InMemoryStore>().trips.firstWhere((t) => t.id == widget.tripId, orElse: () => TripModel(id: '', name: '', destination: '', startDate: DateTime.now(), endDate: DateTime.now(), totalBudget: 0, currency: r'$'));
    _markers = _trip.markers ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _markers.isNotEmpty ? _markers.first.point : const ll.LatLng(20.5937, 78.9629),
            initialZoom: 8,
            onTap: (_, p) => setState(() {
               _markers.add(Marker(point: p, child: Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary, size: 30)));
               _trip.markers = _markers;
               getIt<InMemoryStore>().saveToDisk();
            }),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.wandr.app',
            ),
            MarkerLayer(markers: _markers),
          ],
        ),
        Positioned(
          right: 24,
          top: 24,
          child: Column(
            children: [
              _ZoomButton(icon: Icons.add, onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1)),
              const Gap(12),
              _ZoomButton(icon: Icons.remove, onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        width: 52,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}