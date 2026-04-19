import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skeletonizer/skeletonizer.dart';

class WandrImage extends StatelessWidget {
  final String? source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String heroTag;

  const WandrImage({
    super.key,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.heroTag = '',
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (source == null || source!.isEmpty) {
      imageWidget = _buildPlaceholder();
    } else if (source!.startsWith('http')) {
      imageWidget = CachedNetworkImage(
        imageUrl: source!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => Skeletonizer(
          enabled: true,
          child: Container(
            width: width ?? double.infinity,
            height: height ?? double.infinity,
            color: Colors.grey.shade900,
          ),
        ),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    } else if (source!.startsWith('assets/')) {
      imageWidget = Image.asset(
        source!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else {
      // Treat as local file path
      final file = File(source!);
      if (file.existsSync()) {
        imageWidget = Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      } else {
        imageWidget = _buildPlaceholder();
      }
    }

    if (heroTag.isNotEmpty) {
      imageWidget = Hero(tag: heroTag, child: imageWidget);
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined, color: Colors.white24, size: 32),
      ),
    );
  }
}
