import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/in_memory_store.dart';
import '../../../../main.dart';
import '../../../../core/widgets/interactive_dialog.dart';
import '../../../../core/utils/file_utils.dart'; // Added
import '../../../../core/utils/haptic_feedback_helper.dart';
import '../../../../core/services/storage_service.dart';

import '../widgets/wonderous_memories_grid.dart';

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {

  @override
  Widget build(BuildContext context) {
    final store = getIt<InMemoryStore>();

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
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
          backgroundColor: Theme.of(context).colorScheme.surface,
          extendBody: true,
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
              : WonderousMemoriesGrid(photos: combinedPhotos),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 110),
            child: FloatingActionButton(
              onPressed: _addGlobalMemory,
              elevation: 8,
              child: const Icon(Icons.add_photo_alternate_outlined),
            ),
          ).animate().scale(delay: 500.ms, curve: Curves.easeOutBack),
        );
      },
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
              onPressed: (pickedFilePath == null) ? null : () async {
                // Show uploading hint
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('☁️ Syncing memory to cloud...'), duration: Duration(seconds: 2)),
                );

                final finalPath = await FileUtils.saveFilePersistently(pickedFilePath!);
                final String? cloudUrl = await StorageService.uploadImage(finalPath, 'memories');
                
                final inputTripName = tripNameCtrl.text.trim();
                final tripMatch = store.trips.where(
                  (t) => t.name.toLowerCase() == inputTripName.toLowerCase(),
                );
                
                final matchedTrip = inputTripName.isNotEmpty && tripMatch.isNotEmpty ? tripMatch.first : null;

                final newPhoto = PhotoModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  tripId: matchedTrip?.id,
                  url: cloudUrl ?? finalPath,
                  caption: captionCtrl.text.isEmpty ? null : captionCtrl.text,
                );

                setState(() {
                  store.photos.insert(0, newPhoto);
                  if (matchedTrip != null) {
                    if (matchedTrip.photos == null) {
                      matchedTrip.photos = [newPhoto];
                    } else {
                      matchedTrip.photos!.insert(0, newPhoto);
                    }
                  }
                });
                store.saveToDisk();
                HapticHelper.success();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  context.pop();
                }
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
