import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final DateTime birthday;
  final String gender;
  final String interestedIn;
  final String bio;
  final String lookingFor;
  final List<String> photoUrls;
  final GeoPoint? location;
  final String? locationName;
  final int minAgePreference;
  final int maxAgePreference;
  final int maxDistanceKm;
  final DateTime createdAt;
  final DateTime lastSeen;
  final bool isOnboardingComplete;
  final bool hasPremiumFlag;
  final DateTime? premiumEndDate;
  final String? pronouns;
  final String? height;
  final List<String> interests;
  final int superLikesCount;

  // New discovery prefs
  final int minPhotosPreference;
  final bool hasBioPreference;
  final bool showOutsideDistance;
  final bool showOutsideAge;
  final bool globalMode;

  bool get isPremium {
    if (!hasPremiumFlag) return false;
    if (premiumEndDate == null) return true;
    return premiumEndDate!.isAfter(DateTime.now());
  }

  AppUser({
    required this.uid,
    required this.name,
    required this.birthday,
    required this.gender,
    required this.interestedIn,
    required this.bio,
    this.lookingFor = 'Long-term partner',
    required this.photoUrls,
    this.location,
    this.locationName,
    this.minAgePreference = 18,
    this.maxAgePreference = 99,
    this.maxDistanceKm = 50,
    required this.createdAt,
    required this.lastSeen,
    this.isOnboardingComplete = false,
    this.hasPremiumFlag = false,
    this.premiumEndDate,
    this.pronouns,
    this.height,
    this.interests = const [],
    this.superLikesCount = 5,
    this.minPhotosPreference = 1,
    this.hasBioPreference = false,
    this.showOutsideDistance = true,
    this.showOutsideAge = false,
    this.globalMode = false,
  });

  int get age {
    final now = DateTime.now();
    int age = now.year - birthday.year;
    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age;
  }

  String get firstPhotoUrl => photoUrls.isNotEmpty ? photoUrls.first : '';

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      name: data['name'] ?? '',
      birthday: (data['birthday'] as Timestamp).toDate(),
      gender: data['gender'] ?? 'Other',
      interestedIn: data['interestedIn'] ?? 'Everyone',
      bio: data['bio'] ?? '',
      lookingFor: data['lookingFor'] ?? 'Long-term partner',
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      location: data['location'] as GeoPoint?,
      locationName: data['locationName'],
      minAgePreference: data['minAgePreference'] ?? 18,
      maxAgePreference: data['maxAgePreference'] ?? 99,
      maxDistanceKm: data['maxDistanceKm'] ?? 50,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastSeen: (data['lastSeen'] as Timestamp).toDate(),
      isOnboardingComplete: data['isOnboardingComplete'] ?? false,
      hasPremiumFlag: data['isPremium'] ?? false,
      premiumEndDate: data['premiumEndDate'] != null
          ? (data['premiumEndDate'] as Timestamp).toDate()
          : null,
      pronouns: data['pronouns'],
      height: data['height'],
      interests: List<String>.from(data['interests'] ?? []),
      superLikesCount: data['superLikesCount'] ?? 5,
      minPhotosPreference: data['minPhotosPreference'] ?? 1,
      hasBioPreference: data['hasBioPreference'] ?? false,
      showOutsideDistance: data['showOutsideDistance'] ?? true,
      showOutsideAge: data['showOutsideAge'] ?? false,
      globalMode: data['globalMode'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'birthday': Timestamp.fromDate(birthday),
      'gender': gender,
      'interestedIn': interestedIn,
      'bio': bio,
      'lookingFor': lookingFor,
      'photoUrls': photoUrls,
      'location': location,
      'locationName': locationName,
      'minAgePreference': minAgePreference,
      'maxAgePreference': maxAgePreference,
      'maxDistanceKm': maxDistanceKm,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSeen': Timestamp.fromDate(lastSeen),
      'isOnboardingComplete': isOnboardingComplete,
      'isPremium': hasPremiumFlag,
      if (premiumEndDate != null)
        'premiumEndDate': Timestamp.fromDate(premiumEndDate!),
      'pronouns': pronouns,
      'height': height,
      'interests': interests,
      'superLikesCount': superLikesCount,
      'minPhotosPreference': minPhotosPreference,
      'hasBioPreference': hasBioPreference,
      'showOutsideDistance': showOutsideDistance,
      'showOutsideAge': showOutsideAge,
      'globalMode': globalMode,
    };
  }

  AppUser copyWith({
    String? name,
    DateTime? birthday,
    String? gender,
    String? interestedIn,
    String? bio,
    String? lookingFor,
    List<String>? photoUrls,
    GeoPoint? location,
    String? locationName,
    int? minAgePreference,
    int? maxAgePreference,
    int? maxDistanceKm,
    DateTime? lastSeen,
    bool? isOnboardingComplete,
    bool? hasPremiumFlag,
    DateTime? premiumEndDate,
    String? pronouns,
    String? height,
    List<String>? interests,
    int? superLikesCount,
    int? minPhotosPreference,
    bool? hasBioPreference,
    bool? showOutsideDistance,
    bool? showOutsideAge,
    bool? globalMode,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
      interestedIn: interestedIn ?? this.interestedIn,
      bio: bio ?? this.bio,
      lookingFor: lookingFor ?? this.lookingFor,
      photoUrls: photoUrls ?? this.photoUrls,
      location: location ?? this.location,
      locationName: locationName ?? this.locationName,
      minAgePreference: minAgePreference ?? this.minAgePreference,
      maxAgePreference: maxAgePreference ?? this.maxAgePreference,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      createdAt: createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
      hasPremiumFlag: hasPremiumFlag ?? this.hasPremiumFlag,
      premiumEndDate: premiumEndDate ?? this.premiumEndDate,
      pronouns: pronouns ?? this.pronouns,
      height: height ?? this.height,
      interests: interests ?? this.interests,
      superLikesCount: superLikesCount ?? this.superLikesCount,
      minPhotosPreference: minPhotosPreference ?? this.minPhotosPreference,
      hasBioPreference: hasBioPreference ?? this.hasBioPreference,
      showOutsideDistance: showOutsideDistance ?? this.showOutsideDistance,
      showOutsideAge: showOutsideAge ?? this.showOutsideAge,
      globalMode: globalMode ?? this.globalMode,
    );
  }
}
