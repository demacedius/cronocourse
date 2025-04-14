import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  List<Map<String, dynamic>> allOrders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllOrders();
  }

  Future<void> _fetchAllOrders() async {
    final users = await FirebaseFirestore.instance.collection('users').get();
    final userData = {
      for (final doc in users.docs)
        doc.id: {
          'email': doc.data()['email'] ?? '',
          'display_name': doc.data()['display_name'] ?? '',
        },
    };
    List<Map<String, dynamic>> orders = [];

    for (final user in users.docs) {
      final uid = user.id;
      final userOrders =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('orderedProduct')
              .get();

      for (final order in userOrders.docs) {
        final data = order.data();
        data['orderId'] = order.id;
        data['userId'] = uid;
        data['userEmail'] = userData[uid]?['email'] ?? '';
        data['userName'] = userData[uid]?['display_name'] ?? '';
        orders.add(data);
      }
    }

    orders.sort((a, b) {
      final dateA = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final dateB = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      return dateB.compareTo(dateA);
    });

    setState(() {
      allOrders = orders;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Commandes clients"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : allOrders.isEmpty
              ? const Center(child: Text("Aucune commande trouvée"))
              : ListView.builder(
                itemCount: allOrders.length,
                itemBuilder: (context, index) {
                  final order = allOrders[index];
                  final createdAt =
                      (order['createdAt'] as Timestamp?)?.toDate();
                  final items = List<Map<String, dynamic>>.from(
                    order['items'] ?? order['product'] ?? [],
                  );

                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.all(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Commande #${order['orderId']}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Utilisateur : ${order['userName'] ?? order['userEmail'] ?? order['userId']}",
                          ),
                          Text("Email de l'utilisateur: ${order['userEmail']}"),
                          Text(
                            "Date : ${createdAt?.toLocal().toString().split('.')[0] ?? 'N/A'}",
                          ),
                          Text("Type : ${order['type'] ?? 'N/A'}"),
                          Row(
                            children: [
                              const Text("Statut : "),
                              DropdownButton<String>(
                                value: order['status'] ?? 'en cours',
                                items: const [
                                  DropdownMenuItem(
                                    value: 'en cours',
                                    child: Text('En cours'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'préparée',
                                    child: Text('Préparée'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'livrée',
                                    child: Text('Livrée'),
                                  ),
                                ],
                                onChanged: (newStatus) async {
                                  final userId = order['userId'];
                                  final orderId = order['orderId'];

                                  if (newStatus != null) {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(userId)
                                        .collection('orderedProduct')
                                        .doc(orderId)
                                        .update({'status': newStatus});

                                    setState(() {
                                      order['status'] =
                                          newStatus; // met à jour localement
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Statut mis à jour ✅"),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),
                          ListView.separated(
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(), // empêche le conflit de scroll
                            itemCount: items.length,
                            separatorBuilder:
                                (context, index) => const Divider(),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 8,
                                ),
                                child: Row(
                                  children: [
                                    Image.network(
                                      item['image'],
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "${item['name']} x${item['quantity']}",
                                      ),
                                    ),
                                    Text("${item['price']} €"),
                                  ],
                                ),
                              );
                            },
                          ),
                          const Divider(),
                          Text(
                            "Total : ${(order['total'] ?? order['order_total'] ?? 0).toStringAsFixed(2)} €",
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
