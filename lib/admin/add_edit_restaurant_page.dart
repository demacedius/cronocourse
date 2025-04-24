import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

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
  final adresseController = TextEditingController();
  bool isSaving = false;
  String? imageUrl;
  File? _selectedImage;
  bool _imageError = false;
  bool isRestaurantClosed = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      nameController.text = widget.initialData!['name'] ?? '';
      adresseController.text = widget.initialData!['adresse'] ?? '';
      imageUrl = widget.initialData!['image_url'];
      isRestaurantClosed = widget.initialData!['isClosed'] ?? false;
    }
  }

  Future<void> _deleteCurrentImage() async {
    if (imageUrl != null) {
      try {
        setState(() => isSaving = true);
        // Extraire le nom du fichier de l'URL
        final fileName = imageUrl!.split('/').last.split('?').first;
        final ref = FirebaseStorage.instance.ref().child('restaurants/$fileName');
        
        // Vérifier si l'image existe avant de la supprimer
        try {
          await ref.getMetadata();
          await ref.delete();
        } catch (e) {
          // Si l'image n'existe pas, on continue sans erreur
          print('Image non trouvée dans le storage, continuation...');
        }
        
        setState(() {
          imageUrl = null;
          _selectedImage = null;
          _imageError = false;
        });
      } catch (e) {
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
        // Supprimer l'ancienne image si elle existe
        if (imageUrl != null) {
          await _deleteCurrentImage();
        }

        final file = File(picked.path);
        final compressedFile = await _compressImage(file);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(picked.path)}';
        final ref = FirebaseStorage.instance.ref().child('restaurants/$fileName');

        await ref.putFile(compressedFile);
        final url = await ref.getDownloadURL();

        setState(() {
          _selectedImage = file;
          imageUrl = url;
          _imageError = false;
        });
      }
    } catch (e) {
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
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final compressedFile = File('$path/$fileName.jpg');

    final image = img.decodeImage(await file.readAsBytes());
    if (image == null) return file;

    final compressed = img.copyResize(image, width: 800);
    await compressedFile.writeAsBytes(img.encodeJpg(compressed, quality: 85));

    return compressedFile;
  }

  Future<void> _saveRestaurant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    final data = {
      'name': nameController.text.trim(),
      'adresse': adresseController.text.trim(),
      'image_url': imageUrl,
      'isClosed': isRestaurantClosed,
      'updated_at': FieldValue.serverTimestamp(),
    };

    final ref = FirebaseFirestore.instance.collection('restaurant');

    try {
      if (widget.restaurantId == null) {
        data['created_at'] = FieldValue.serverTimestamp();
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
                  decoration: const InputDecoration(labelText: "Nom du restaurant"),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Nom requis" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: adresseController,
                  decoration: const InputDecoration(labelText: "Adresse"),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Adresse requise" : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Restaurant fermé'),
                    const Spacer(),
                    Switch(
                      value: isRestaurantClosed,
                      onChanged: (bool value) {
                        setState(() {
                          isRestaurantClosed = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isSaving ? null : _saveRestaurant,
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
