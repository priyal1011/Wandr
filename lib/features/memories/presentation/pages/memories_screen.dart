import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/in_memory_store.dart';
import '../../../../main.dart';
import '../../../../core/widgets/interactive_dialog.dart';

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {

  @override
  Widget build(BuildContext context) {
    final store = getIt<InMemoryStore>();
    final photos = store.photos;

    // Also gather photos from all trips that aren't already in store.photos
    final allTripPhotos = <PhotoModel>[];
    for (final trip in store.trips) {
      if (trip.photos != null) {
        for (final p in trip.photos!) {
          if (!photos.any((sp) => sp.id == p.id)) {
            allTripPhotos.add(p);
          }
        }
      }
    }
    final combinedPhotos = [...photos, ...allTripPhotos];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Memories', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: combinedPhotos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome_mosaic_outlined, size: 80, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
                  const Gap(16),
                  const Text('No memories captured yet.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Gap(8),
                  Text('Go to a trip or tap + to add moments!', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: combinedPhotos.length,
              itemBuilder: (context, index) {
                final photo = combinedPhotos[index];
                final tripMatch = store.trips.where((t) => t.id == photo.tripId);
                final trip = tripMatch.isNotEmpty ? tripMatch.first : (store.trips.isNotEmpty ? store.trips.first : null);
                final tripName = trip?.name ?? 'Journey';
                return _MemoryCard(photo: photo, tripName: tripName)
                    .animate(delay: Duration(milliseconds: index * 60))
                    .fadeIn(duration: 400.ms)
                    .scale(begin: const Offset(0.92, 0.92), duration: 400.ms, curve: Curves.easeOutBack);
              },
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          onPressed: _addGlobalMemory,
          label: const Text('Add Memory', style: TextStyle(fontWeight: FontWeight.bold)),
          icon: const Icon(Icons.add_photo_alternate_outlined),
        ),
      ).animate().scale(delay: 500.ms, curve: Curves.easeOutBack),
    );
  }

  void _addGlobalMemory() {
    final store = getIt<InMemoryStore>();
    final tripNameCtrl = TextEditingController();
    final captionCtrl = TextEditingController();
    String? pickedFilePath;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => InteractiveDialog(
          title: 'Preserve Memory',
          icon: Icons.auto_awesome_outlined,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               GestureDetector(
                onTap: () async {
                   final ImagePicker picker = ImagePicker();
                   final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                   if (image != null) setDialogState(() => pickedFilePath = image.path);
                },
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    image: pickedFilePath != null ? DecorationImage(image: FileImage(File(pickedFilePath!)), fit: BoxFit.cover) : null,
                  ),
                  child: pickedFilePath == null ? const Icon(Icons.add_a_photo_outlined, color: Colors.grey) : null,
                ),
              ),
              const Gap(16),
              TextField(
                controller: tripNameCtrl,
                decoration: InputDecoration(
                  labelText: 'Trip Name',
                  hintText: 'e.g. Summer in Tokyo',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const Gap(16),
              TextField(
                controller: captionCtrl,
                decoration: InputDecoration(
                  labelText: 'Caption (Optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: (pickedFilePath == null) ? null : () {
                final tripMatch = store.trips.where(
                  (t) => t.name.toLowerCase() == tripNameCtrl.text.toLowerCase(),
                );
                if (tripMatch.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip not found. Please enter an exact trip name.')));
                  return;
                }
                final trip = tripMatch.first;

                final newPhoto = PhotoModel(
                  id: DateTime.now().toString(),
                  tripId: trip.id,
                  url: pickedFilePath!,
                  caption: captionCtrl.text.isEmpty ? null : captionCtrl.text,
                );

                setState(() {
                  store.photos.insert(0, newPhoto);
                  if (trip.photos == null) {
                    trip.photos = [newPhoto];
                  } else {
                    trip.photos!.insert(0, newPhoto);
                  }
                });
                store.saveToDisk();
                context.pop();
              },
              child: const Text('Save Memory'),
            ),
          ],
        ),
      ),
    ).catchError((e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
       }
    });
  }
}

class _MemoryCard extends StatelessWidget {
  final PhotoModel photo;
  final String tripName;
  const _MemoryCard({required this.photo, required this.tripName});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: photo.url.startsWith('http')
                  ? Image.network(photo.url, fit: BoxFit.cover, width: double.infinity, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade300, child: const Icon(Icons.broken_image, color: Colors.grey)))
                  : Image.file(File(photo.url), fit: BoxFit.cover, width: double.infinity, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade300, child: const Icon(Icons.broken_image, color: Colors.grey))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  photo.caption ?? 'Travel Moment',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Gap(4),
                Text(
                  tripName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension AnimateExtension on Animate {
  // Added a custom helper for slide + scale
  Animate slideScale({required Offset begin}) => slide(begin: begin).scale(begin: const Offset(0.95, 0.95));
}
