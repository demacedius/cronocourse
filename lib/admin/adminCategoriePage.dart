import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminCategoryPage extends StatefulWidget {
  const AdminCategoryPage({super.key});

  @override
  State<AdminCategoryPage> createState() => _AdminCategoryPageState();
}

class _AdminCategoryPageState extends State<AdminCategoryPage> {
  final TextEditingController _controller = TextEditingController();

  void _addCategory() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    await FirebaseFirestore.instance.collection('category').add({'name': name});

    _controller.clear();
    Navigator.pop(context);
  }

  void _editCategory(String docId, String currentName) {
    _controller.text = currentName;

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Modifier la catégorie'),
            content: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Nom de la catégorie',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _controller.clear();
                  Navigator.pop(context);
                },
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newName = _controller.text.trim();
                  if (newName.isEmpty) return;

                  await FirebaseFirestore.instance
                      .collection('category')
                      .doc(docId)
                      .update({'name': newName});

                  _controller.clear();
                  Navigator.pop(context);
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
    );
  }

  void _deleteCategory(String docId) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Supprimer ?'),
            content: const Text('Cette action est irréversible.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('category')
                      .doc(docId)
                      .delete();
                  Navigator.pop(context);
                },
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );
  }

  Future<void> assignDefaultCategoryToProducts() async {
    final firestore = FirebaseFirestore.instance;
    final productsRef = firestore.collection('product');

    final snapshot = await productsRef.get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['category'] == null || data['category'].toString().isEmpty) {
        await doc.reference.update({
          'category': 'Autre',
        }); // ou une autre valeur
        print('✅ Produit mis à jour : ${doc.id}');
      } else {
        print('ℹ️ Produit déjà catégorisé : ${doc.id}');
      }
    }

    print('🎉 Mise à jour terminée !');
  }

  void _showAddDialog() {
    _controller.clear();
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Nouvelle catégorie'),
            content: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Nom de la catégorie',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: _addCategory,
                child: const Text('Ajouter'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catégories'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddDialog),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Mettre à jour les produits',
            onPressed: assignDefaultCategoryToProducts,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('category').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Erreur de chargement'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('Aucune catégorie trouvée.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Sans nom';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.category),
                  title: Text(name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editCategory(doc.id, name),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteCategory(doc.id),
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
