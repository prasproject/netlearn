import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_storage/get_storage.dart';
import 'firebase_options.dart';
import 'app.dart';

/// NetLearn — Main entry point
/// Interactive LMS for Computer Networking Education
/// Author: Faridatus Shofiyah
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Storage (GetStorage)
  await GetStorage.init();

  // Try to initialize Firebase, fallback gracefully if not configured
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize Analytics and Messaging (Phase 2 completion)
    final analytics = FirebaseAnalytics.instance;
    final messaging = FirebaseMessaging.instance;
    
    // Log app open
    await analytics.logAppOpen();
    
    if (!kIsWeb) {
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  } catch (e) {
    debugPrint('Firebase init warning (running in mock mode): $e');
  }

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  runApp(
    const ProviderScope(
      child: NetLearnApp(),
    ),
  );
}
