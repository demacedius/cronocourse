// admin_dashboard.dart
import 'package:flutter/material.dart';
import '../utils/logout.dart'; // importe ta fonction logout

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: const Center(
        child: Text('Dashboard Admin'),
      ),
    );
  }
}
