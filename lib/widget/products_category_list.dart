import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cronocourse/product_detail.dart';
import 'package:flutter/material.dart';

class CategorizedProductList extends StatelessWidget {
  final String category;
  final String label;

  const CategorizedProductList({
    super.key,
    required this.category,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: StreamBuilder(
            stream:
                FirebaseFirestore.instance
                    .collection('product')
                    .where('category', isEqualTo: category)
                    .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final products = snapshot.data!.docs;

              if (products.isEmpty) {
                return const Text("Aucun produit.");
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final data = products[index].data() as Map<String, dynamic>;

                  return GestureDetector(
                    onTap:
                        () => {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailPage(product: data),
                            ),
                          ),
                        },
                    child: Container(
                      width: 130,
                      margin: const EdgeInsets.only(right: 30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.1 * 255).toInt()),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: Image.network(
                              data['image'] ?? '',
                              height: 80,
                              width: 120,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => const Icon(Icons.image),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data['name'] ?? '',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(data['price'] as num).toStringAsFixed(2)} €',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
