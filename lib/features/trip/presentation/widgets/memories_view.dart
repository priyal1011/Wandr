// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:wandr/models/trip_model.dart';
import 'package:wandr/models/photo_model.dart';

class MemoriesView extends StatefulWidget {
  final TripModel trip;
  final Function(List<PhotoModel>) onUpdate;

  const MemoriesView({
    super.key,
    required this.trip,
    required this.onUpdate,
  });

  @override
  State<MemoriesView> createState() => MemoriesViewState();
}

class MemoriesViewState extends State<MemoriesView> {
  late List<PhotoModel> _photos;

  @override
  void initState() {
    super.initState();
    _photos = widget.trip.photos ?? [];
  }

  Future<void> addPhoto() async {
    _showAddMemoryDialog();
  }

  void _showAddMemoryDialog() {
    final captionController = TextEditingController();
    final notesController = TextEditingController();
    String? selectedPath;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('New Memory', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                      if (image != null) setDialogState(() => selectedPath = image.path);
                    },
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: selectedPath == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey),
                                Gap(8),
                                Text('Tap to Upload Photo', style: TextStyle(color: Colors.grey)),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(File(selectedPath!), fit: BoxFit.cover),
                            ),
                    ),
                  ),
                  const Gap(20),
                  TextField(
                    controller: captionController,
                    decoration: InputDecoration(
                      labelText: 'Caption (Optional)',
                      hintText: 'A timeless capture...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const Gap(16),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Story Notes (Optional)',
                      hintText: 'Tell the story...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selectedPath == null ? null : () {
                final newPhoto = PhotoModel(
                  id: const Uuid().v4(),
                  tripId: widget.trip.id,
                  url: selectedPath!,
                  caption: captionController.text.trim(),
                  notes: notesController.text.trim(),
                );

                setState(() {
                  _photos = [..._photos, newPhoto];
                  widget.onUpdate(_photos);
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save Memory'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_photos.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        return _buildPhotoCard(_photos[index], index);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
          const Gap(16),
          Text('No memories captured yet.', 
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(PhotoModel photo, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => context.push('/memory/${photo.id}?fromTrip=true'),
      child: Hero(
        tag: 'memory_photo_${photo.id}',
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
            boxShadow: !isDark ? [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))] : [],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              photo.url.startsWith('http')
                  ? Image.network(photo.url, fit: BoxFit.cover)
                  : Image.file(File(photo.url), fit: BoxFit.cover),
              
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _photos.removeAt(index);
                      widget.onUpdate(_photos);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ),
              
              if (photo.caption != null && photo.caption!.isNotEmpty)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                      ),
                    ),
                    child: Text(
                      photo.caption!,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).scale();
  }
}
