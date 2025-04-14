import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cronocourse/main_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_dashboard.dart';
import 'home_page.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Pas encore chargé
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Pas connecté
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginSignupPage();
        }

        final uid = snapshot.data!.uid;

        // 3. Connecté → récupérer les infos utilisateur depuis Firestore
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data = userSnapshot.data!.data() as Map<String, dynamic>?;

           

            
            return const MainPage();
          },
        );
      },
    );
  }
}
