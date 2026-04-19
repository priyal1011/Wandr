import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/in_memory_store.dart';
import '../../../../main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  int _currentIndex = 0;
  bool _isAnimating = false;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: 'The World is Yours\nto Wandr.',
      subtitle: 'Swipe up to begin your journey.',
      image: 'assets/images/onboarding/onboarding_cafe.jpg',
      direction: SwipeDirection.up,
    ),
    OnboardingSlide(
      title: 'Preserve Every\nMoment.',
      subtitle: 'Swipe left to continue.',
      image: 'assets/images/onboarding/onboarding_custom.jpg',
      direction: SwipeDirection.left,
    ),
    OnboardingSlide(
      title: 'Your Story,\nStart Today.',
      subtitle: 'Swipe down to enter.',
      image: 'assets/images/onboarding/onboarding_road.jpg',
      direction: SwipeDirection.down,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutQuart),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleVerticalDrag(DragUpdateDetails details) {
    if (_isAnimating) return;
    final slide = _slides[_currentIndex];
    
    if (slide.direction == SwipeDirection.up && details.delta.dy < -5) {
      _triggerTransition();
    } else if (slide.direction == SwipeDirection.down && details.delta.dy > 5) {
      _triggerTransition();
    }
  }

  void _handleHorizontalDrag(DragUpdateDetails details) {
    if (_isAnimating) return;
    final slide = _slides[_currentIndex];
    
    if (slide.direction == SwipeDirection.left && details.delta.dx < -5) {
      _triggerTransition();
    }
  }

  Future<void> _triggerTransition() async {
    setState(() => _isAnimating = true);
    
    if (_currentIndex == _slides.length - 1) {
      await _animController.forward();
      getIt<InMemoryStore>().hasSeenOnboarding = true;
      if (mounted) context.go('/login');
    } else {
      await _animController.forward();
      setState(() {
        _currentIndex++;
        _isAnimating = false;
      });
      _animController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentIndex];
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: _handleVerticalDrag,
        onHorizontalDragUpdate: _handleHorizontalDrag,
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // 1. DYNAMIC BACKGROUND
                Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: 1.0 + (0.2 * _slideAnimation.value),
                    child: Image.asset(
                      slide.image,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),

                // 2. MODERN OVERLAY
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),

                // 3. MINIMAL CONTENT
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),
                        Opacity(
                          opacity: _fadeAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, -50 * _slideAnimation.value),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  slide.title,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: size.width > 600 ? 64 : 44,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -1.5,
                                    height: 1.0,
                                  ),
                                ),
                                const Gap(20),
                                Text(
                                  slide.subtitle.toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 4.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 4. TRANSITION HINT (Subtle)
                if (!_isAnimating)
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Icon(
                        _getIconForDirection(slide.direction),
                        color: Colors.white.withValues(alpha: 0.3),
                        size: 30,
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .move(begin: _getOffsetForDirection(slide.direction), 
                            end: Offset.zero, 
                            duration: 1200.ms, 
                            curve: Curves.easeInOut),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  IconData _getIconForDirection(SwipeDirection dir) {
    return switch (dir) {
      SwipeDirection.up => Icons.keyboard_arrow_up_rounded,
      SwipeDirection.left => Icons.keyboard_arrow_left_rounded, // Corrected to point left
      SwipeDirection.down => Icons.keyboard_arrow_down_rounded,
    };
  }

  Offset _getOffsetForDirection(SwipeDirection dir) {
    return switch (dir) {
      SwipeDirection.up => const Offset(0, 10),
      SwipeDirection.left => const Offset(10, 0), // Bounce from right to emphasize left swipe
      SwipeDirection.down => const Offset(0, -10),
    };
  }
}

enum SwipeDirection { up, left, down }

class OnboardingSlide {
  final String title;
  final String subtitle;
  final String image;
  final SwipeDirection direction;

  OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.direction,
  });
}
