import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddEditRestaurantPage extends StatefulWidget {
  final String? restaurantId; // null si on ajoute
  final Map<String, dynamic>? initialData;

  const AddEditRestaurantPage({
    super.key,
    this.restaurantId,
    this.initialData,
  });

  @override
  State<AddEditRestaurantPage> createState() => _AddEditRestaurantPageState();
}

class _AddEditRestaurantPageState extends State<AddEditRestaurantPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final imageController = TextEditingController();
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      nameController.text = widget.initialData!['name'] ?? '';
      imageController.text = widget.initialData!['image_url'] ?? '';
    }
  }

  Future<void> _saveRestaurant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    final data = {
      'name': nameController.text.trim(),
      'image': imageController.text.trim(),
    };

    final ref = FirebaseFirestore.instance.collection('restaurant');

    try {
      if (widget.restaurantId == null) {
        await ref.add(data); // nouveau resto
      } else {
        await ref.doc(widget.restaurantId).update(data); // modification
      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Restaurant enregistré ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.restaurantId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Modifier le restaurant" : "Ajouter un restaurant"),
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
                decoration: const InputDecoration(labelText: "Nom du restaurant"),
                validator: (value) =>
                    value == null || value.isEmpty ? "Nom requis" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: imageController,
                decoration: const InputDecoration(labelText: "URL de l'image"),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isSaving ? null : _saveRestaurant,
                child: Text(isEditing ? "Modifier" : "Ajouter"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
