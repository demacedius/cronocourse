import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductFilterBar extends StatefulWidget {
  final String searchText;
  final String selectedCategory;
  final Function(String) onSearchChanged;
  final Function(String) onCategoryChanged;

  const ProductFilterBar({
    super.key,
    required this.searchText,
    required this.selectedCategory,
    required this.onSearchChanged,
    required this.onCategoryChanged,
  });

  @override
  State<ProductFilterBar> createState() => _ProductFilterBarState();
}

class _ProductFilterBarState extends State<ProductFilterBar> {
  List<String> _categories = ['tous'];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('category').get();
      setState(() {
        _categories = ['tous']..addAll(snapshot.docs.map((doc) => doc['name'].toString()));
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des catégories: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Rechercher un produit',
            labelStyle: TextStyle(color: Colors.black, fontSize: 16, fontFamily: "inter"),
            prefixIcon: Icon(Icons.search,),
          ),
          onChanged: widget.onSearchChanged,
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = widget.selectedCategory == cat;

                return ChoiceChip(
                  label: Text(cat),
                  backgroundColor: Colors.white,
                  selected: isSelected,
                  onSelected: (_) => widget.onCategoryChanged(cat),
                  selectedColor: Colors.black,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                );
              },
            ),
          )
      ],
    );
  }
}
