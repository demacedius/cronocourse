import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final double price = (product['price'] as num).toDouble();
    final String name = product['name'] ?? '';
    final String image = product['image'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(image, height: 180),
            ),
            const SizedBox(height: 16),
            Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${price.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 24),

            // Quantity selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    if (quantity > 1) setState(() => quantity--);
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(quantity.toString(), style: const TextStyle(fontSize: 18)),
                IconButton(
                  onPressed: () {
                    setState(() => quantity++);
                  },
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),

            const Spacer(),

            // Total
            Text(
              'Total : ${(price * quantity).toStringAsFixed(2)} €',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 12),

            // Add to Cart button
            ElevatedButton(
              onPressed: () {
                _addToCart(product, quantity);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text("Ajouter au panier"),
            ),
            const SizedBox(height: 12),

            // Order now button
            ElevatedButton(
              onPressed: () {
                // TODO: rediriger vers page de paiement Stripe
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text("Commander maintenant"),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _addToCart(Map<String, dynamic> product, int quantity) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final cartItem = {
    'productId': product['id'],
    'name': product['name'],
    'price': product['price'],
    'image': product['image'],
    'quantity': quantity,
    'total': (product['price'] as num) * quantity,
    'addedAt': FieldValue.serverTimestamp(),
  };

  final cartRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('cart')
      .doc(product['id']);

  await cartRef.set(cartItem, SetOptions(merge: true));

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Produit ajouté au panier ✅')),
  );
}
}
