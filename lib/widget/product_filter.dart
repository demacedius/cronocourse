import 'package:flutter/material.dart';

class ProductFilterBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    const categories = [
      'tous',
      'fruit',
      'legumes',
      'viande',
      'laitage',
      'plat_cuisine',
      'produitdebase'
    ];

    return Column(
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Rechercher un produit',
            labelStyle: TextStyle(color: Colors.black, fontSize: 16, fontFamily: "inter"),
            prefixIcon: Icon(Icons.search,),
          ),
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = selectedCategory == cat;

              return ChoiceChip(
                label: Text(cat),
                backgroundColor: Colors.white,
                selected: isSelected,
                onSelected: (_) => onCategoryChanged(cat),
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
