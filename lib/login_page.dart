import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'main_page.dart';

class LoginSignupPage extends StatefulWidget {
  const LoginSignupPage({super.key});

  @override
  State<LoginSignupPage> createState() => _LoginSignupPageState();
}

class _LoginSignupPageState extends State<LoginSignupPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  String? error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _login() async {
    setState(() => error = null);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message);
    }
  }

  Future<void> _signup() async {
  setState(() => error = null);
  final name = _nameController.text.trim();
  final email = _emailController.text.trim();
  final password = _passwordController.text;

  if (name.isEmpty) {
    setState(() => error = "Le nom est obligatoire");
    return;
  }

  try {
    final userCred = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userCred.user!.uid)
        .set({
      'uid': userCred.user!.uid,
      'email': email,
      'display_name': name,
      'adress': '',
      'city': '',
      'created_time': FieldValue.serverTimestamp(),
      'admin': false,
      'isRestaurateur': false,
    });

    print("Utilisateur enregistré dans Firestore");

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainPage()),
    );
  } on FirebaseAuthException catch (e) {
    setState(() => error = e.message);
  }
}

  @override
  Widget build(BuildContext context) {
    final isSignup = _tabController.index == 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenue'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Se connecter'), Tab(text: 'Créer un compte')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Sign In Tab
          _buildForm(
            showName: false,
            buttonText: 'Connexion',
            onPressed: _login,
          ),

          // Sign Up Tab
          _buildForm(
            showName: true,
            buttonText: 'Créer un compte',
            onPressed: _signup,
          ),
        ],
      ),
    );
  }

  Widget _buildForm({
    required bool showName,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showName)
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Nom"),
            ),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: "Email"),
            keyboardType: TextInputType.emailAddress,
          ),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: "Mot de passe"),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onPressed, child: Text(buttonText)),
        ],
      ),
    );
  }
}
