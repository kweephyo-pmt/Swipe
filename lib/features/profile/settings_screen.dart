import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/service_providers.dart';
import '../../providers/user_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  double _distance = 50;
  double _minAge = 18;
  double _maxAge = 35;
  bool _showOutsideDistance = true;
  bool _showOutsideAge = false;
  bool _global = false;
  bool _hasBio = false;
  double _minPhotos = 1;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: const SizedBox.shrink(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.black, size: 24),
              ),
            ),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child:
                Text('Error: $e', style: const TextStyle(color: Colors.white))),
        data: (user) {
          if (user == null) return const SizedBox.shrink();

          return ListView(
            padding: const EdgeInsets.only(bottom: 60),
            children: [
              // Swipe Platinum Banner
              _buildPlatinumBanner(),
              const SizedBox(height: 16),

              // Super Likes & Boosts
              _buildInventoryRow(user.isPremium ? user.superLikesCount : 0),

              const SizedBox(height: 24),

              // Account Settings
              _buildSectionHeader('ACCOUNT SETTINGS'),
              _buildSectionGroup(
                children: [
                  _buildListTile(title: 'Phone number', value: 'Not set'),
                  _buildDivider(),
                  _buildListTile(title: 'Connected accounts'),
                  _buildDivider(),
                  _buildListTile(title: 'Email', value: 'Not set'),
                ],
              ),
              _buildSectionFooter(
                  'A verified phone number and email help secure your account.'),

              const SizedBox(height: 24),

              // Premium Discovery
              _buildPremiumDiscoveryHeader(),
              _buildSectionGroup(
                children: [
                  _buildSliderTile(
                    title: 'Minimum number of photos',
                    value: _minPhotos,
                    min: 1,
                    max: 6,
                    onChanged: (val) => setState(() => _minPhotos = val),
                    valueLabel: _minPhotos.toInt().toString(),
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    title: 'Has a bio',
                    value: _hasBio,
                    onChanged: (val) => setState(() => _hasBio = val),
                  ),
                  _buildDivider(),
                  _buildListTile(title: 'Interests', value: 'Select'),
                  _buildDivider(),
                  _buildListTile(
                      title: 'Looking for',
                      value: 'Long-term partner',
                      icon: Icons.remove_red_eye_outlined),
                ],
              ),

              const SizedBox(height: 24),

              // Discovery
              _buildSectionHeader('DISCOVERY'),
              _buildSectionGroup(
                children: [
                  _buildListTile(
                    title: 'Location',
                    value: 'My Current Location',
                    subtitle: 'Change locations to find matches anywhere.',
                  ),
                  _buildDivider(),
                  _buildSliderTile(
                    title: 'Maximum distance',
                    value: _distance,
                    min: 1,
                    max: 100,
                    onChanged: (val) => setState(() => _distance = val),
                    valueLabel: '${_distance.toInt()} mi',
                  ),
                  _buildSwitchTile(
                    title:
                        'Show people further away if I run out of profiles to see.',
                    value: _showOutsideDistance,
                    onChanged: (val) =>
                        setState(() => _showOutsideDistance = val),
                    isSubtitle: true,
                  ),
                  _buildDivider(),
                  _buildListTile(title: 'Interested in', value: 'Women'),
                  _buildDivider(),
                  _buildRangeSliderTile(
                    title: 'Age range',
                    min: 18,
                    max: 100,
                    startValue: _minAge,
                    endValue: _maxAge,
                    onChanged: (start, end) => setState(() {
                      _minAge = start;
                      _maxAge = end;
                    }),
                    valueLabel: '${_minAge.toInt()}-${_maxAge.toInt()}',
                  ),
                  _buildSwitchTile(
                    title:
                        'Show people slightly out of my preferred range if I run out of profiles to see',
                    value: _showOutsideAge,
                    onChanged: (val) => setState(() => _showOutsideAge = val),
                    isSubtitle: true,
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    title: 'Global',
                    value: _global,
                    onChanged: (val) => setState(() => _global = val),
                  ),
                ],
              ),
              _buildSectionFooter(
                  'Going global will allow you to see people nearby and from around the world.'),

              const SizedBox(height: 24),
              // Control who you see
              _buildPremiumHeader('CONTROL WHO YOU SEE'),
              _buildSectionGroup(
                children: [
                  _buildCheckTile(
                    title: 'Balanced recommendations',
                    subtitle:
                        'See the most relevant people to you (default setting)',
                    isChecked: true,
                  ),
                  _buildDivider(),
                  _buildCheckTile(
                    title: 'Recently active',
                    subtitle: 'See the most recently active people first',
                    isChecked: false,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: () async {
                    context.pop();
                    await ref.read(authServiceProvider).signOut();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: const Color(0xFFFF4458),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Sign Out',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlatinumBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  color: Colors.white, size: 24),
              const SizedBox(width: 4),
              Text(
                'swipe',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: Colors.white,
                child: Text(
                  'PLATINUM',
                  style: GoogleFonts.inter(
                    color: Colors.black,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Priority Likes, see who Likes You, and more',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryRow(int superLikes) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF141416),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded,
                      color: Color(0xFF00C6FF), size: 28),
                  const SizedBox(height: 6),
                  Text(
                    'Get Super Likes',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF00C6FF),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF141416),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bolt_rounded,
                      color: Color(0xFFD32BE8), size: 28),
                  const SizedBox(height: 6),
                  Text(
                    'Get Boosts',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFD32BE8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFF4458),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Swipe Plus®',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumDiscoveryHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'PREMIUM DISCOVERY',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCC00),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Swipe Gold™',
                  style: GoogleFonts.inter(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Preferences show you people who match your vibe, but won\'t limit who you see — you\'ll still be able to match with people outside of your selections.',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionFooter(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: Colors.white54,
          fontSize: 13,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildSectionGroup({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
        color: Colors.white12, height: 1, indent: 16, endIndent: 16);
  }

  Widget _buildListTile({
    required String title,
    String? value,
    String? subtitle,
    IconData? icon,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading:
          icon != null ? Icon(icon, color: Colors.white70, size: 22) : null,
      title: Text(
        title,
        style: GoogleFonts.inter(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 13))
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null) ...[
            Text(value,
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 16)),
            const SizedBox(width: 8),
          ],
          const Icon(Icons.chevron_right_rounded,
              color: Colors.white30, size: 20),
        ],
      ),
      onTap: () {},
    );
  }

  Widget _buildCheckTile({
    required String title,
    String? subtitle,
    bool isChecked = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(
        title,
        style: GoogleFonts.inter(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 13))
          : null,
      trailing: isChecked
          ? const Icon(Icons.check_rounded, color: Color(0xFFFF4458), size: 24)
          : null,
      onTap: () {},
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isSubtitle = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(
        title,
        style: GoogleFonts.inter(
          color: isSubtitle ? Colors.white70 : Colors.white,
          fontSize: isSubtitle ? 14 : 16,
          fontWeight: isSubtitle ? FontWeight.normal : FontWeight.w500,
        ),
      ),
      trailing: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFFFF4458),
        trackColor: Colors.white24,
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required String valueLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
              ),
              Text(
                valueLabel,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              activeTrackColor: const Color(0xFFFF4458),
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              overlayColor: const Color(0xFFFF4458).withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSliderTile({
    required String title,
    required double min,
    required double max,
    required double startValue,
    required double endValue,
    required Function(double, double) onChanged,
    required String valueLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
              ),
              Text(
                valueLabel,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              activeTrackColor: const Color(0xFFFF4458),
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              overlayColor: const Color(0xFFFF4458).withOpacity(0.2),
              rangeThumbShape:
                  const RoundRangeSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: RangeSlider(
              values: RangeValues(startValue, endValue),
              min: min,
              max: max,
              onChanged: (vals) => onChanged(vals.start, vals.end),
            ),
          ),
        ],
      ),
    );
  }
}
