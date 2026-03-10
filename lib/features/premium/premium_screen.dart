import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/service_providers.dart';
import '../../providers/user_provider.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _isLoading = false;
  int _selectedPlan = 1; // 0=monthly, 1=yearly

  static const _plans = [
    {'label': 'Monthly', 'price': '\$9.99', 'per': '/month', 'tag': ''},
    {
      'label': 'Yearly',
      'price': '\$4.99',
      'per': '/month',
      'tag': 'BEST VALUE'
    },
  ];

  static const _perks = [
    (
      Icons.favorite_rounded,
      'See Who Likes You',
      'Know exactly who\'s interested before you swipe'
    ),
    (
      Icons.all_inclusive_rounded,
      'Unlimited Swipes',
      'Never run out of swipes again'
    ),
    (
      Icons.replay_rounded,
      'Rewind Last Swipe',
      'Accidentally swiped left? Undo it'
    ),
    (Icons.star_rounded, 'Super Likes', '5 Super Likes per day to stand out'),
    (
      Icons.location_on_rounded,
      'Passport',
      'Match with people anywhere in the world'
    ),
    (
      Icons.visibility_off_rounded,
      'Invisible Mode',
      'Browse profiles without being seen'
    ),
  ];

  Future<void> _upgrade() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user == null) return;

      // In a real app: process payment via RevenueCat / StoreKit here
      await ref.read(firestoreServiceProvider).upgradeToPremium(user.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Welcome to Swipe Gold!'),
            backgroundColor: Color(0xFFFFB347),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white70),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFB347)]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('GOLD',
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 12)),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      // Crown icon
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFB347)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.4),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.workspace_premium_rounded,
                            color: Colors.white, size: 52),
                      )
                          .animate()
                          .scale(duration: 600.ms, curve: Curves.easeOutCubic),

                      const SizedBox(height: 20),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFB347)],
                        ).createShader(bounds),
                        child: const Text(
                          'Swipe Gold',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 8),
                      const Text(
                        'Unlock your full potential',
                        style: TextStyle(color: Colors.white60, fontSize: 16),
                      ).animate().fadeIn(delay: 300.ms),

                      const SizedBox(height: 32),

                      // Perks list
                      ...List.generate(_perks.length, (i) {
                        final (icon, title, desc) = _perks[i];
                        return _PerkTile(icon: icon, title: title, desc: desc)
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: 350 + i * 60))
                            .slideX(begin: -0.15);
                      }),

                      const SizedBox(height: 28),

                      // Plan selector
                      Row(
                        children: List.generate(2, (i) {
                          final plan = _plans[i];
                          final selected = _selectedPlan == i;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedPlan = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: selected
                                      ? const LinearGradient(colors: [
                                          Color(0xFFFFD700),
                                          Color(0xFFFFB347)
                                        ])
                                      : null,
                                  color: selected
                                      ? null
                                      : Colors.white.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFFFFD700)
                                        : Colors.white24,
                                    width: selected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    if (plan['tag']!.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.black26,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(plan['tag']!,
                                            style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: selected
                                                    ? Colors.black
                                                    : Colors.white70)),
                                      ),
                                    Text(plan['label']!,
                                        style: TextStyle(
                                            color: selected
                                                ? Colors.black
                                                : Colors.white,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    Text(plan['price']!,
                                        style: TextStyle(
                                            color: selected
                                                ? Colors.black
                                                : Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900)),
                                    Text(plan['per']!,
                                        style: TextStyle(
                                            color: selected
                                                ? Colors.black54
                                                : Colors.white54,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // CTA button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Color(0xFFFFD700))
                    : GestureDetector(
                        onTap: _upgrade,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFB347)]),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      const Color(0xFFFFD700).withOpacity(0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6))
                            ],
                          ),
                          child: const Text(
                            '🚀 Start Free Trial',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 18),
                          ),
                        ),
                      ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3),
              ),

              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text('Cancel anytime · Billed annually',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PerkTile extends StatelessWidget {
  const _PerkTile(
      {required this.icon, required this.title, required this.desc});
  final IconData icon;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFB347)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.black, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                const SizedBox(height: 2),
                Text(desc,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFFFFD700), size: 20),
        ],
      ),
    );
  }
}
