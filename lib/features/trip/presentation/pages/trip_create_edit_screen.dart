import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/in_memory_store.dart';
import '../../../../main.dart';

class TripCreateEditScreen extends StatefulWidget {
  final String? tripId;
  const TripCreateEditScreen({super.key, this.tripId});

  @override
  State<TripCreateEditScreen> createState() => _TripCreateEditScreenState();
}

class _TripCreateEditScreenState extends State<TripCreateEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _destinationController = TextEditingController();
  final _budgetController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;
  String? _coverPhotoUrl;

  @override
  void initState() {
    super.initState();
    if (widget.tripId != null) {
      final match = getIt<InMemoryStore>().trips.where((t) => t.id == widget.tripId);
      if (match.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/home');
        });
        return;
      }
      final trip = match.first;
      _nameController.text = trip.name;
      _destinationController.text = trip.destination;
      _budgetController.text = trip.totalBudget.toString();
      _startDate = trip.startDate;
      _endDate = trip.endDate;
      _coverPhotoUrl = trip.coverPhoto;
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: isStart ? DateTime(2000) : (_startDate ?? DateTime(2000)),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) _endDate = null;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectPhotoSource() async {
    final ImagePicker picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.camera_alt_outlined, color: Theme.of(context).colorScheme.primary),
                ),
                title: const Text('Capture with Camera', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const Gap(12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.photo_library_outlined, color: Theme.of(context).colorScheme.primary),
                ),
                title: const Text('Select from Gallery', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              if (_coverPhotoUrl != null) ...[
                const Gap(12),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  title: const Text('Remove Cover Photo', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  onTap: () => Navigator.pop(context, null),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (source == null && _coverPhotoUrl != null) {
       setState(() => _coverPhotoUrl = null);
       return;
    }
    if (source == null) return;

    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _coverPhotoUrl = image.path; // Use actual path for native file rendering
      });
    }
  }

  void _saveTrip() {
    if (_formKey.currentState!.validate() && _startDate != null && _endDate != null) {
      final store = getIt<InMemoryStore>();
      final newTrip = TripModel(
        id: widget.tripId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        destination: _destinationController.text,
        startDate: _startDate!,
        endDate: _endDate!,
        totalBudget: double.tryParse(_budgetController.text) ?? 500.0,
        currency: r'$',
        coverPhoto: _coverPhotoUrl,
      );

      if (widget.tripId != null) {
        final index = store.trips.indexWhere((t) => t.id == widget.tripId);
        store.trips[index] = newTrip;
      } else {
        store.trips.insert(0, newTrip);
      }
      store.saveToDisk();
      
      context.go('/home');
    } else if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please define your journey timeframe.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tripId == null ? 'Plan New Trip' : 'Refine Trip'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              onPressed: _saveTrip,
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPhotoPicker(),
              const Gap(32),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Adventure Name',
                  hintText: 'e.g. Kyoto Explorer 2026',
                  prefixIcon: const Icon(Icons.drive_file_rename_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Enter a name for your journey.' : null,
              ),
              const Gap(16),
              TextFormField(
                controller: _destinationController,
                decoration: InputDecoration(
                  labelText: 'Destination',
                  prefixIcon: const Icon(Icons.explore_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Where are we going?' : null,
              ),
              const Gap(24),
              Row(
                children: [
                   Expanded(child: _buildDatePicker(true)),
                   const Gap(16),
                   Expanded(child: _buildDatePicker(false)),
                ],
              ),
              const Gap(24),
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Estimated Budget',
                  prefixIcon: const Icon(Icons.savings_outlined),
                  prefixText: r'$ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
              const Gap(100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(bool isStart) {
    final date = isStart ? _startDate : _endDate;
    return InkWell(
      onTap: () => _pickDate(isStart),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isStart ? 'Starts' : 'Returns', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const Gap(4),
            Text(
              date == null ? 'Set Date' : DateFormat('MMM d, y').format(date),
              style: TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.bold,
                color: date == null ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3) : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return GestureDetector(
      onTap: _selectPhotoSource,
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
          image: _coverPhotoUrl != null 
              ? DecorationImage(
                  image: _coverPhotoUrl!.startsWith('http') ? NetworkImage(_coverPhotoUrl!) : FileImage(File(_coverPhotoUrl!)) as ImageProvider, 
                  fit: BoxFit.cover
                ) : null,
        ),
        child: _coverPhotoUrl == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, size: 56, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
                  const Gap(12),
                  const Text('Inspire your Journey', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const Text('Upload a cover photo', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              )
            : Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
      ),
    );
  }
}