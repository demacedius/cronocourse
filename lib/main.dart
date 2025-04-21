import 'package:cronocourse/utils/notifications_api.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'auth_gate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  print('🔍 Starting app initialization...');
  WidgetsFlutterBinding.ensureInitialized();
  print('✅ Flutter binding initialized');
  
  await dotenv.load(fileName: ".env");
  print('✅ Loaded .env file');
  
  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
  print('🔑 Stripe key status: ${Stripe.publishableKey.isEmpty ? "Missing" : "Present"}');
  if (Stripe.publishableKey.isEmpty) {
    print('⚠️ Aucune clé Stripe définie dans .env');
  }

  print('🔥 Initializing Firebase...');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('✅ Firebase initialized');

  print('🔔 Setting up notifications...');
  await NotificationsApi.initNotifications();
  print('✅ Notifications initialized');

  print('🚀 Running app...');
  runApp(const ChronoCourseApp());
}

class ChronoCourseApp extends StatefulWidget {
  const ChronoCourseApp({super.key});

  @override
  State<ChronoCourseApp> createState() => _ChronoCourseAppState();
}

class _ChronoCourseAppState extends State<ChronoCourseApp> {
  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    await FirebaseMessaging.instance.requestPermission();

    final fcmToken = await FirebaseMessaging.instance.getToken();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && fcmToken != null) {
      await FirebaseFirestore.instance
          .collection('addFCMtoken')
          .doc(user.uid)
          .set({'token': fcmToken});
      print('✅ FCM Token saved for user ${user.uid}');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        final snackBar = SnackBar(
          content: Text(
            '${message.notification!.title ?? ''}\n${message.notification!.body ?? ''}',
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('➡️ User opened the notification');
      // Navigation could be added here if needed
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chronocourse',
      theme: ThemeData(
        fontFamily: GoogleFonts.inter().fontFamily,
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.interTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          brightness: Brightness.light,
        ),
      ),
      home: const AuthGate(),
    );
  }
}
