import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_user.dart';
import '../../providers/service_providers.dart';
import '../shared/gradient_button.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSaving = false;

  // Form state
  String _name = '';
  DateTime _birthday = DateTime(2000, 1, 1);
  String _gender = 'Man';
  String _interestedIn = 'Everyone';
  String _lookingFor = 'Long-term partner';
  String _bio = '';
  List<String> _photoUrls = [];
  GeoPoint? _location;
  String? _locationName;

  final List<String> _genders = ['Man', 'Woman', 'Non-binary', 'Other'];
  final List<String> _orientations = ['Women', 'Men', 'Everyone'];
  final List<String> _lookingForOptions = ['Long-term partner', 'Long-term, open to short', 'Short-term, open to long', 'Short-term fun', 'New friends', 'Still figuring it out'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Progress indicator
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (_currentPage > 0)
                          IconButton(
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            icon: Icon(Icons.arrow_back_ios_rounded,
                                color: AppColors.textPrimary),
                          ),
                        const Spacer(),
                        Text(
                          '${_currentPage + 1} / 6',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_currentPage + 1) / 6,
                        backgroundColor: AppColors.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    _NameStep(
                      onNext: (name) {
                        setState(() => _name = name);
                        _nextPage();
                      },
                    ),
                    _BirthdayStep(
                      onNext: (date) {
                        setState(() => _birthday = date);
                        _nextPage();
                      },
                    ),
                    _GenderStep(
                      genders: _genders,
                      orientations: _orientations,
                      selectedGender: _gender,
                      selectedOrientation: _interestedIn,
                      onNext: (gender, orientation) {
                        setState(() {
                          _gender = gender;
                          _interestedIn = orientation;
                        });
                        _nextPage();
                      },
                    ),
                    _LookingForStep(
                      options: _lookingForOptions,
                      selectedOption: _lookingFor,
                      onNext: (lookingFor) {
                        setState(() => _lookingFor = lookingFor);
                        _nextPage();
                      },
                    ),
                    _PhotosStep(
                      photoUrls: _photoUrls,
                      onPhotosChanged: (urls) =>
                          setState(() => _photoUrls = urls),
                      onNext: () => _nextPage(),
                    ),
                    _BioStep(
                      onFinish: (bio) {
                        setState(() => _bio = bio);
                        _saveProfile();
                      },
                      isSaving: _isSaving,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      // Get location
      final hasPermission = await _requestLocationPermission();
      if (hasPermission) {
        final pos = await Geolocator.getCurrentPosition();
        _location = GeoPoint(pos.latitude, pos.longitude);
      }

      final authService = ref.read(authServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);
      final uid = authService.currentUser!.uid;

      final user = AppUser(
        uid: uid,
        name: _name,
        birthday: _birthday,
        gender: _gender,
        interestedIn: _interestedIn,
        lookingFor: _lookingFor,
        bio: _bio,
        photoUrls: _photoUrls,
        location: _location,
        locationName: _locationName,
        createdAt: DateTime.now(),
        lastSeen: DateTime.now(),
        isOnboardingComplete: true,
      );

      await firestoreService.createUser(user);
      if (!mounted) return;
      context.go('/discovery');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _requestLocationPermission() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }
}

// ── Step Widgets ──────────────────────────────────────────────────────────────

class _NameStep extends StatefulWidget {
  const _NameStep({required this.onNext});
  final Function(String) onNext;

  @override
  State<_NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<_NameStep> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "What's your\nfirst name?",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ).animate().fadeIn().slideX(begin: -0.2),
          const SizedBox(height: 12),
          const Text(
            'This is how you\'ll appear on Swipe.',
            style:
                TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 40),
          TextFormField(
            controller: _ctrl,
            autofocus: true,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(hintText: 'Your first name'),
            onChanged: (_) => setState(() {}),
          ).animate().fadeIn(delay: 200.ms),
          const Spacer(),
          GradientButton(
            label: 'Continue',
            onPressed: _ctrl.text.trim().isNotEmpty
                ? () => widget.onNext(_ctrl.text.trim())
                : null,
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}

class _BirthdayStep extends StatefulWidget {
  const _BirthdayStep({required this.onNext});
  final Function(DateTime) onNext;

  @override
  State<_BirthdayStep> createState() => _BirthdayStepState();
}

class _BirthdayStepState extends State<_BirthdayStep> {
  DateTime _selectedDate = DateTime(2000, 1, 1);

  int get _age {
    final now = DateTime.now();
    int age = now.year - _selectedDate.year;
    if (now.month < _selectedDate.month ||
        (now.month == _selectedDate.month &&
            now.day < _selectedDate.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            "When's your\nbirthday?",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ).animate().fadeIn().slideX(begin: -0.2),
          const SizedBox(height: 12),
          const Text(
            'Your age will be shown on your profile.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '$_age years old',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ScrollWheel(
                    items: List.generate(12, (i) => _monthName(i + 1)),
                    initialIndex: _selectedDate.month - 1,
                    onChanged: (i) => setState(() {
                      _selectedDate = DateTime(
                          _selectedDate.year, i + 1, _selectedDate.day);
                    }),
                  ),
                ),
                Expanded(
                  child: _ScrollWheel(
                    items: List.generate(31, (i) => '${i + 1}'),
                    initialIndex: _selectedDate.day - 1,
                    onChanged: (i) => setState(() {
                      _selectedDate = DateTime(
                          _selectedDate.year, _selectedDate.month, i + 1);
                    }),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _ScrollWheel(
                    items: List.generate(
                      90,
                      (i) => '${DateTime.now().year - 18 - i}',
                    ),
                    initialIndex:
                        (DateTime.now().year - 18 - _selectedDate.year)
                            .clamp(0, 89),
                    onChanged: (i) => setState(() {
                      _selectedDate = DateTime(
                          DateTime.now().year - 18 - i,
                          _selectedDate.month,
                          _selectedDate.day);
                    }),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 32),
          GradientButton(
            label: 'Continue',
            onPressed: _age >= 18 ? () => widget.onNext(_selectedDate) : null,
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

class _ScrollWheel extends StatefulWidget {
  const _ScrollWheel({
    required this.items,
    required this.initialIndex,
    required this.onChanged,
  });

  final List<String> items;
  final int initialIndex;
  final ValueChanged<int> onChanged;

  @override
  State<_ScrollWheel> createState() => _ScrollWheelState();
}

class _ScrollWheelState extends State<_ScrollWheel> {
  late FixedExtentScrollController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = FixedExtentScrollController(
        initialItem: widget.initialIndex.clamp(0, widget.items.length - 1));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: _ctrl,
      itemExtent: 44,
      diameterRatio: 1.5,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: widget.onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        builder: (context, index) {
          if (index < 0 || index >= widget.items.length) return null;
          return Center(
            child: Text(
              widget.items[index],
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
        childCount: widget.items.length,
      ),
    );
  }
}

class _GenderStep extends StatefulWidget {
  const _GenderStep({
    required this.genders,
    required this.orientations,
    required this.selectedGender,
    required this.selectedOrientation,
    required this.onNext,
  });

  final List<String> genders;
  final List<String> orientations;
  final String selectedGender;
  final String selectedOrientation;
  final Function(String gender, String orientation) onNext;

  @override
  State<_GenderStep> createState() => _GenderStepState();
}

class _GenderStepState extends State<_GenderStep> {
  late String _gender;
  late String _orientation;

  @override
  void initState() {
    super.initState();
    _gender = widget.selectedGender;
    _orientation = widget.selectedOrientation;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Who are you?',
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary),
          ).animate().fadeIn().slideX(begin: -0.2),
          const SizedBox(height: 32),
          const Text('I am a...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.genders
                .map((g) => _SelectChip(
                      label: g,
                      isSelected: _gender == g,
                      onTap: () => setState(() => _gender = g),
                    ))
                .toList(),
          ),
          const SizedBox(height: 32),
          const Text('I\'m interested in...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.orientations
                .map((o) => _SelectChip(
                      label: o,
                      isSelected: _orientation == o,
                      onTap: () => setState(() => _orientation = o),
                    ))
                .toList(),
          ),
          const Spacer(),
          GradientButton(
            label: 'Continue',
            onPressed: () => widget.onNext(_gender, _orientation),
          ),
        ],
      ),
    );
  }
}

class _LookingForStep extends StatefulWidget {
  const _LookingForStep({
    required this.options,
    required this.selectedOption,
    required this.onNext,
  });

  final List<String> options;
  final String selectedOption;
  final Function(String) onNext;

  @override
  State<_LookingForStep> createState() => _LookingForStepState();
}

class _LookingForStepState extends State<_LookingForStep> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedOption;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Right now I\'m\nlooking for...',
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.2),
          ).animate().fadeIn().slideX(begin: -0.2),
          const SizedBox(height: 8),
          const Text(
            'Share this to find your match.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: widget.options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final option = widget.options[i];
                final isSelected = _selected == option;
                return GestureDetector(
                  onTap: () => setState(() => _selected = option),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          option,
                          style: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          GradientButton(
            label: 'Continue',
            onPressed: () => widget.onNext(_selected),
          ),
        ],
      ),
    );
  }
}

class _SelectChip extends StatelessWidget {
  const _SelectChip(
      {required this.label, required this.isSelected, required this.onTap});
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(50),
          border: isSelected
              ? null
              : Border.all(color: AppColors.surfaceVariant),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PhotosStep extends ConsumerStatefulWidget {
  const _PhotosStep(
      {required this.photoUrls,
      required this.onPhotosChanged,
      required this.onNext});
  final List<String> photoUrls;
  final Function(List<String>) onPhotosChanged;
  final VoidCallback onNext;

  @override
  ConsumerState<_PhotosStep> createState() => _PhotosStepState();
}

class _PhotosStepState extends ConsumerState<_PhotosStep> {
  late List<String> _photos;
  final _picker = ImagePicker();
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.photoUrls);
  }

  Future<void> _pickAndUpload() async {
    final xFile = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (xFile == null) return;

    setState(() => _uploading = true);
    final cloudinary = ref.read(cloudinaryServiceProvider);
    final url = await cloudinary.uploadImage(File(xFile.path));
    if (url != null) {
      final updated = [..._photos, url];
      setState(() => _photos = updated);
      widget.onPhotosChanged(updated);
    }
    setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add your best\nphotos',
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.2),
          ).animate().fadeIn().slideX(begin: -0.2),
          const SizedBox(height: 8),
          const Text(
            'Add at least 2 photos to continue.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.75,
              ),
              itemCount: AppConstants.maxPhotos,
              itemBuilder: (_, i) {
                if (i < _photos.length) {
                  return _PhotoTile(
                    url: _photos[i],
                    onDelete: () {
                      final updated = [..._photos]..removeAt(i);
                      setState(() => _photos = updated);
                      widget.onPhotosChanged(updated);
                    },
                  );
                }
                if (i == _photos.length && !_uploading) {
                  return _AddPhotoTile(onTap: _pickAndUpload);
                }
                if (i == _photos.length && _uploading) {
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                  );
                }
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          GradientButton(
            label: 'Continue',
            onPressed: _photos.length >= 2 ? widget.onNext : null,
          ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.url, required this.onDelete});
  final String url;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(url, fit: BoxFit.cover,
              width: double.infinity, height: double.infinity),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.primary.withOpacity(0.5), width: 2),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 36),
            SizedBox(height: 8),
            Text('Add Photo',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _BioStep extends StatefulWidget {
  const _BioStep({required this.onFinish, required this.isSaving});
  final Function(String) onFinish;
  final bool isSaving;

  @override
  State<_BioStep> createState() => _BioStepState();
}

class _BioStepState extends State<_BioStep> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Write a\nbit about you',
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.2),
          ).animate().fadeIn().slideX(begin: -0.2),
          const SizedBox(height: 8),
          Text(
            '${_ctrl.text.length} / ${AppConstants.bioMaxLength} characters',
            style: TextStyle(color: AppColors.textHint, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: TextFormField(
              controller: _ctrl,
              maxLines: null,
              expands: true,
              maxLength: AppConstants.bioMaxLength,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 16),
              decoration: const InputDecoration(
                hintText:
                    'Tell others something interesting about yourself...',
                alignLabelWithHint: true,
                counterText: '',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 16),
          GradientButton(
            label: 'Get Started 🎉',
            isLoading: widget.isSaving,
            onPressed: () => widget.onFinish(_ctrl.text.trim()),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => widget.onFinish(''),
              child: const Text(
                'Skip for now',
                style: TextStyle(color: AppColors.textHint),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
