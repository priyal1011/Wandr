// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:wandr/core/services/ai_service.dart';
import 'package:wandr/core/widgets/interactive_dialog.dart';
import 'package:wandr/models/trip_model.dart';
import 'package:wandr/models/day_data.dart';
import 'package:wandr/models/place_data.dart';

class ItineraryView extends StatefulWidget {
  final TripModel trip;
  final Function(List<DayData>) onUpdate;

  const ItineraryView({
    super.key,
    required this.trip,
    required this.onUpdate,
  });

  @override
  State<ItineraryView> createState() => _ItineraryViewState();
}

class _ItineraryViewState extends State<ItineraryView> {
  late List<DayData> _itinerary;
  int _selectedDayIndex = 0;
  bool _isAiLoading = false;
  http.Client? _aiClient;

  @override
  void initState() {
    super.initState();
    _itinerary = widget.trip.itinerary ?? [];
  }

  void _addDay() {
    setState(() {
      final nextDate = _itinerary.isEmpty
          ? widget.trip.startDate
          : _itinerary.last.date.add(const Duration(days: 1));
      _itinerary.add(DayData(date: nextDate, places: []));
      widget.onUpdate(_itinerary);
    });
  }

  Future<void> _autoFill() async {
    final promptCtrl = TextEditingController();
    bool shouldRetry = true;

    while (shouldRetry) {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => InteractiveDialog(
          title: 'Magic Auto-Fill',
          icon: Icons.auto_awesome,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What kind of activities are you looking for?', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
              const Gap(12),
              TextField(
                controller: promptCtrl,
                maxLines: 3,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'e.g. "Focus on local food and hidden gems," "Include more hiking," etc.',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlueAccent, foregroundColor: Colors.black),
              child: const Text('Generate'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
      
      shouldRetry = false; // Default to not retrying unless stopped
      setState(() => _isAiLoading = true);
      _aiClient = http.Client();

      try {
        final result = await AiService.generateItinerary(
          destination: widget.trip.destination,
          days: 3, 
          startDate: widget.trip.startDate,
          customPrompt: promptCtrl.text,
          client: _aiClient,
        );

        if (!mounted) return;
        setState(() => _isAiLoading = false);

        if (result != null) {
          setState(() {
            _itinerary = result;
            widget.onUpdate(_itinerary);
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✨ Trip magic generated!')));
        } else {
          // If result is null, it might be due to cancellation or actual error
          if (_aiClient == null) {
             shouldRetry = true; // Was cancelled/stopped, show dialog again
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('🛡️ Quota limit reached or network error.'), backgroundColor: Colors.orange),
            );
          }
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isAiLoading = false);
        if (_aiClient == null) {
          shouldRetry = true; // Was cancelled/stopped
        }
      } finally {
        _aiClient?.close();
        _aiClient = null;
      }
    }
  }

  void _stopAi() {
    _aiClient?.close();
    _aiClient = null;
    setState(() => _isAiLoading = false);
  }

  void _deleteDay(int index) {
    setState(() {
      _itinerary.removeAt(index);
      if (_selectedDayIndex >= _itinerary.length) {
        _selectedDayIndex = (_itinerary.length - 1).clamp(0, 999);
      }
      widget.onUpdate(_itinerary);
    });
  }

  void _editPlace(int dayIndex, int placeIndex) async {
    final place = _itinerary[dayIndex].places[placeIndex];
    final nameCtrl = TextEditingController(text: place.name);
    final timeCtrl = TextEditingController(text: place.time);
    final notesCtrl = TextEditingController(text: place.notes);
    String type = place.type;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => InteractiveDialog(
          title: 'Edit Place',
          icon: Icons.edit_location_alt_outlined,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Place Name',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const Gap(12),
              TextField(
                controller: timeCtrl,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Time',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const Gap(12),
              DropdownButtonFormField<String>(
                value: type,
                dropdownColor: Theme.of(context).colorScheme.surface,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Type',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                items: ['Activity', 'Restaurant', 'Transport', 'Hotel', 'Other']
                   .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setDialogState(() => type = v!),
              ),
              const Gap(12),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Notes',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlueAccent, foregroundColor: Colors.black),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      setState(() {
        _itinerary[dayIndex].places[placeIndex] = PlaceData(
          name: nameCtrl.text,
          time: timeCtrl.text,
          type: type,
          notes: notesCtrl.text,
        );
        widget.onUpdate(_itinerary);
      });
    }
  }

  void _deletePlace(int dayIndex, int placeIndex) {
    setState(() {
      _itinerary[dayIndex].places.removeAt(placeIndex);
      widget.onUpdate(_itinerary);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDayPicker(),
        Expanded(
          child: _itinerary.isEmpty 
            ? _buildEmptyState()
            : _buildDayPlaces(
                _selectedDayIndex.clamp(0, _itinerary.length - 1), 
                _itinerary[_selectedDayIndex.clamp(0, _itinerary.length - 1)]
              ),
        ),
      ],
    );
  }

  Widget _buildDayPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            ..._itinerary.asMap().entries.map((entry) {
              final isSelected = _selectedDayIndex == entry.key;
              return GestureDetector(
                onTap: () => setState(() => _selectedDayIndex = entry.key),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.lightBlueAccent : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? Colors.lightBlueAccent : Colors.grey.withOpacity(0.3)),
                    boxShadow: !isDark && isSelected ? [BoxShadow(color: Colors.lightBlueAccent.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
                  ),
                  child: Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Day ${entry.key + 1}', 
                            style: TextStyle(color: isSelected ? (isDark ? Colors.black : Colors.white) : Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(DateFormat('MMM dd').format(entry.value.date), 
                            style: TextStyle(color: isSelected ? (isDark ? Colors.black87 : Colors.white70) : Colors.grey, fontSize: 10)),
                        ],
                      ),
                      if (isSelected) ...[
                        const Gap(8),
                        GestureDetector(
                          onTap: () => _deleteDay(entry.key),
                          child: Icon(Icons.close, size: 16, color: isDark ? Colors.black54 : Colors.white70),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
            _buildActionIcon(Icons.add_circle_outline, 'Add Day', _addDay),
            const Gap(12),
            _buildAutoFillButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4), 
              decoration: BoxDecoration(color: Colors.lightBlueAccent.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: Colors.lightBlueAccent, size: 20), 
            ),
            const Gap(2),
            Text(label, style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 9, fontWeight: FontWeight.bold, height: 1.1)),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoFillButton() {
    return GestureDetector(
      onTap: _isAiLoading ? _stopAi : _autoFill,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: _isAiLoading 
              ? Colors.red.withValues(alpha: 0.1) 
              : Colors.lightBlueAccent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: _isAiLoading 
                ? Colors.red.withValues(alpha: 0.2) 
                : Colors.lightBlueAccent.withValues(alpha: 0.2)
          ),
        ),
        child: Row(
          children: [
            if (_isAiLoading)
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
            else
              const Icon(Icons.auto_awesome, color: Colors.lightBlueAccent, size: 18),
            const Gap(10),
            Text(
              _isAiLoading ? 'Stop Generation' : 'Auto-Fill', 
              style: TextStyle(
                color: _isAiLoading ? Colors.red : Colors.lightBlueAccent, 
                fontWeight: FontWeight.bold, 
                fontSize: 14
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayPlaces(int dayIndex, DayData day) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 160),
      itemCount: day.places.length,
      itemBuilder: (context, index) {
        final place = day.places[index];
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
            boxShadow: !isDark ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))] : [],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.lightBlueAccent.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getIconForPlace(place.type), color: Colors.lightBlueAccent, size: 24),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                    if (place.notes?.isNotEmpty ?? false) ...[
                      const Gap(2),
                      Text(place.notes!, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                    ],
                    const Gap(4),
                    Text(place.type, style: const TextStyle(fontSize: 12, color: Colors.lightBlueAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(place.time, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontWeight: FontWeight.bold)),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.withOpacity(0.5)),
                    padding: EdgeInsets.zero,
                    onSelected: (val) {
                      if (val == 'edit') _editPlace(dayIndex, index);
                      if (val == 'delete') _deletePlace(dayIndex, index);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), Gap(8), Text('Edit')])),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red, size: 18), Gap(8), Text('Delete', style: TextStyle(color: Colors.red))])),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.05);
      },
    );
  }

  IconData _getIconForPlace(String type) {
    switch (type) {
      case 'Activity': return Icons.explore_outlined;
      case 'Restaurant': return Icons.restaurant_outlined;
      case 'Transport': return Icons.directions_bus_outlined;
      case 'Hotel': return Icons.hotel_outlined;
      default: return Icons.location_on_outlined;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
          const Gap(24),
          Text(
            'Start planning your adventure day by day.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3), fontSize: 16, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ).animate().fadeIn(duration: 800.ms),
    );
  }
}
