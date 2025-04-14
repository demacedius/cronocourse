import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductAdminForm extends StatefulWidget {
  final String? productId;
  final Map<String, dynamic>? productData;

  const ProductAdminForm({super.key, this.productId, this.productData});

  @override
  State<ProductAdminForm> createState() => _ProductAdminFormState();
}

class _ProductAdminFormState extends State<ProductAdminForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController imageController;
  late TextEditingController quantityController;
  String category = 'produitdebase';

  final List<String> categories = [
    'fruit',
    'legumes',
    'viande',
    'laitage',
    'plat_cuisine',
    'produitdebase',
  ];

  @override
  void initState() {
    super.initState();
    final data = widget.productData;
    nameController = TextEditingController(text: data?['name'] ?? '');
    priceController = TextEditingController(text: data?['price']?.toString() ?? '');
    imageController = TextEditingController(text: data?['image'] ?? '');
    quantityController = TextEditingController(text: data?['quantity']?.toString() ?? '');
    category = data?['category'] ?? 'produitdebase';
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le produit' : 'Ajouter un produit'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Prix'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    double.tryParse(value!) == null ? 'Prix invalide' : null,
              ),
              TextFormField(
                controller: imageController,
                decoration: const InputDecoration(labelText: 'URL de l\'image'),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Quantité en stock'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    int.tryParse(value!) == null ? 'Nombre invalide' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: category,
                items: categories.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (value) => setState(() => category = value!),
                decoration: const InputDecoration(labelText: 'Catégorie'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveProduct,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(isEditing ? 'Mettre à jour' : 'Ajouter'),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final product = {
      'name': nameController.text,
      'price': double.parse(priceController.text),
      'image': imageController.text,
      'quantity': int.parse(quantityController.text),
      'category': category,
    };

    final productRef = FirebaseFirestore.instance.collection('product');

    if (widget.productId != null) {
      await productRef.doc(widget.productId).update(product);
    } else {
      await productRef.add(product);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.productId != null ? 'Produit modifié ✅' : 'Produit ajouté ✅')),
    );

    Navigator.of(context).pop();
  }
}
