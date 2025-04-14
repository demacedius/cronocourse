import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cronocourse/main_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RestaurantMenuPage extends StatelessWidget {
  final String restaurantId;

  const RestaurantMenuPage({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    final menuRef = FirebaseFirestore.instance
        .collection('restaurant')
        .doc(restaurantId)
        .collection('menu');

    return Scaffold(
      appBar: AppBar(title: const Text("Menu")),
      body: StreamBuilder<QuerySnapshot>(
        stream: menuRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white,
                elevation: 3,
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      data['image_url'],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(data['name']),
                  subtitle: Text("${data['prix']} €"),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_shopping_cart),
                    onPressed: () => addToCart(context, data),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        backgroundColor: Colors.white,
        onTap: (index) {
          Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => MainPage(initialIndex: index)),
      (route) => false,
    );
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Mes Commandes'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Panier'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  void addToCart(BuildContext context, Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart');

    final newItem = {
      'name': data['name'],
      'price': data['prix'],
      'image': data['image_url'],
      'quantity': 1,
      'total': data['prix'], // 1x prix
      'type': 'restaurant',
      'createdAt': FieldValue.serverTimestamp(),
    };

    await cartRef.add(newItem);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Ajouté au panier ✅")));
  }
}
