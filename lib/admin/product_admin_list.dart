import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'product_admin_form.dart';

class ProductAdminList extends StatelessWidget {
  const ProductAdminList({super.key});

  @override
  Widget build(BuildContext context) {
    final productRef = FirebaseFirestore.instance.collection('product');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion des produits"),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Ajouter un produit",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProductAdminForm(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: productRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final products = snapshot.data!.docs;

          if (products.isEmpty) {
            return const Center(child: Text("Aucun produit trouvé."));
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final doc = products[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  tileColor: Colors.white,
                  leading: Image.network(
                    data['image'] ?? '',
                    width: 50,
                    height: 50,
                    
                    fit: BoxFit.cover,
                  ),
                  title: Text(data['name'] ?? ''),
                  subtitle: Text("${(data['price'] ?? 0).toString()} € - Stock : ${data['quantity']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductAdminForm(productId: doc.id, productData: data),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Confirmer la suppression"),
                              content: const Text("Voulez-vous vraiment supprimer ce produit ?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annuler")),
                                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Supprimer")),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await doc.reference.delete();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Produit supprimé ✅")),
                            );
                          }
                        },
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
