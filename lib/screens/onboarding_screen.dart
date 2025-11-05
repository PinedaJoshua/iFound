import 'package:flutter/material.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:flutter_application_1/theme/auth_gate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  bool _isLastPage = false;

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showOnboarding', false);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthGate()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _isLastPage = (index == 2);
                  });
                },
                children: const [
                  OnboardingPage(
                    image: 'assets/images/onboarding 1.png',
                    title: 'Find. Return. Connect.',
                    subtitle:
                        'iFound makes it easy for USTP students to report, find, and return lost items around the campus.',
                  ),
                  OnboardingPage(
                    image: 'assets/images/onboarding 2.png',
                    title: 'Earn Points and Badges!',
                    subtitle:
                        'Help others find their belongings and get rewarded with badges and points for every good deed you do.',
                  ),
                  OnboardingPage(
                    image: 'assets/images/onboarding 3.png',
                    title: 'Chat. Report. Recover.',
                    subtitle:
                        'Use our peer-to-peer chat to contact finders or owners directly—making item recovery fast and secure.',
                  ),
                ],
              ),
            ),
            
            // FIX 5: Centered the bottom navigation section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: 3,
                    effect: const WormEffect(
                      dotHeight: 10,
                      dotWidth: 10,
                      activeDotColor: AppTheme.primaryColor,
                      dotColor: AppTheme.lightTextColor,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _isLastPage
                      ?
                      // "Get Started" Button on last page
                      SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _completeOnboarding,
                            child: const Text('Get Started'),
                          ),
                        )
                      :
                      // "Next" Button on other pages
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Text('Next'),
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
}

// Helper Widget for each onboarding page
class OnboardingPage extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;

  const OnboardingPage({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(image, height: 300),
          const SizedBox(height: 48),
          Text(
            title,
            // FIX 5: Applied League Spartan font and color
            style: GoogleFonts.leagueSpartan(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF141449), // AppTheme.primaryColor
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            // FIX 5: Applied Inter Medium font
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500, // Inter Medium
              color: AppTheme.darkTextColor.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}