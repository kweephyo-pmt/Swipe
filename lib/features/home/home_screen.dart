import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/discovery_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      // RepaintBoundary isolates the tab body from the nav bar repaints
      body: RepaintBoundary(child: navigationShell),
      bottomNavigationBar: _BottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) {
          navigationShell.goBranch(
            i,
            initialLocation: i == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

// ── Bottom Navigation Bar ─────────────────────────────────────────────────────

// Pre-built SVG strings as constants so they are never re-parsed per frame
const _svgSelected = '''
<svg width="37" height="31" viewBox="0 0 37 31" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect x="20.6094" y="5.70557" width="15.7655" height="21.3961" rx="2" fill="white" stroke="#FF4458"/>
<rect x="0.0620388" y="7.4667" width="18.8058" height="25.2696" rx="3" transform="rotate(-23.1873 0.0620388 7.4667)" fill="white" stroke="#FF4458" stroke-width="2"/>
</svg>
''';

const _svgUnselected = '''
<svg width="37" height="31" viewBox="0 0 37 31" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect x="20.6094" y="5.70557" width="15.7655" height="21.3961" rx="2" fill="#555566" stroke="#1C1C27"/>
<rect x="0.0620388" y="7.4667" width="18.8058" height="25.2696" rx="3" transform="rotate(-23.1873 0.0620388 7.4667)" fill="#555566" stroke="#1C1C27" stroke-width="2"/>
</svg>
''';

class _BottomNav extends ConsumerWidget {
  const _BottomNav({required this.currentIndex, required this.onTap});
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _icons = [
    CupertinoIcons.rectangle_stack_fill,
    CupertinoIcons.heart_fill,
    CupertinoIcons.chat_bubble_text_fill,
    CupertinoIcons.person_solid,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likesCount =
        ref.watch(receivedLikesUnmatchedProvider).valueOrNull?.length ?? 0;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          // Solid color — no BackdropFilter blur which is very expensive
          color: const Color(0xFF1E1E2C),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SizedBox(
          height: 68,
          child: Row(
            children: List.generate(_icons.length, (i) {
              final isSelected = currentIndex == i;

              Widget iconWidget;

              if (i == 0) {
                iconWidget = SvgPicture.string(
                  isSelected ? _svgSelected : _svgUnselected,
                  width: 26,
                  height: 22,
                );
              } else {
                iconWidget = Icon(
                  _icons[i],
                  color: isSelected ? Colors.white : const Color(0xFF555566),
                  size: 26,
                );
              }

              if (i == 1 && !isSelected && likesCount > 0) {
                iconWidget = Stack(
                  clipBehavior: Clip.none,
                  children: [
                    iconWidget,
                    Positioned(
                      top: -6,
                      right: -10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFF1E1E2C), width: 2),
                        ),
                        child: Text(
                          likesCount > 99 ? '99+' : '$likesCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: iconWidget,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
