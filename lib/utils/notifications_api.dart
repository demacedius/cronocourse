import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsApi {
  static final _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> initNotifications() async {
    // 1. Demander les permissions
    await _firebaseMessaging.requestPermission();

    // 2. Récupérer le token FCM
    await FirebaseMessaging.instance.getAPNSToken(); // attend d’avoir le token
    final fcmToken = await _firebaseMessaging.getToken();
    debugPrint('🔑 FCM Token : $fcmToken');

    // 3. Enregistrer le token en base de données
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && fcmToken != null) {
      await FirebaseFirestore.instance
          .collection("addFCMtoken")
          .doc(user.uid)
          .set({'token': fcmToken});
    }

    // 4. Gestion des messages reçus en premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        debugPrint('📩 Message reçu : ${notification.title} - ${notification.body}');
        // Optionnel : afficher une Snackbar ou un AlertDialog
      }
    });
  }
}
