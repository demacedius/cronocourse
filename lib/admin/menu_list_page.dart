import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cronocourse/admin/add_edit_menu_page.dart';
import 'package:flutter/material.dart';

class MenuListPage extends StatelessWidget {
  final String restaurantId;

  const MenuListPage({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    final menuRef = FirebaseFirestore.instance
        .collection('restaurant')
        .doc(restaurantId)
        .collection('menu');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Menus du restaurant"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditMenuPage(restaurantId: restaurantId),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: menuRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("Aucun menu disponible."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: Image.network(
                  data['image_url'] ?? '',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
                title: Text(data['name'] ?? 'Sans nom'),
                subtitle: Text("${data['prix']?.toStringAsFixed(2)} €"),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => AddEditMenuPage(
                              restaurantId: restaurantId,
                              menuId: docs[index].id,
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
