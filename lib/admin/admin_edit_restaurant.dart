import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cronocourse/admin/menu_list_page.dart';
import 'package:flutter/material.dart';

import 'add_edit_restaurant_page.dart';

class RestaurantAdminPage extends StatelessWidget {
  const RestaurantAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final restaurantRef = FirebaseFirestore.instance.collection('restaurant');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion des restaurants"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF008060),
        
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditRestaurantPage()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white,),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: restaurantRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("Aucun restaurant"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(data['image_url'] ?? ''),
                ),
                title: Text(data['name'] ?? 'Sans nom'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MenuListPage(restaurantId: docId),
                    ),
                  );
                },
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => AddEditRestaurantPage(
                              restaurantId: docId,
                              initialData: data,
                            ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
