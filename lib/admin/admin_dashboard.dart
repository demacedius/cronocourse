import 'package:cronocourse/admin/adminCategoriePage.dart';
import 'package:cronocourse/admin/delivery_fees_page.dart';
import 'package:flutter/material.dart';

import '../main_page.dart';
import 'product_admin_list.dart';
import 'admin_edit_restaurant.dart';
import 'user_admin_page.dart';
import 'admin_order_page.dart';
import '../restaurant/restaurant_orders_page.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Panneau d'administration",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MainPage()),
              );
            },
            icon: const Icon(Icons.swap_horiz, color: Colors.white,),
            tooltip: 'Retour côté client',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildTile(
              context,
              icon: Icons.shopping_bag,
              label: "Produits",
              destination: const ProductAdminList(),
            ),
            _buildTile(
              context,
              icon: Icons.restaurant,
              label: "Restaurants",
              destination: const RestaurantAdminPage(),
            ),
            _buildTile(
              context,
              icon: Icons.people,
              label: "Utilisateurs",
              destination: const UserAdminPage(),
            ),
            _buildTile(
              context,
              icon: Icons.receipt_long,
              label: "Commandes",
              destination: const AdminOrdersPage(),
            ),
            _buildTile(
              context,
              icon: Icons.list,
              label: "Catégorie",
              destination: const AdminCategoryPage(),
            ),
            _buildTile(
              context,
              icon: Icons.list,
              label: "Frais de livraison",
              destination: const DeliveryFeesPage(),
            ),
            _buildTile(
              context,
              icon: Icons.restaurant_menu,
              label: "Commandes restaurant",
              destination: const RestaurantOrdersPage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Widget destination,
  }) {
    return InkWell(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => destination),
          ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.05 * 255).toInt()),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Colors.black),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
