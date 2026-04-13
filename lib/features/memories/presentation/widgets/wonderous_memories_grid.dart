import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../../../../core/in_memory_store.dart';
import '../../../../core/utils/haptic_feedback_helper.dart';
import '../../../../main.dart';

class WonderousMemoriesGrid extends StatefulWidget {
  final List<PhotoModel> photos;
  const WonderousMemoriesGrid({super.key, required this.photos});

  @override
  State<WonderousMemoriesGrid> createState() => _WonderousMemoriesGridState();
}

class _WonderousMemoriesGridState extends State<WonderousMemoriesGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentIndex = 0;
  Offset _panOffset = Offset.zero;
  final int _crossAxisCount = 3; 

  final double _itemWidth = 280;
  final double _itemHeight = 420;
  final double _spacing = 15;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.photos.isNotEmpty) {
      _currentIndex = (widget.photos.length / 2).floor();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _getOffsetForIndex(int index, Size screenSize) {
    if (widget.photos.isEmpty) return Offset.zero;

    final row = index ~/ _crossAxisCount;
    final col = index % _crossAxisCount;

    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;

    final itemX = col * (_itemWidth + _spacing) + _itemWidth / 2;
    final itemY = row * (_itemHeight + _spacing) + _itemHeight / 2;

    return Offset(centerX - itemX, centerY - itemY);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _panOffset += details.delta;
    });
  }

  void _handlePanEnd(DragEndDetails details, Size screenSize) {
    final velocity = details.velocity.pixelsPerSecond;
    int newIndex = _currentIndex;

    final row = _currentIndex ~/ _crossAxisCount;
    final col = _currentIndex % _crossAxisCount;
    final totalRows = (widget.photos.length / _crossAxisCount).ceil();

    if (velocity.distance > 300) {
      if (velocity.dx.abs() > velocity.dy.abs()) {
        if (velocity.dx > 0 && col > 0) {
          newIndex--;
        } else if (velocity.dx < 0 &&
            col < _crossAxisCount - 1 &&
            _currentIndex < widget.photos.length - 1) {
          newIndex++;
        }
      } else {
        if (velocity.dy > 0 && row > 0) {
          newIndex -= _crossAxisCount;
        } else if (velocity.dy < 0 && row < totalRows - 1) {
          final potentialIndex = _currentIndex + _crossAxisCount;
          if (potentialIndex < widget.photos.length) {
            newIndex = potentialIndex;
          }
        }
      }
    }

    if (newIndex != _currentIndex) {
      HapticHelper.light();
    }

    _animateTo(newIndex, screenSize);
  }

  void _animateTo(int index, Size screenSize) {
    final start = _getOffsetForIndex(_currentIndex, screenSize) + _panOffset;
    final end = _getOffsetForIndex(index, screenSize);

    final animation = Tween<Offset>(
      begin: start,
      end: end,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _currentIndex = index;
    _controller.reset();
    _controller.forward();

    animation.addListener(() {
      setState(() {
        _panOffset =
            animation.value - _getOffsetForIndex(_currentIndex, screenSize);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photos.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = Size(constraints.maxWidth, constraints.maxHeight);
        final baseOffset = _getOffsetForIndex(_currentIndex, screenSize);
        final currentOffset = baseOffset + _panOffset;

        return GestureDetector(
          onPanUpdate: _handlePanUpdate,
          onPanEnd: (d) => _handlePanEnd(d, screenSize),
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/memory/${widget.photos[_currentIndex].id}');
          },
          behavior: HitTestBehavior.translucent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Transform.translate(offset: currentOffset, child: _buildGrid()),
              IgnorePointer(
                child: _AnimatedCutoutOverlay(
                  targetWidth: _itemWidth * 1.1,
                  targetHeight: _itemHeight * 1.1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrid() {
    return OverflowBox(
      maxWidth: double.infinity,
      maxHeight: double.infinity,
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: _crossAxisCount * (_itemWidth + _spacing),
        height:
            ((widget.photos.length / _crossAxisCount).ceil()) *
            (_itemHeight + _spacing),
        child: Stack(
          children: List.generate(widget.photos.length, (index) {
            final row = index ~/ _crossAxisCount;
            final col = index % _crossAxisCount;
            final photo = widget.photos[index];
            final isSelected = index == _currentIndex;

            return Positioned(
              left: col * (_itemWidth + _spacing),
              top: row * (_itemHeight + _spacing),
              width: _itemWidth,
              height: _itemHeight,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: isSelected ? 1.0 : 0.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutQuart,
                builder: (context, selectionValue, child) {
                  final double scale = 0.9 + (selectionValue * 0.15); 

                  return Transform(
                    transform: Matrix4.diagonal3Values(scale, scale, 1.0)
                      ..setEntry(3, 2, 0.001) 
                      ..rotateX(isSelected ? 0 : 0.1) 
                      ..rotateY(isSelected ? 0 : (col < 1 ? 0.2 : col > 1 ? -0.2 : 0)),
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () {
                        if (isSelected) {
                          HapticFeedback.lightImpact();
                          context.push('/memory/${photo.id}');
                        } else {
                          _currentIndex = index;
                          HapticFeedback.lightImpact();
                          setState(() {});
                        }
                      },
                      child: _PhotoCard(
                        photo: photo,
                        isSelected: isSelected,
                      ),
                    ).animate(delay: Duration(milliseconds: index * 50))
                     .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                     .slideY(begin: 0.2, end: 0, curve: Curves.easeOutBack),
                  );
                },
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final PhotoModel photo;
  final bool isSelected;
  const _PhotoCard({required this.photo, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final store = getIt<InMemoryStore>();
    final matchedTrip = photo.tripId != null
        ? store.trips.where((t) => t.id == photo.tripId).firstOrNull
        : null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: isSelected ? 0.3 : 0.1),
            blurRadius: isSelected ? 40 : 15,
            offset: Offset(0, isSelected ? 20 : 8),
            spreadRadius: isSelected ? -5 : 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          Hero(
            tag: 'memory_photo_${photo.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Builder(
                builder: (context) {
                  final String fallback = 'https://images.unsplash.com/photo-${1501785888041 + (photo.id.hashCode % 10000)}?q=80&w=800&auto=format&fit=crop';
                  
                  Widget netImg(String url, {bool isFallback = false}) => Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        url,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Image.network(
                          'https://images.unsplash.com/photo-1501785888041-af3ef285b470?q=80&w=1000&auto=format&fit=crop',
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (isFallback)
                        Container(
                          color: Colors.black.withValues(alpha: 0.2),
                          child: const Center(
                            child: Icon(Icons.cloud_sync_outlined, color: Colors.white54, size: 30),
                          ),
                        ),
                    ],
                  );

                  if (photo.url.startsWith('http')) {
                    return netImg(photo.url);
                  }
                  
                  final file = File(photo.url);
                  if (file.existsSync()) {
                    return Image.file(
                      file,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => netImg(fallback, isFallback: true),
                    );
                  } else {
                    return netImg(fallback, isFallback: true);
                  }
                },
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (matchedTrip != null)
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 10, color: Theme.of(context).colorScheme.secondary),
                        const Gap(4),
                        Text(
                          matchedTrip.name.toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  const Gap(4),
                  Text(
                    photo.caption ?? "Journey Moment",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          if (isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AnimatedCutoutOverlay extends StatelessWidget {
  final double targetWidth;
  final double targetHeight;
  const _AnimatedCutoutOverlay({required this.targetWidth, required this.targetHeight});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _CutoutClipper(targetWidth: targetWidth, targetHeight: targetHeight),
      child: Container(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
    );
  }
}

class _CutoutClipper extends CustomClipper<Path> {
  final double targetWidth;
  final double targetHeight;
  _CutoutClipper({required this.targetWidth, required this.targetHeight});

  @override
  Path getClip(Size size) {
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutRect = Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: targetWidth, height: targetHeight);
    path.addRRect(RRect.fromRectAndRadius(cutoutRect, const Radius.circular(30)));
    path.fillType = PathFillType.evenOdd;
    return path;
  }
  @override
  bool shouldReclip(_CutoutClipper oldClipper) => oldClipper.targetWidth != targetWidth || oldClipper.targetHeight != targetHeight;
}
