import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/in_memory_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../main.dart';

class MemoryDetailScreen extends StatelessWidget {
  final PhotoModel photo;

  const MemoryDetailScreen({super.key, required this.photo});

  @override
  Widget build(BuildContext context) {
    final store = getIt<InMemoryStore>();
    final matchedTrip = photo.tripId != null 
        ? store.trips.where((t) => t.id == photo.tripId).firstOrNull 
        : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full Screen Photo (Edge-to-Edge)
          GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! > 500) context.pop();
            },
            child: Hero(
              tag: 'memory_photo_${photo.id}',
              child: photo.url.startsWith('http')
                  ? Image.network(
                      photo.url, 
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(color: Colors.black, child: const Center(child: Icon(Icons.broken_image, color: Colors.white24, size: 48))),
                    )
                  : Image.file(
                      File(photo.url), 
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(color: Colors.black, child: const Center(child: Icon(Icons.broken_image, color: Colors.white24, size: 48))),
                    ),
            ),
          ),
          
          // 2. Translucent Luxe Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 40, left: 16, right: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black54, Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white70, size: 24),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Memory?'),
                          content: const Text('This photo will be permanently removed from your journey.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        final store = getIt<InMemoryStore>();
                        await store.deletePhoto(photo.id);
                        if (context.mounted) context.pop();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // 3. Floating Detail Card (Airbnb Style)
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 40, offset: const Offset(0, 20)),
                ],
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (matchedTrip != null) ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.darkBackground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              matchedTrip.destination.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                            ),
                          ),
                          const Gap(10),
                          Text(
                            matchedTrip.name,
                            style: TextStyle(color: Colors.black.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const Gap(16),
                    ],
                    Text(
                      photo.caption ?? "A timeless capture of this journey.",
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Gap(24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              if (photo.tripId != null) context.push('/trip/${photo.tripId}');
                            },
                            icon: const Icon(Icons.arrow_forward_outlined, color: Colors.black),
                            label: const Text("View Trip", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate().slideY(begin: 0.5, curve: Curves.easeOutQuart).fadeIn(duration: 600.ms),
          ),
        ],
      ),
      ),
    );
  }
}
