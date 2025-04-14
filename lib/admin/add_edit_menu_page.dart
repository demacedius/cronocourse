import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddEditMenuPage extends StatefulWidget {
  final String restaurantId;
  final String? menuId;
  final Map<String, dynamic>? initialData;

  const AddEditMenuPage({
    super.key,
    required this.restaurantId,
    this.menuId,
    this.initialData,
  });

  @override
  State<AddEditMenuPage> createState() => _AddEditMenuPageState();
}

class _AddEditMenuPageState extends State<AddEditMenuPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final imageController = TextEditingController();
  final priceController = TextEditingController();
  final categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      nameController.text = widget.initialData!['name'] ?? '';
      imageController.text = widget.initialData!['image_url'] ?? '';
      priceController.text =
          (widget.initialData!['prix'] ?? '').toString();
      categoryController.text = widget.initialData!['category'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.menuId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Modifier le menu" : "Ajouter un menu"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Nom du menu"),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: imageController,
                decoration: const InputDecoration(labelText: "URL de l'image"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Prix"),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Champ requis';
                  if (double.tryParse(value) == null) return 'Nombre invalide';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: "Catégorie"),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveMenu,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(isEditing ? "Modifier" : "Ajouter"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveMenu() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': nameController.text.trim(),
      'image_url': imageController.text.trim(),
      'prix': double.tryParse(priceController.text) ?? 0.0,
      'category': categoryController.text.trim(),
      'updated_at': FieldValue.serverTimestamp(),
    };

    final menuRef = FirebaseFirestore.instance
        .collection('restaurant')
        .doc(widget.restaurantId)
        .collection('menu');

    if (widget.menuId != null) {
      await menuRef.doc(widget.menuId).update(data);
    } else {
      data['created_at'] = FieldValue.serverTimestamp();
      await menuRef.add(data);
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.menuId != null
              ? "Menu modifié ✅"
              : "Menu ajouté ✅"),
        ),
      );
    }
  }
}
