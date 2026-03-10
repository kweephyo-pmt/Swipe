import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/service_providers.dart';
import '../../providers/user_provider.dart';
import '../discovery/user_detail_screen.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  bool _isSaving = false;
  bool _isPreview = false;
  final _picker = ImagePicker();
  List<String> _photoUrls = [];
  bool _initialized = false;
  int _minAge = 18;
  int _maxAge = 40;
  String _lookingFor = 'Long-term partner';
  List<String> _interests = [];
  String? _pronouns;
  String? _height;

  final List<String> _lookingForOptions = [
    'Long-term partner',
    'Long-term, open to short',
    'Short-term, open to long',
    'Short-term fun',
    'New friends',
    'Still figuring it out'
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _initFromUser() {
    if (_initialized) return;
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user != null) {
      _nameCtrl.text = user.name;
      _bioCtrl.text = user.bio;
      _photoUrls = List.from(user.photoUrls);
      _minAge = user.minAgePreference;
      _maxAge = user.maxAgePreference;
      _lookingFor = user.lookingFor;
      _interests = List.from(user.interests);
      _pronouns = user.pronouns;
      _height = user.height;
      _initialized = true;
    }
  }

  Future<void> _addPhoto() async {
    if (_photoUrls.length >= AppConstants.maxPhotos) return;
    final xFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xFile == null) return;

    setState(() {}); // show uploading indicator
    final cloudinary = ref.read(cloudinaryServiceProvider);
    final url = await cloudinary.uploadImage(File(xFile.path));
    if (url != null) {
      setState(() => _photoUrls.add(url));
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final uid = ref.read(authServiceProvider).currentUser!.uid;
      await ref.read(firestoreServiceProvider).updateUser(uid, {
        'name': _nameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'photoUrls': _photoUrls,
        'lookingFor': _lookingFor,
        'minAgePreference': _minAge,
        'maxAgePreference': _maxAge,
        'interests': _interests,
        'pronouns': _pronouns,
        'height': _height,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!')),
      );
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _initFromUser();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
        ),
        title: const Text(
          'Edit info',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18),
        ),
        actions: [
          _isSaving
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: _save,
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.black, size: 22),
                  ),
                ),
        ],
      ),
      body: Column(
        children: [
          // Edit / Preview Tabs
          Container(
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Color(0xFF202020), width: 1)),
            ),
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isPreview = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: !_isPreview
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text('Edit',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: !_isPreview
                                  ? AppColors.primary
                                  : AppColors.textHint,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                    ),
                  ),
                ),
                Container(width: 1, height: 20, color: const Color(0xFF333333)),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isPreview = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _isPreview
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text('Preview',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _isPreview
                                  ? AppColors.primary
                                  : AppColors.textHint,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isPreview ? _buildPreview() : _buildEditForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final userState = ref.watch(currentUserProvider);
    if (userState.value == null) return const SizedBox.shrink();

    // Create a mock user reflecting current unsaved state
    final previewUser = userState.value!.copyWith(
      name: _nameCtrl.text.trim().isNotEmpty
          ? _nameCtrl.text.trim()
          : userState.value!.name,
      bio: _bioCtrl.text.trim(),
      photoUrls:
          _photoUrls.isNotEmpty ? _photoUrls : userState.value!.photoUrls,
      lookingFor: _lookingFor,
      minAgePreference: _minAge,
      maxAgePreference: _maxAge,
      interests: _interests,
      pronouns: _pronouns,
      height: _height,
    );

    return UserDetailScreen(
      user: previewUser,
      isPreview: true,
    );
  }

  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._buildMediaSection(),
          const SizedBox(height: 32),
          ..._buildAboutMeSection(),
          const SizedBox(height: 32),
          ..._buildPromptsSection(),
          const SizedBox(height: 32),
          ..._buildMockSection(
            'INTERESTS',
            _interests.isEmpty ? 'Add interests' : _interests.join(', '),
            () => _editInterests(),
          ),
          const SizedBox(height: 32),
          ..._buildMockSectionWithIcon(
            'PRONOUNS',
            Icons.person_outline_rounded,
            _pronouns ?? 'Add pronouns',
            _pronouns == null ? 'Add' : '',
            () => _editField(
                'Pronouns',
                _pronouns,
                ['he/him', 'she/her', 'they/them'],
                (val) => setState(() => _pronouns = val)),
          ),
          const SizedBox(height: 32),
          ..._buildMockSectionWithIcon(
            'HEIGHT',
            Icons.straighten_rounded,
            _height ?? 'Add height',
            _height == null ? 'Add' : '',
            _showHeightPicker,
          ),
          const SizedBox(height: 32),
          ..._buildMockSectionWithIcon(
            'RELATIONSHIP GOALS',
            Icons.visibility_outlined,
            'Looking for',
            _lookingFor,
            () => _editField('Looking for', _lookingFor, _lookingForOptions,
                (val) => setState(() => _lookingFor = val)),
          ),
          const SizedBox(height: 60), // bottom padding
        ],
      ),
    );
  }

  List<Widget> _buildMediaSection() {
    return [
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text('MEDIA',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.5)),
      ),
      const SizedBox(height: 12),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text(
            'Add up to 9 photos. Use prompts to share your personality.',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 14, height: 1.4)),
      ),
      const SizedBox(height: 6),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GestureDetector(
          onTap: () {},
          child: const Text('Stand out with our photo tips',
              style: TextStyle(
                  color: Color(0xFF00C6FF),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFF00C6FF))),
        ),
      ),
      const SizedBox(height: 20),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: 9,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.7, // taller than wide
          ),
          itemBuilder: (context, index) {
            if (index < _photoUrls.length) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(_photoUrls[index], fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => setState(() => _photoUrls.removeAt(index)),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E24).withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              // Empty slot
              return GestureDetector(
                onTap: _addPhoto,
                child: DottedBorder(
                  color: AppColors.surfaceVariant,
                  strokeWidth: 2,
                  dashPattern: const [6, 4],
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.add_rounded,
                          color: AppColors.textHint, size: 28),
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ),
    ];
  }

  List<Widget> _buildAboutMeSection() {
    return [
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text('ABOUT ME',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.5)),
      ),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E24), // Dark rounded box
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextFormField(
            controller: _bioCtrl,
            maxLines: null,
            minLines: 2,
            maxLength: AppConstants.bioMaxLength,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: const InputDecoration(
              hintText: 'More active on IG',
              hintStyle: TextStyle(color: AppColors.textHint, fontSize: 15),
              contentPadding: EdgeInsets.all(16),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              counterStyle: TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildPromptsSection() {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(right: 6),
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle)),
            const Text('PROMPTS',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.5)),
            const Spacer(),
            const Text('+10%',
                style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            DottedBorder(
              color: AppColors.surfaceVariant,
              strokeWidth: 2,
              dashPattern: const [6, 4],
              borderType: BorderType.RRect,
              radius: const Radius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select a prompt',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    SizedBox(height: 4),
                    Text('Answer prompt',
                        style:
                            TextStyle(color: AppColors.textHint, fontSize: 14)),
                  ],
                ),
              ),
            ),
            Positioned(
              right: -8,
              top: -8,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary, // Red '+' icon
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.background,
                      width: 3), // dark border to look cut-out
                ),
                padding: const EdgeInsets.all(2),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildMockSection(
      String title, String content, VoidCallback onTap) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.5)),
      ),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E24),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(content,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          height: 1.4)),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textHint),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildMockSectionWithIcon(String title, IconData icon,
      String label, String actionText, VoidCallback? onTap) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.5)),
      ),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E24),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.textHint, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 15)),
                ),
                const SizedBox(width: 8),
                if (actionText.isNotEmpty)
                  Text(actionText,
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 14)),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textHint),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Future<void> _showHeightPicker() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _HeightPickerSheet(
        initialHeight: _height,
        onSave: (val) {
          setState(() => _height = val);
        },
      ),
    );
  }

  Future<void> _editInterests() async {
    final availableInterests = [
      'PlayStation',
      'Badminton',
      'Mala',
      'Korean dramas',
      'NFTs',
      'Grilled pork',
      'Instagram',
      'Investing',
      'Netflix',
      'BBQ',
      'Reading',
      'Travel',
      'Coffee',
      'Gym'
    ];
    List<String> currentSelected = List.from(_interests);

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Interests',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableInterests.map((interest) {
                    final isSelected = currentSelected.contains(interest);
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          if (isSelected) {
                            currentSelected.remove(interest);
                          } else {
                            if (currentSelected.length < 5) {
                              currentSelected.add(interest);
                            }
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          interest,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      setState(() => _interests = currentSelected);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Save',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _editField(String title, String? initialValue,
      List<String> options, Function(String) onSave) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select $title',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: options
                      .map((option) => ListTile(
                            title: Text(option,
                                style: const TextStyle(color: Colors.white)),
                            trailing: initialValue == option
                                ? const Icon(Icons.check_rounded,
                                    color: AppColors.primary)
                                : null,
                            onTap: () {
                              onSave(option);
                              Navigator.pop(ctx);
                            },
                          ))
                      .toList(),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

class _HeightPickerSheet extends StatefulWidget {
  final String? initialHeight;
  final Function(String?) onSave;

  const _HeightPickerSheet({this.initialHeight, required this.onSave});

  @override
  State<_HeightPickerSheet> createState() => _HeightPickerSheetState();
}

class _HeightPickerSheetState extends State<_HeightPickerSheet> {
  bool isMetric = false;
  int ft = 5;
  int inch = 8;
  int cm = 173;

  late FixedExtentScrollController _ftCtrl;
  late FixedExtentScrollController _inCtrl;
  late FixedExtentScrollController _cmCtrl;

  @override
  void initState() {
    super.initState();
    if (widget.initialHeight != null && widget.initialHeight!.contains('cm')) {
      isMetric = true;
      try {
        cm = int.parse(widget.initialHeight!.replaceAll(RegExp(r'[^0-9]'), ''));
      } catch (_) {}
    } else if (widget.initialHeight != null) {
      isMetric = false;
      try {
        final matches = RegExp(r'(\d+)\s*ft\s*(\d+)\s*in')
            .firstMatch(widget.initialHeight!);
        if (matches != null) {
          ft = int.parse(matches.group(1)!);
          inch = int.parse(matches.group(2)!);
        } else {
          final m2 = RegExp(r'(\d+)\D+(\d+)').firstMatch(widget.initialHeight!);
          if (m2 != null) {
            ft = int.parse(m2.group(1)!);
            inch = int.parse(m2.group(2)!);
          }
        }
      } catch (_) {}
    }

    if (ft < 3) ft = 3;
    if (ft > 8) ft = 8;
    if (inch < 0) inch = 0;
    if (inch > 11) inch = 11;
    if (cm < 90) cm = 90;
    if (cm > 242) cm = 242;

    _ftCtrl = FixedExtentScrollController(initialItem: ft - 3);
    _inCtrl = FixedExtentScrollController(initialItem: inch);
    _cmCtrl = FixedExtentScrollController(initialItem: cm - 90);
  }

  @override
  void dispose() {
    _ftCtrl.dispose();
    _inCtrl.dispose();
    _cmCtrl.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (isMetric) {
      widget.onSave('$cm cm');
    } else {
      widget.onSave('$ft ft $inch in');
    }
    Navigator.pop(context);
  }

  void _handleRemove() {
    widget.onSave(null);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 24),
                  ),
                ),
                const Text('Height',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: _handleSave,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.black, size: 24),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              "Here's where you can add your height to your profile.",
              style: TextStyle(color: AppColors.textHint, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: isMetric ? _buildCmPicker() : _buildFtInPicker(),
          ),
          const Divider(color: Colors.white12, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Height unit',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (isMetric) {
                            setState(() {
                              isMetric = false;
                              final totalInches = (cm / 2.54).round();
                              ft = totalInches ~/ 12;
                              inch = totalInches % 12;
                              if (ft < 3) ft = 3;
                              if (ft > 8) ft = 8;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (_ftCtrl.hasClients) {
                                  _ftCtrl.jumpToItem(ft - 3);
                                }
                                if (_inCtrl.hasClients) {
                                  _inCtrl.jumpToItem(inch);
                                }
                              });
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: !isMetric
                                ? Colors.white.withOpacity(0.25)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('ft/in',
                              style: TextStyle(
                                  color:
                                      !isMetric ? Colors.white : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (!isMetric) {
                            setState(() {
                              isMetric = true;
                              final totalInches = (ft * 12) + inch;
                              cm = (totalInches * 2.54).round();
                              if (cm < 90) cm = 90;
                              if (cm > 242) cm = 242;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (_cmCtrl.hasClients) {
                                  _cmCtrl.jumpToItem(cm - 90);
                                }
                              });
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isMetric
                                ? Colors.white.withOpacity(0.25)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('cm',
                              style: TextStyle(
                                  color:
                                      isMetric ? Colors.white : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Padding(
            padding: EdgeInsets.only(
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 24,
                right: 24),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _handleRemove,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Remove height',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFtInPicker() {
    return Stack(
      children: [
        Center(
          child: Container(
            height: 48,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 100,
              child: CupertinoPicker.builder(
                scrollController: _ftCtrl,
                itemExtent: 48,
                selectionOverlay: const SizedBox(),
                onSelectedItemChanged: (i) => ft = i + 3,
                childCount: 6,
                itemBuilder: (ctx, i) => Center(
                    child: Text('${i + 3} ft',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 20))),
              ),
            ),
            SizedBox(
              width: 100,
              child: CupertinoPicker.builder(
                scrollController: _inCtrl,
                itemExtent: 48,
                selectionOverlay: const SizedBox(),
                onSelectedItemChanged: (i) => inch = i,
                childCount: 12,
                itemBuilder: (ctx, i) => Center(
                    child: Text('$i in',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 20))),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCmPicker() {
    return Stack(
      children: [
        Center(
          child: Container(
            height: 48,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        SizedBox(
          width: 200,
          child: CupertinoPicker.builder(
            scrollController: _cmCtrl,
            itemExtent: 48,
            selectionOverlay: const SizedBox(),
            onSelectedItemChanged: (i) => cm = i + 90,
            childCount: 153,
            itemBuilder: (ctx, i) => Center(
                child: Text('${i + 90} cm',
                    style: const TextStyle(color: Colors.white, fontSize: 20))),
          ),
        ),
      ],
    );
  }
}
