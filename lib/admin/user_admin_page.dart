import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserAdminPage extends StatelessWidget {
  const UserAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final usersRef = FirebaseFirestore.instance.collection('users');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion des utilisateurs"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return const Center(child: Text("Aucun utilisateur"));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;

              final name = data['display_name'] ?? 'Sans nom';
              final email = data['email'] ?? '';
              final city = data['city'] ?? '';
              final isAdmin = data['admin'] == true;

              return ListTile(
                tileColor: Colors.white,
                leading: CircleAvatar(
                  backgroundColor: isAdmin ? const Color.fromARGB(255, 1, 255, 39) : Colors.grey,
                  child: Text(name[0].toUpperCase()),
                ),
                title: Text(name),
                subtitle: Text("$email\nVille : $city"),
                isThreeLine: true,
                trailing: Switch(
                  value: isAdmin,
                  onChanged: (val) {
                    usersRef.doc(docId).update({'admin': val});
                  },
                  activeColor: Colors.green,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
