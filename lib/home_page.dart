// home_page.dart
import 'package:cronocourse/widget/product_list.dart';
import 'package:cronocourse/widget/restaurant_list.dart';
import 'package:flutter/material.dart';

import 'utils/logout.dart';
import 'widget/product_filter.dart';
import 'widget/switch_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedView = "course";
  String searchText = '';
  String selectedCategory = 'tous';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Acceuil',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Image.asset(
                  'lib/assets/image/23.jpg', // ou Image.network('https://url-du-logo')
                  fit: BoxFit.contain
                ),
              ),
              SwitchButtons(
                selected: selectedView,
                onChanged: (value) {
                  setState(() => selectedView = value);
                },
              ),
              const SizedBox(height: 24),
              if (selectedView == "course") ...[
                ProductFilterBar(
                  searchText: searchText,
                  selectedCategory: selectedCategory,
                  onSearchChanged: (value) {
                    setState(() => searchText = value.toLowerCase());
                  },
                  onCategoryChanged: (value) {
                    setState(() => selectedCategory = value);
                  },
                ),
                Text(
                  "Nos produits",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
                ),
                const SizedBox(height: 12),
                ProductList(
                  searchText: searchText,
                  selectedCategory: selectedCategory,
                ),
              ] else ...[
                Text(
                  "Nos restaurants partenaires",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
                ),
                const SizedBox(height: 12),
                RestaurantList(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
