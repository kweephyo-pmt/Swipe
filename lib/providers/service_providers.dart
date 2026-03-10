import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../services/cloudinary_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());
final cloudinaryServiceProvider =
    Provider<CloudinaryService>((ref) => CloudinaryService());
final notificationServiceProvider = 
    Provider<NotificationService>((ref) => NotificationService());

// Stream of Firebase Auth state changes
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});
