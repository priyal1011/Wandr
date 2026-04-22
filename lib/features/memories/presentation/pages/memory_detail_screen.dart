// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/in_memory_store.dart';
import '../../../../main.dart';
import '../../../../models/photo_model.dart';
import '../../../../core/widgets/interactive_dialog.dart';

class MemoryDetailScreen extends StatefulWidget {
  final PhotoModel photo;
  final bool showViewTrip;

  const MemoryDetailScreen({
    super.key, 
    required this.photo, 
    this.showViewTrip = true,
  });

  @override
  State<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends State<MemoryDetailScreen> {
  late PhotoModel _currentPhoto;

  @override
  void initState() {
    super.initState();
    _currentPhoto = widget.photo;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Full Screen Photo
            GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity! > 500) context.pop();
              },
              child: Hero(
                tag: 'memory_photo_${_currentPhoto.id}',
                child: _currentPhoto.url.startsWith('http')
                    ? Image.network(_currentPhoto.url, fit: BoxFit.cover, alignment: Alignment.center)
                    : Image.file(File(_currentPhoto.url), fit: BoxFit.cover, alignment: Alignment.center),
              ),
            ),
            
            // 2. Dark Overlay Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),

            // 3. Top Action Bar
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 16,
              child: Row(
                children: [
                   IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 28),
                    onPressed: _showEditDialog,
                  ).animate().fadeIn(delay: 400.ms),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white70, size: 28),
                    onPressed: () => _confirmDelete(context),
                  ).animate().fadeIn(delay: 500.ms),
                ],
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => context.pop(),
              ).animate().fadeIn(delay: 500.ms),
            ),

            // 4. Content (Caption & Notes)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentPhoto.caption != null && _currentPhoto.caption!.isNotEmpty 
                              ? _currentPhoto.caption! 
                              : "A timeless capture.",
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.2,
                            height: 1.1,
                          ),
                        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
                        const Gap(0),
                        Text(
                          (_currentPhoto.notes != null && _currentPhoto.notes!.isNotEmpty 
                              ? _currentPhoto.notes! 
                              : "").toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 4.0,
                          ),
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                        
                        // 5. Conditional "View Trip" Card (Only for Global Memories)
                        if (widget.showViewTrip && _currentPhoto.tripId != null) ...[
                          const Gap(8),
                          GestureDetector(
                            onTap: () => context.push('/trip/${_currentPhoto.tripId}'),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.explore_outlined, color: Colors.lightBlueAccent),
                                  const Gap(16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Part of your Journey', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                        Text('View Trip Details', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog() {
    final captionController = TextEditingController(text: _currentPhoto.caption);
    final notesController = TextEditingController(text: _currentPhoto.notes);
    String? tempPath = _currentPhoto.url;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => InteractiveDialog(
          title: 'Refine Memory',
          icon: Icons.auto_awesome_outlined,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                    if (image != null) setDialogState(() => tempPath = image.path);
                  },
                  child: Container(
                    height: 160, // Slightly taller for impact
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: tempPath!.startsWith('http') 
                              ? Image.network(tempPath!, fit: BoxFit.cover)
                              : Image.file(File(tempPath!), fit: BoxFit.cover),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: Colors.black.withValues(alpha: 0.3),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.photo_library_outlined, color: Colors.white, size: 32),
                                Gap(8),
                                Text('Swap Photo', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(24),
                TextField(
                  controller: captionController,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Caption',
                    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const Gap(16),
                TextField(
                  controller: notesController,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'The Full Story',
                    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: Text('Discard', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedPhoto = _currentPhoto.copyWith(
                  url: tempPath,
                  caption: captionController.text,
                  notes: notesController.text,
                );
                
                final store = getIt<InMemoryStore>();
                final idx = store.photos.indexWhere((p) => p.id == updatedPhoto.id);
                if (idx != -1) store.photos[idx] = updatedPhoto;
                
                for (var trip in store.trips) {
                   final pIdx = trip.photos?.indexWhere((p) => p.id == updatedPhoto.id);
                   if (pIdx != null && pIdx != -1) {
                     trip.photos![pIdx] = updatedPhoto;
                   }
                }
                
                await store.saveToDisk();
                setState(() => _currentPhoto = updatedPhoto);
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Memory?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('This photo will be permanently removed from your journey.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final store = getIt<InMemoryStore>();
      await store.deletePhoto(_currentPhoto.id);
      if (context.mounted) context.pop();
    }
  }
}
