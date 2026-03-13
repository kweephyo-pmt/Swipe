import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'app.dart';
import 'core/router/app_router.dart';
import 'firebase_options.dart';
import 'providers/service_providers.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


  final container = ProviderContainer();
  final notificationService = container.read(notificationServiceProvider);
  await notificationService.init((payload) {
    if (payload != null && payload.isNotEmpty) {
      if (rootNavigatorKey.currentContext != null) {
        rootNavigatorKey.currentContext!.push(payload);
      }
    }
  });
  await notificationService.requestPermissions();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SwipeApp(),
    ),
  );
}
