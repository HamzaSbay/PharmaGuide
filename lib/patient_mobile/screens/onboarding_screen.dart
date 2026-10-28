import 'package:flutter/material.dart';
import '../../core/constants/theme.dart';
import '../../core/services/cache_service.dart';
import 'patient_home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      badge: 'QUI SOMMES-NOUS ?',
      title: 'Bienvenue sur PharmaGuide TN',
      subtitle: 'Le 1er Réseau National d\'Officines en Tunisie',
      description:
          'Un service citoyen innovant conçu pour soulager les patients tunisiens, éliminer le stress du manque de médicaments et réduire les déplacements inutiles entre municipalités.',
      icon: Icons.health_and_safety_outlined,
      gradientColor: AppTheme.pharmacyGreen,
    ),
    OnboardingSlide(
      badge: 'CE QUE NOUS FAISONS',
      title: 'Localisateur de Stock 24/7',
      subtitle: 'Disponibilité Réelle & Tour de Garde',
      description:
          'Recherchez par nom, DCI ou symptôme (Cœur, Yeux, Jambes, Fièvre). Géolocalisez les officines disposant du stock réel, conventions CNAM Tiers-Payant et garde de nuit.',
      icon: Icons.search_rounded,
      gradientColor: AppTheme.pharmacyGreen,
    ),
    OnboardingSlide(
      badge: 'COMMENT ÇA MARCHE',
      title: 'Réservation en 1-Clic (2H)',
      subtitle: 'Blocage Gratuit & Zéro Paiement Web',
      description:
          'Demandez au pharmacien de bloquer votre médicament gratuitement pendant 2h. Retrait et paiement 100% en personne à l\'officine, en conformité totale avec le Ministère de la Santé.',
      icon: Icons.timer_outlined,
      gradientColor: AppTheme.pharmacyGreen,
    ),
    OnboardingSlide(
      badge: 'NOTRE VISION FUTURE',
      title: 'L\'Avenir de la Santé Numérique',
      subtitle: 'Innovation & Réseau B2B en Tunisie',
      description:
          'Bientôt: Ordonnance électronique cryptée (Loi INPDP n° 2004-63), alerte automatique de réapprovisionnement PCT et réseau de dépannage urgent entre pharmacats.',
      icon: Icons.rocket_launch_outlined,
      gradientColor: AppTheme.pharmacyGreen,
    ),
  ];

  void _onFinishOnboarding() {
    CacheService().saveSetting('has_seen_onboarding', true);
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const PatientHomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepBlack,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Hero(
                          tag: 'app_logo',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'assets/images/app_logo.jpg',
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppTheme.pharmacyGreen,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.local_pharmacy, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'PharmaGuide TN',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_currentPage < _slides.length - 1)
                    TextButton(
                      onPressed: _onFinishOnboarding,
                      child: const Text(
                        'Passer',
                        style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),

            // Main PageView Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated Hero Icon Card
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.pharmacyGreen.withValues(alpha: 0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.pharmacyGreen.withValues(alpha: 0.2),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            slide.icon,
                            size: 72,
                            color: AppTheme.pharmacyGreen,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Badge Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.pharmacyGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.pharmacyGreen.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            slide.badge,
                            style: const TextStyle(
                              color: AppTheme.pharmacyGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          slide.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.pharmacyGreen.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Description
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
              ),
            ),

            // Page Indicators & Action Buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Dots Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppTheme.pharmacyGreen
                              : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bottom Navigation Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _slides.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _onFinishOnboarding();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.pharmacyGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == _slides.length - 1 ? 'Commencer' : 'Suivant',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentPage == _slides.length - 1 ? Icons.check_circle : Icons.arrow_forward,
                            size: 20,
                          ),
                        ],
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
}

class OnboardingSlide {
  final String badge;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color gradientColor;

  OnboardingSlide({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.gradientColor,
  });
}
