class AppConstants {
  // Cloudinary
  static const String cloudinaryCloudName = 'dqaklhcim';
  static const String cloudinaryUploadPreset = 'SwipeApp';
  static const String cloudinaryBaseUrl =
      'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String likesCollection = 'likes';
  static const String matchesCollection = 'matches';
  static const String messagesSubcollection = 'messages';

  // App settings
  static const int maxPhotos = 6;
  static const int minAge = 18;
  static const int maxAge = 99;
  static const int defaultMaxDistance = 50; // km
  static const int bioMaxLength = 500;

  // Swipe thresholds
  static const double swipeThreshold = 100.0;
  static const double superLikeThreshold = -100.0;
}
