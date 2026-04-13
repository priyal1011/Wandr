import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart' as spi;
import '../../../../core/in_memory_store.dart';
import '../../../../main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingData> _slides = [
    OnboardingData(
      title: 'Welcome to Wandr',
      subtitle: 'Your personal travel journal for unforgettable adventures.',
      image: 'assets/images/onboarding_1.jpg',
    ),
    OnboardingData(
      title: 'Preserve Moments',
      subtitle: 'Capture photos, manage budgets, and trace your journey on the map.',
      image: 'assets/images/onboarding_2.jpg',
    ),
    OnboardingData(
      title: 'Explore Together',
      subtitle: 'Every trip is a story. Start writing yours today.',
      image: 'assets/images/onboarding_3.jpg',
    ),
  ];

  void _onDone() {
    getIt<InMemoryStore>().hasSeenOnboarding = true;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastPage = _currentIndex == _slides.length - 1;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _slides[index].image,
                    fit: BoxFit.cover,
                  ).animate(key: ValueKey(index)).fade(duration: 800.ms).scale(begin: const Offset(1.1, 1.1), end: const Offset(1.0, 1.0), duration: 1000.ms),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.0),
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Content Layer
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 3),
                  Animate(
                    key: ValueKey(_currentIndex),
                    effects: const [FadeEffect(duration: Duration(milliseconds: 600)), SlideEffect(begin: Offset(0, 0.05))],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _slides[_currentIndex].title,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            height: 1.1,
                          ),
                        ),
                        const Gap(16),
                        Text(
                          _slides[_currentIndex].subtitle,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                            height: 1.6,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      spi.SmoothPageIndicator(
                        controller: _pageController,
                        count: _slides.length,
                        effect: spi.ExpandingDotsEffect(
                          spacing: 8.0,
                          radius: 12.0,
                          dotWidth: 12.0,
                          dotHeight: 8.0,
                          dotColor: Colors.white.withValues(alpha: 0.3),
                          activeDotColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 24),
                      ElevatedButton(
                        onPressed: () {
                          if (isLastPage) {
                            _onDone();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.fastOutSlowIn,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(isLastPage ? 'Get Started' : 'Next', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Icon(isLastPage ? Icons.rocket_launch : Icons.arrow_forward, size: 18),
                          ],
                        ),
                      ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final String image;

  OnboardingData({required this.title, required this.subtitle, required this.image});
}
