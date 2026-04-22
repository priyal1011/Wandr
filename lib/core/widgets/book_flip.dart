import 'dart:math';
import 'package:flutter/material.dart';

/// A widget that performs a 3D book-flip or card-flip animation.
/// Used to reveal the "story" behind a memory card.
class BookFlip extends StatefulWidget {
  final Widget front;
  final Widget back;
  final Duration duration;
  final bool isFlipped;

  const BookFlip({
    super.key,
    required this.front,
    required this.back,
    this.duration = const Duration(milliseconds: 800),
    this.isFlipped = false,
  });

  @override
  State<BookFlip> createState() => _BookFlipState();
}

class _BookFlipState extends State<BookFlip> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    if (widget.isFlipped) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(BookFlip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped != oldWidget.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final rotation = _animation.value * pi;
        final isFront = rotation < pi / 2;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012) // Perspective effect
            ..rotateY(rotation),
          alignment: Alignment.center,
          child: isFront
              ? widget.front
              : Transform(
                  // Flip the back widget so it's not mirrored
                  transform: Matrix4.identity()..rotateY(pi),
                  alignment: Alignment.center,
                  child: widget.back,
                ),
        );
      },
    );
  }
}
