// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../../core/in_memory_store.dart';
import '../../../../main.dart';

class MemoryDetailScreen extends StatelessWidget {
  final PhotoModel photo;
  final bool showViewTrip;

  const MemoryDetailScreen({
    super.key, 
    required this.photo, 
    this.showViewTrip = true,
  });

  @override
  Widget build(BuildContext context) {
    final store = getIt<InMemoryStore>();
    final matchedTrip = photo.tripId != null
        ? store.trips.where((t) => t.id == photo.tripId).firstOrNull
        : null;

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
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Full Screen Photo
            GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity! > 500) context.pop();
              },
              child: Hero(
                tag: 'memory_photo_${photo.id}',
                child: photo.url.startsWith('http')
                    ? Image.network(photo.url, fit: BoxFit.cover, alignment: Alignment.center)
                    : Image.file(File(photo.url), fit: BoxFit.cover, alignment: Alignment.center),
              ),
            ),
            
            // 2. Top Bar (X and Delete)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 40, left: 16, right: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => context.pop(),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white70, size: 28),
                      onPressed: () => _confirmDelete(context),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Floating Journey Card at Bottom
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (matchedTrip != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              matchedTrip.destination.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const Gap(12),
                          Text(
                            matchedTrip.name,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ] else ...[
                          const Text(
                            "UNLINKED MEMORY",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Gap(12),
                    Text(
                      photo.caption ?? "A timeless capture.",
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Gap(24),
                    if (matchedTrip != null && showViewTrip)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: () {
                             context.pop(); // Close current detail
                             context.push('/trip/${matchedTrip.id}');
                          },
                          icon: const Icon(Icons.arrow_right_alt, color: Colors.black87),
                          label: const Text(
                            'View Trip',
                            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.grey.shade50,
                            side: BorderSide(color: Colors.grey.shade200),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
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
      await store.deletePhoto(photo.id);
      if (context.mounted) context.pop();
    }
  }
}
