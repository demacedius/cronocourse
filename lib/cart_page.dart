import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'utils/strip_payement.dart';
import 'widget/dropdown_delivery.dart';
import 'widget/address_selection.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final user = FirebaseAuth.instance.currentUser;
  String? selectedCity;
  double deliveryFee = 0.0;
  double cartTotal = 0.0;
  Map<String, dynamic>? userInfo;
  Map<String, dynamic>? selectedDeliveryAddress;
  Map<String, dynamic>? billingAddress;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    if (user == null) return;
    
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    
    if (userDoc.exists) {
      setState(() {
        userInfo = userDoc.data();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Non connecté")));
    }

    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('cart');

    return Scaffold(
      appBar: AppBar(title: const Text("Mon Panier")),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: cartRef.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;
            double cartTotal = 0;
            final onlyRestaurant = docs.every((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['type'] == 'restaurant';
            });

            for (final doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              cartTotal += (data['total'] ?? 0);
            }

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;

                            return ListTile(
                              leading: Image.network(
                                data['image'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                              title: Text(data['name']),
                              subtitle: Text(
                                '${data['quantity']} x ${data['price']} € = ${data['total'].toStringAsFixed(2)} €',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () => _updateQuantity(doc.id, data['quantity'] - 1),
                                    icon: const Icon(Icons.remove_circle_outline),
                                  ),
                                  IconButton(
                                    onPressed: () => _updateQuantity(doc.id, data['quantity'] + 1),
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteItem(doc.id),
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        if (onlyRestaurant) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: AddressSelection(
                              isRequired: true,
                              onAddressSelected: (deliveryAddress) {
                                setState(() {
                                  selectedDeliveryAddress = deliveryAddress;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: DeliveryZoneDropdown(
                            selectedCity: selectedCity,
                            onChanged: (city, courseFee, restaurantFee) {
                              setState(() {
                                selectedCity = city;
                                deliveryFee = onlyRestaurant ? restaurantFee : courseFee;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Panier : ${cartTotal.toStringAsFixed(2)} €",
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Livraison : ${deliveryFee.toStringAsFixed(2)} €",
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Total : ${(cartTotal + deliveryFee).toStringAsFixed(2)} €",
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          final total = cartTotal + deliveryFee;

                          if (selectedCity == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Choisissez une ville de livraison"),
                              ),
                            );
                            return;
                          }

                          if (onlyRestaurant && selectedDeliveryAddress == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Choisissez une adresse de livraison"),
                              ),
                            );
                            return;
                          }
                          
                          payWithStripe(
                            amount: total,
                            context: context,
                            onSuccess: _submitOrder,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text("Commander maintenant"),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _updateQuantity(String docId, int newQty) {
    if (newQty < 1) return _deleteItem(docId);

    final cartItemRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('cart')
        .doc(docId);

    cartItemRef.get().then((doc) {
      final data = doc.data()!;
      final price = data['price'];
      cartItemRef.update({'quantity': newQty, 'total': price * newQty});
    });
  }

  void _deleteItem(String docId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('cart')
        .doc(docId)
        .delete();
  }

  Future<void> _submitOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final cartRef = userRef.collection('cart');
    final orderRef = userRef.collection('orderedProduct');
    final ordersRef = FirebaseFirestore.instance.collection('orders');

    final cartSnapshot = await cartRef.get();

    if (cartSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Votre panier est vide")),
      );
      return;
    }

    // 🧩 Séparation des produits par type
    List<Map<String, dynamic>> courseItems = [];
    List<Map<String, dynamic>> restaurantItems = [];

    for (final doc in cartSnapshot.docs) {
      final data = doc.data();
      if (data['type'] == 'restaurant') {
        restaurantItems.add(data);
      } else {
        courseItems.add(data);
      }
    }

    // 📦 Commande course
    if (courseItems.isNotEmpty) {
      final totalCourse = courseItems.fold<double>(
        0,
        (sum, item) => sum + (item['total'] ?? 0),
      );

      final orderData = {
        'products': courseItems,
        'type': 'course',
        'order_total': totalCourse + deliveryFee,
        'cart_total': totalCourse,
        'delivery_fee': deliveryFee,
        'delivery_city': selectedCity,
        'created_at': FieldValue.serverTimestamp(),
        'status': 'en cours',
        'user_info': userInfo,
      };

      // Ajouter à la collection orderedProduct
      await orderRef.add(orderData);
      
      // Ajouter à la collection orders
      await ordersRef.add(orderData);

      // Décrémenter les stocks
      await _decrementProductQuantities(courseItems);
    }

    // 🍕 Commande restaurant
    if (restaurantItems.isNotEmpty) {
      final totalRestaurant = restaurantItems.fold<double>(
        0,
        (sum, item) => sum + (item['total'] ?? 0),
      );

      final orderData = {
        'products': restaurantItems,
        'type': 'restaurant',
        'order_total': totalRestaurant,
        'delivery_fee': deliveryFee,
        'delivery_city': selectedCity,
        'delivery_address': selectedDeliveryAddress,
        'created_at': FieldValue.serverTimestamp(),
        'status': 'en cours',
        'user_info': userInfo,
      };

      // Ajouter à la collection orderedProduct
      await orderRef.add(orderData);
      
      // Ajouter à la collection orders
      await ordersRef.add(orderData);
    }

    // 🗑️ Vider le panier
    for (final doc in cartSnapshot.docs) {
      await doc.reference.delete();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Commandes enregistrées ✅")),
    );

    Navigator.of(context).pop();
  }

  Future<void> _decrementProductQuantities(
    List<Map<String, dynamic>> productList,
  ) async {
    final firestore = FirebaseFirestore.instance;

    for (final product in productList) {
      final productId = product['id'];
      final quantityPurchased = product['quantity'];

      final productRef = firestore.collection('products').doc(productId);

      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(productRef);
        if (!snapshot.exists) return;

        final currentQty = snapshot.data()?['quantity'] ?? 0;
        final newQty =
            (currentQty - quantityPurchased).clamp(0, double.infinity).toInt();

        transaction.update(productRef, {'quantity': newQty});
      });
    }
  }
}
