import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/in_memory_store.dart';

import 'package:google_fonts/google_fonts.dart';

class MemoryLightBox extends StatelessWidget {
  final PhotoModel photo;
  const MemoryLightBox({super.key, required this.photo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Full Screen Photo (Edge-to-Edge)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity! > 500) Navigator.pop(context);
              },
              child: Hero(
                tag: 'memory_lightbox_${photo.id}',
                child: photo.url.startsWith('http')
                    ? Image.network(
                        photo.url,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stk) => Container(
                          color: Colors.black,
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.white24,
                              size: 48,
                            ),
                          ),
                        ),
                      )
                    : Image.file(
                        File(photo.url),
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stk) => Container(
                          color: Colors.black,
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.white24,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
              ),
            ),

            // 2. Header
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white70,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // 3. Caption (Bottom - Just like onboarding)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  left: 32,
                  right: 32,
                  top: 40,
                  bottom: MediaQuery.of(context).padding.bottom + 40,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      photo.caption ?? "A glimpse from your journey.",
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        height: 1.1,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
