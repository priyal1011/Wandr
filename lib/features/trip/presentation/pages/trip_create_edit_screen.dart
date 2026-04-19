import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/in_memory_store.dart';
import '../../../../main.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../models/trip_model.dart';

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
      final match = getIt<InMemoryStore>().trips.where(
        (t) => t.id == widget.tripId,
      );
      if (match.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/');
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
      _companions = List.from(trip.companions ?? []);
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: isStart ? DateTime(2000) : (_startDate ?? DateTime(2000)),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: const Text(
                  'Capture with Camera',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const Gap(12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.photo_library_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: const Text(
                  'Select from Gallery',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              if (_coverPhotoUrl != null) ...[
                const Gap(12),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  title: const Text(
                    'Remove Cover Photo',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
        _coverPhotoUrl =
            image.path; // Use actual path for native file rendering
      });
    }
  }

  Future<void> _saveTrip() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_formKey.currentState!.validate() &&
        _startDate != null &&
        _endDate != null) {
      final store = getIt<InMemoryStore>();

      String? finalPhotoPath = _coverPhotoUrl;
      if (_coverPhotoUrl != null && !_coverPhotoUrl!.startsWith('http')) {
        // Show uploading hint
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('☁️ Syncing cover photo to cloud...'), duration: Duration(seconds: 2)),
        );

        final localSaved = await FileUtils.saveFilePersistently(_coverPhotoUrl!);
        final String? cloudUrl = await StorageService.uploadImage(localSaved, 'trip_covers');
        finalPhotoPath = cloudUrl ?? localSaved; // Preferred cloud, fallback local
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      final TripModel newTrip;
      if (widget.tripId != null) {
        final existing = store.trips.firstWhere((t) => t.id == widget.tripId);
        newTrip = TripModel(
          id: existing.id,
          name: _nameController.text,
          destination: _destinationController.text,
          startDate: _startDate!,
          endDate: _endDate!,
          totalBudget:
              double.tryParse(_budgetController.text) ?? existing.totalBudget,
          currency: store.currentCurrency, // Inherit current currency on update
          coverPhoto: finalPhotoPath ?? existing.coverPhoto,
          companions: _companions,
          itinerary: existing.itinerary,
          expenses: existing.expenses,
          photos: existing.photos,
          markers: existing.markers,
        );
      } else {
        newTrip = TripModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text,
          destination: _destinationController.text,
          startDate: _startDate!,
          endDate: _endDate!,
          totalBudget: double.tryParse(_budgetController.text) ?? 500.0,
          currency: store.currentCurrency, // Correctly use the selected currency
          coverPhoto: finalPhotoPath,
          companions: _companions,
        );
      }

      if (widget.tripId != null) {
        final index = store.trips.indexWhere((t) => t.id == widget.tripId);
        store.trips[index] = newTrip;
      } else {
        store.trips.insert(0, newTrip);
      }
      await store.saveToDisk();

      if (mounted) {
        if (Navigator.of(context).canPop()) {
           Navigator.of(context).pop();
        } else {
           context.go('/');
        }
      }
    } else if (_startDate == null || _endDate == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please define your journey timeframe.')),
      );
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
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'SAVE',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
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
                stylusHandwritingEnabled: false,
controller: _nameController,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                decoration: InputDecoration(
                  labelText: 'Adventure Name',
                  hintText: 'e.g. Kyoto Explorer 2026',
                  prefixIcon: const Icon(Icons.drive_file_rename_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Enter a name for your journey.'
                    : null,
                
              ),
              const Gap(16),
              TextFormField(
                stylusHandwritingEnabled: false,
controller: _destinationController,
                decoration: InputDecoration(
                  labelText: 'Destination',
                  prefixIcon: const Icon(Icons.explore_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Where are we going?' : null,
                
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
              ListenableBuilder(
                listenable: getIt<InMemoryStore>(),
                builder: (context, _) {
                  return TextFormField(
                    stylusHandwritingEnabled: false,
controller: _budgetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Estimated Budget',
                      prefixIcon: const Icon(Icons.savings_outlined),
                      prefixText: '${getIt<InMemoryStore>().currentCurrency} ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                },
              ),
              const Gap(32),
              _buildCompanionsSection(),
              const Gap(100),
            ],
          ),
        ),
      ),
    );
  }

  final _companionController = TextEditingController();
  List<String> _companions = [];

  Widget _buildCompanionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TRAVEL COMPANIONS',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const Text(
                  'Who is coming with you?',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            Icon(Icons.group_add_outlined, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
          ],
        ),
        const Gap(16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              TextField(
                stylusHandwritingEnabled: false,
controller: _companionController,
                onSubmitted: (value) {
                  final trimmed = value.trim();
                  if (trimmed.isNotEmpty && !_companions.contains(trimmed)) {
                    setState(() {
                      _companions.add(trimmed);
                      _companionController.clear();
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Add a friend\'s name...',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      final trimmed = _companionController.text.trim();
                      if (trimmed.isNotEmpty && !_companions.contains(trimmed)) {
                        setState(() {
                          _companions.add(trimmed);
                          _companionController.clear();
                        });
                      }
                    },
                  ),
                  border: InputBorder.none,
                ),
              ),
              if (_companions.isNotEmpty) ...[
                const Divider(),
                const Gap(8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _companions.asMap().entries.map((entry) {
                    return Chip(
                      label: Text(entry.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onDeleted: () => setState(() => _companions.removeAt(entry.key)),
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
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
            Text(
              isStart ? 'Starts' : 'Returns',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const Gap(4),
            Text(
              date == null ? 'Set Date' : DateFormat('MMM d, y').format(date),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: date == null
                    ? Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.3)
                    : Theme.of(context).colorScheme.onSurface,
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
                  image: _coverPhotoUrl!.startsWith('http')
                      ? NetworkImage(_coverPhotoUrl!)
                      : FileImage(File(_coverPhotoUrl!)) as ImageProvider,
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _coverPhotoUrl == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 56,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.2),
                  ),
                  const Gap(12),
                  const Text(
                    'Inspire your Journey',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const Text(
                    'Upload a cover photo',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              )
            : Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
