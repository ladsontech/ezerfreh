import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ezer_fresh/src/core/providers/providers.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Fresh Farm\nProduce Daily',
      description: 'Get the freshest vegetables and fruits delivered straight from local organic farms to your kitchen.',
      image: 'assets/onboarding/fresh.png',
    ),
    OnboardingData(
      title: 'Crisp & Fast\nDelivery',
      description: 'Our dedicated riders ensure your organic produce reaches you while it is still crisp, cool, and fresh.',
      image: 'assets/onboarding/delivery.png',
    ),
    OnboardingData(
      title: 'Worry-Free\nEasy Payments',
      description: 'Secure and seamless payment options for a simple and modern grocery shopping experience.',
      image: 'assets/onboarding/payment.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F4), // Warm Organic Cream Background
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar for Skipper
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: _currentPage < _pages.length - 1
                    ? TextButton(
                        onPressed: () async {
                          await ref.read(onboardingCompletedProvider.notifier).completeOnboarding();
                          if (context.mounted) {
                            context.go('/home');
                          }
                        },
                        child: Text(
                          'Skip',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF7A7F7A),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : const SizedBox(height: 48),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) => _OnboardingPage(data: _pages[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dot Indicators
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => _buildIndicator(index == _currentPage),
                    ),
                  ),
                  // Navigation Button
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _currentPage == _pages.length - 1
                        ? ElevatedButton(
                            key: const ValueKey('start_btn'),
                            onPressed: () async {
                              await ref.read(onboardingCompletedProvider.notifier).completeOnboarding();
                              if (context.mounted) {
                                context.go('/home');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Get Started',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, size: 18),
                              ],
                            ),
                          )
                        : Container(
                            key: const ValueKey('next_btn'),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2E7D32),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () => _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              ),
                              padding: const EdgeInsets.all(16),
                              icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 24),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      height: 6,
      width: isActive ? 24 : 6,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2E7D32) : const Color(0xFFE5E4DC),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final String image;

  OnboardingData({required this.title, required this.description, required this.image});
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingData data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Graphic Backdrop & Image
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Soft organic round shadow backing
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F2EA), // A shade darker than scaffold for subtle contrast
                    borderRadius: BorderRadius.circular(130),
                  ),
                ),
                Image.asset(
                  data.image,
                  height: 240,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          Text(
            data.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1B3D25), // Rich Matcha Dark Green
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data.description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              color: const Color(0xFF5E655F),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
