import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class ProductAdminForm extends StatefulWidget {
  final String? productId;
  final Map<String, dynamic>? productData;

  const ProductAdminForm({super.key, this.productId, this.productData});

  @override
  State<ProductAdminForm> createState() => _ProductAdminFormState();
}

class _ProductAdminFormState extends State<ProductAdminForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController quantityController;
  String? imageUrl;
  File? _selectedImage;
  String? category;
  List<String> categories = [];

  @override
  void initState() {
    super.initState();
    final data = widget.productData;
    nameController = TextEditingController(text: data?['name'] ?? '');
    priceController = TextEditingController(text: data?['price']?.toString() ?? '');
    quantityController = TextEditingController(text: data?['quantity']?.toString() ?? '');
    category = data?['category'];
    imageUrl = data?['image'];

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('category').get();
      final fetchedCategories = snapshot.docs.map((doc) => doc['name'].toString()).toList();

      setState(() {
        categories = fetchedCategories;
        if (category == null || !categories.contains(category)) {
          category = categories.isNotEmpty ? categories.first : null;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des catégories : ${e.toString()}';
      });
    }
  }

  Future<File> _compressImage(File file) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Impossible de décoder l\'image');
    
    final compressed = img.encodeJpg(image, quality: 85);
    final tempDir = await getTemporaryDirectory();
    final path = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return File(path)..writeAsBytesSync(compressed);
  }

  Future<void> _pickAndUploadImage() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (picked != null) {
        final file = File(picked.path);
        final compressedFile = await _compressImage(file);
        final uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
        final fileName = 'product_$uniqueId.jpg';
        
        final ref = FirebaseStorage.instance.ref().child('product/$fileName');
        
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploaded_at': DateTime.now().toIso8601String(),
          },
        );

        await ref.putFile(compressedFile, metadata);
        final url = await ref.getDownloadURL();

        setState(() {
          _selectedImage = file;
          imageUrl = url;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de l\'upload de l\'image : ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le produit' : 'Ajouter un produit'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nom'),
                    validator: (value) {
                      if (value!.isEmpty) return 'Champ requis';
                      if (value.length < 3) return 'Le nom doit faire au moins 3 caractères';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Prix'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isEmpty) return 'Champ requis';
                      final price = double.tryParse(value);
                      if (price == null) return 'Prix invalide';
                      if (price <= 0) return 'Le prix doit être supérieur à 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: quantityController,
                    decoration: const InputDecoration(labelText: 'Quantité en stock'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isEmpty) return 'Champ requis';
                      final quantity = int.tryParse(value);
                      if (quantity == null) return 'Nombre invalide';
                      if (quantity < 0) return 'La quantité ne peut pas être négative';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: category,
                    items: categories.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c));
                    }).toList(),
                    onChanged: (value) => setState(() => category = value!),
                    decoration: const InputDecoration(labelText: 'Catégorie'),
                    validator: (value) => value == null ? 'Veuillez sélectionner une catégorie' : null,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _pickAndUploadImage,
                    icon: const Icon(Icons.image),
                    label: Text(_isLoading ? "Chargement..." : "Importer une image"),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedImage != null || imageUrl != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Aperçu :'),
                        const SizedBox(height: 8),
                        Image.file(
                          _selectedImage ?? File(''),
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.network(imageUrl!, height: 150, fit: BoxFit.cover);
                          },
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProduct,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: Text(isEditing ? 'Mettre à jour' : 'Ajouter'),
                  )
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final product = {
        'name': nameController.text,
        'price': double.parse(priceController.text),
        'quantity': int.parse(quantityController.text),
        'image': imageUrl ?? '',
        'category': category ?? 'non_classé',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final productRef = FirebaseFirestore.instance.collection('product');

      if (widget.productId != null) {
        await productRef.doc(widget.productId).update(product);
      } else {
        await productRef.add(product);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.productId != null ? 'Produit modifié ✅' : 'Produit ajouté ✅'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la sauvegarde : ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
