import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

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
  final priceController = TextEditingController();
  final categoryController = TextEditingController();
  bool isSaving = false;
  String? imageUrl;
  File? _selectedImage;
  bool _imageError = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      nameController.text = widget.initialData!['name'] ?? '';
      imageUrl = widget.initialData!['image_url'];
      priceController.text = (widget.initialData!['prix'] ?? '').toString();
      categoryController.text = widget.initialData!['category'] ?? '';
    }
  }

  Future<void> _deleteCurrentImage() async {
    if (imageUrl != null) {
      try {
        setState(() => isSaving = true);
        final fileName = imageUrl!.split('/').last.split('?').first;
        final ref = FirebaseStorage.instance.ref().child('menus/$fileName');
        
        try {
          final metadata = await ref.getMetadata();
          await ref.delete();
          print('Image supprimée avec succès: $fileName');
                } catch (e) {
          print('Image non trouvée dans le storage: $fileName');
        }
        
        setState(() {
          imageUrl = null;
          _selectedImage = null;
          _imageError = false;
        });
      } catch (e) {
        print('Erreur lors de la suppression: ${e.toString()}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression de l\'image : ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      setState(() => isSaving = true);

      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (picked != null) {
        if (imageUrl != null) {
          await _deleteCurrentImage();
        }

        final file = File(picked.path);
        final compressedFile = await _compressImage(file);
        
        final uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
        final fileName = 'menu_$uniqueId.jpg';
        
        print('Début de l\'upload de l\'image: $fileName');
        
        final fileRef = FirebaseStorage.instance.ref().child('menus/$fileName');
        
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploaded_at': DateTime.now().toIso8601String(),
          },
        );

        try {
          await fileRef.putFile(compressedFile, metadata);
          final url = await fileRef.getDownloadURL();
          
          print('Image uploadée avec succès: $url');

          setState(() {
            _selectedImage = file;
            imageUrl = url;
            _imageError = false;
          });
        } catch (uploadError) {
          print('Erreur lors de l\'upload: ${uploadError.toString()}');
          try {
            await compressedFile.delete();
          } catch (e) {
            print('Erreur lors de la suppression du fichier compressé: ${e.toString()}');
          }
          rethrow;
        }
      }
    } catch (e) {
      print('Erreur lors de l\'upload: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'upload de l\'image : ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  Future<File> _compressImage(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final path = tempDir.path;
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final compressedFile = File('$path/$fileName.jpg');

      final image = img.decodeImage(await file.readAsBytes());
      if (image == null) {
        print('Impossible de décoder l\'image');
        return file;
      }

      final compressed = img.copyResize(image, width: 800);
      await compressedFile.writeAsBytes(img.encodeJpg(compressed, quality: 85));
      
      print('Image compressée avec succès: ${compressedFile.path}');
      return compressedFile;
    } catch (e) {
      print('Erreur lors de la compression: ${e.toString()}');
      return file;
    }
  }

  Future<void> _saveMenu() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    final data = {
      'name': nameController.text.trim(),
      'image_url': imageUrl,
      'prix': double.tryParse(priceController.text) ?? 0.0,
      'category': categoryController.text.trim(),
      'updated_at': FieldValue.serverTimestamp(),
    };

    final menuRef = FirebaseFirestore.instance
        .collection('restaurant')
        .doc(widget.restaurantId)
        .collection('menu');

    try {
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
    final isEditing = widget.menuId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Modifier le menu" : "Ajouter un menu"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                if (imageUrl != null || _selectedImage != null)
                  Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image(
                            image: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : NetworkImage(imageUrl!) as ImageProvider,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              setState(() => _imageError = true);
                              return Container(
                                height: 200,
                                width: double.infinity,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      if (isEditing)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.white),
                              onPressed: _deleteCurrentImage,
                            ),
                          ),
                        ),
                    ],
                  ),
                ElevatedButton.icon(
                  onPressed: isSaving ? null : _pickAndUploadImage,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: Text(isSaving ? "Chargement..." : "Ajouter une photo"),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Nom du menu"),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Champ requis" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Prix"),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Champ requis";
                    if (double.tryParse(value) == null) return "Nombre invalide";
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
                  onPressed: isSaving ? null : _saveMenu,
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
      ),
    );
  }
}
