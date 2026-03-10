import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/service_providers.dart';
import '../../providers/user_provider.dart';

class BuySuperLikesScreen extends ConsumerStatefulWidget {
  const BuySuperLikesScreen({super.key});

  @override
  ConsumerState<BuySuperLikesScreen> createState() =>
      _BuySuperLikesScreenState();
}

class _BuySuperLikesScreenState extends ConsumerState<BuySuperLikesScreen> {
  bool _isLoading = false;
  int _selectedPack = 1; // 0=3, 1=15, 2=30

  static const _packs = [
    {'count': 3, 'price': '\$2.99'},
    {'count': 15, 'price': '\$9.99', 'tag': 'MOST POPULAR'},
    {'count': 30, 'price': '\$14.99', 'tag': 'BEST VALUE'},
  ];

  Future<void> _buySuperLikes() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user == null) return;

      final count = _packs[_selectedPack]['count'] as int;

      // In a real app: process payment via RevenueCat / StoreKit here
      await ref.read(firestoreServiceProvider).buySuperLikes(user.uid, count);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 You bought $count Super Likes!'),
            backgroundColor: const Color(0xFF00C6FF),
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
      backgroundColor: Colors
          .transparent, // Set transparent if used as modal, but here a full page.
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF112340), Color(0xFF0F3460)],
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
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      // Star icon
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00C6FF).withOpacity(0.4),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.star_rounded,
                            color: Colors.white, size: 52),
                      )
                          .animate()
                          .scale(duration: 600.ms, curve: Curves.easeOutCubic),

                      const SizedBox(height: 20),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                        ).createShader(bounds),
                        child: const Text(
                          'Stand Out',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 8),
                      const Text(
                        'Get 3x more matches with Super Likes',
                        style: TextStyle(color: Colors.white60, fontSize: 16),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 300.ms),

                      const SizedBox(height: 48),

                      // Pack selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) {
                          final pack = _packs[i];
                          final selected = _selectedPack == i;
                          final count = pack['count'] as int;
                          final price = pack['price'] as String;
                          final tag = pack['tag'] as String?;

                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedPack = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 24, horizontal: 8),
                                decoration: BoxDecoration(
                                  gradient: selected
                                      ? const LinearGradient(colors: [
                                          Color(0xFF00C6FF),
                                          Color(0xFF0072FF)
                                        ])
                                      : null,
                                  color: selected
                                      ? null
                                      : Colors.white.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFF00C6FF)
                                        : Colors.white24,
                                    width: selected ? 2 : 1,
                                  ),
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    if (tag != null)
                                      Positioned(
                                        top: -34,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? Colors.black26
                                                : const Color(0xFF00C6FF),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(tag,
                                              style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w900,
                                                  color: selected
                                                      ? Colors.black
                                                      : Colors.white)),
                                        ),
                                      ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('$count',
                                            style: TextStyle(
                                                color: selected
                                                    ? Colors.black
                                                    : Colors.white,
                                                fontSize: 32,
                                                fontWeight: FontWeight.w900)),
                                        const SizedBox(height: 4),
                                        Text(price,
                                            style: TextStyle(
                                                color: selected
                                                    ? Colors.black54
                                                    : Colors.white54,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),

                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),

              // CTA button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Color(0xFF00C6FF))
                    : GestureDetector(
                        onTap: _buySuperLikes,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFF00C6FF), Color(0xFF0072FF)]),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      const Color(0xFF00C6FF).withOpacity(0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6))
                            ],
                          ),
                          child: const Text(
                            'GET SUPER LIKES',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                letterSpacing: 1.2),
                          ),
                        ),
                      ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
