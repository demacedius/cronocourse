import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class UserAdminPage extends StatelessWidget {
  const UserAdminPage({super.key});

  Future<void> _updateExistingUsers(BuildContext context) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('updateExistingUsers');
      final result = await callable();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.data['updatedCount']} utilisateurs mis à jour'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersRef = FirebaseFirestore.instance.collection('users');
    final restaurantsRef = FirebaseFirestore.instance.collection('restaurant');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion des utilisateurs"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _updateExistingUsers(context),
            tooltip: 'Mettre à jour les utilisateurs existants',
          ),
        ],
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
              final isRestaurateur = data['isRestaurateur'] == true;
              final restaurantId = data['restaurantId'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  tileColor: Colors.white,
                  leading: CircleAvatar(
                    backgroundColor: isAdmin ? const Color.fromARGB(255, 1, 255, 39) : Colors.grey,
                    child: Text(name[0].toUpperCase()),
                  ),
                  title: Text(name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(email),
                      Text("Ville : $city"),
                      const SizedBox(height: 8),
                      Column(
                        children: [
                          Row(
                            children: [
                              const Text("Admin : "),
                              Switch(
                                value: isAdmin,
                                onChanged: (val) {
                                  usersRef.doc(docId).update({'admin': val});
                                },
                                activeColor: Colors.green,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text("Restaurateur : "),
                              Switch(
                                value: isRestaurateur,
                                onChanged: (val) {
                                  usersRef.doc(docId).update({'isRestaurateur': val});
                                },
                                activeColor: Colors.orange,
                              ),
                            ],
                          ),
                          if (isRestaurateur) ...[
                            const SizedBox(height: 8),
                            StreamBuilder<QuerySnapshot>(
                              stream: restaurantsRef.snapshots(),
                              builder: (context, restaurantSnapshot) {
                                if (!restaurantSnapshot.hasData) {
                                  return const CircularProgressIndicator();
                                }

                                final restaurants = restaurantSnapshot.data!.docs;
                                return DropdownButton<String>(
                                  value: restaurantId.isEmpty ? null : restaurantId,
                                  hint: const Text('Sélectionner un restaurant'),
                                  items: restaurants.map((doc) {
                                    final restaurantData = doc.data() as Map<String, dynamic>;
                                    return DropdownMenuItem<String>(
                                      value: doc.id,
                                      child: Text(restaurantData['name'] ?? 'Sans nom'),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      usersRef.doc(docId).update({'restaurantId': newValue});
                                    }
                                  },
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
