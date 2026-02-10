import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:salon/AppScreens/loginOption.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  double _scrollOffset = 0.0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _scrollOffset = _pageController.page ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Map<String, String>> _pages = [
    {
      "title": "Marry Queen",
      "description": "Choose your service, select a stylist, and book in seconds.",
      "asset": "assets/bride.png",
      "type": "image"
    },
    {
      "title": "Exclusive Offers",
      "description": "Get notified about discounts and special promotions.",
      "asset": "assets/ManicureTreatment.json",
      "type": "lottie"
    },
    {
      "title": "Manage Your Bookings",
      "description": "View, reschedule, or cancel appointments anytime.",
      "asset": "assets/WomanHair.json",
      "type": "lottie"
    },
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginOption()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF48FB1), Color(0xFFE91E63)],
              ),
            ),
          ),

          // 2. Visual Content (Pushed higher to top: 10%)
          Positioned(
            top: size.height * 0.08, 
            left: 0,
            right: 0,
            child: SizedBox(
              height: size.height * 0.50, // Increased height for larger images
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  double delta = index - _scrollOffset;
                  double moveValue = delta * 120; 

                  return Transform.translate(
                    offset: Offset(moveValue, 0),
                    child: Opacity(
                      opacity: (1 - delta.abs()).clamp(0.0, 1.0),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: _buildVisualAsset(_pages[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 3. Bottom Content (Text & UI)
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Takes only required space
                  children: [
                    // Animated Switcher makes text transitions smoother
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Column(
                        key: ValueKey<int>(_currentPage),
                        children: [
                          Text(
                            _pages[_currentPage]["title"]!,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _pages[_currentPage]["description"]!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildDots(),
                    const SizedBox(height: 30),
                    _buildNextButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualAsset(Map<String, String> page) {
    return page["type"] == "lottie"
        ? Lottie.asset(page["asset"]!, fit: BoxFit.contain)
        : Image.asset(page["asset"]!, fit: BoxFit.contain);
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: _currentPage == index ? 20 : 6,
          decoration: BoxDecoration(
            color: _currentPage == index ? Colors.white : Colors.white38,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return ElevatedButton(
      onPressed: _nextPage,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.pink,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(
        _currentPage == _pages.length - 1 ? "GET STARTED" : "NEXT",
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}