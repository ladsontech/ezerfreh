import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezer_fresh/src/domain/models/product_model.dart';

class UploadProductScreen extends StatefulWidget {
  final Product? productToEdit;
  const UploadProductScreen({super.key, this.productToEdit});

  @override
  State<UploadProductScreen> createState() => _UploadProductScreenState();
}

class _UploadProductScreenState extends State<UploadProductScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _unitController = TextEditingController();
  String? _selectedCategoryId;

  XFile? _imageFile; // Works on both Web and Mobile
  Uint8List? _previewBytes; // For immediate preview

  final _picker = ImagePicker();
  bool _isLoading = false;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.productToEdit != null) {
      _nameController.text = widget.productToEdit!.name;
      _descriptionController.text = widget.productToEdit!.description;
      _priceController.text = widget.productToEdit!.price.toStringAsFixed(0);
      _unitController.text = widget.productToEdit!.unit;
      _selectedCategoryId = widget.productToEdit!.categoryId;
      _existingImageUrl = widget.productToEdit!.imageUrl;
    }
  }

  final List<Map<String, String>> _categories = [
    {'id': '1', 'name': 'Vegetables'},
    {'id': '2', 'name': 'Fruits'},
    {'id': '3', 'name': 'Herbs'},
    {'id': '4', 'name': 'Spices'},
  ];

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageFile = pickedFile;
        _previewBytes = bytes;
      });
    }
  }

  Future<void> _uploadProduct() async {
    if (_imageFile == null && _existingImageUrl == null) {
      _showError('Please select an image.');
      return;
    }

    if (_nameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _unitController.text.isEmpty ||
        _selectedCategoryId == null) {
      _showError('Please fill all fields.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String imageUrl = _existingImageUrl ?? '';

      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        final fileName = _imageFile!.name;
        final extension = fileName.contains('.')
            ? fileName.split('.').last.toLowerCase()
            : 'jpg';
        final contentType = switch (extension) {
          'png' => 'image/png',
          'gif' => 'image/gif',
          'webp' => 'image/webp',
          'bmp' => 'image/bmp',
          _ => 'image/jpeg',
        };

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('product_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.$extension');

        final metadata = SettableMetadata(
          contentType: contentType,
          cacheControl: 'public, max-age=31536000',
        );

        await storageRef.putData(bytes, metadata);
        imageUrl = await storageRef.getDownloadURL();
      }

      final data = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text),
        'unit': _unitController.text.trim(),
        'imageUrl': imageUrl,
        'categoryId': _selectedCategoryId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.productToEdit != null) {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.productToEdit!.id)
            .update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('products').add(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.productToEdit != null ? 'Updated!' : 'Published!',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showError('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F3),
      appBar: AppBar(
        title: Text(
          widget.productToEdit != null ? 'Edit Product' : 'New Product',
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 820;
                      final imagePicker = GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: isWide ? 420 : 240,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE0E5DE)),
                          ),
                          child: _buildImagePreview(),
                        ),
                      );
                      final formPanel = Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE0E5DE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              widget.productToEdit != null
                                  ? 'Edit inventory item'
                                  : 'Create inventory item',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildForm(),
                            const SizedBox(height: 28),
                            FilledButton.icon(
                              onPressed: _uploadProduct,
                              icon: Icon(
                                widget.productToEdit != null
                                    ? Icons.save_outlined
                                    : Icons.publish_outlined,
                              ),
                              label: Text(
                                widget.productToEdit != null
                                    ? 'Update Product'
                                    : 'Publish Product',
                              ),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (!isWide) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            imagePicker,
                            const SizedBox(height: 20),
                            formPanel,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: imagePicker),
                          const SizedBox(width: 24),
                          Expanded(flex: 6, child: formPanel),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildImagePreview() {
    if (_previewBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(_previewBytes!, fit: BoxFit.cover),
      );
    } else if (_existingImageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: _existingImageUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(),
          ),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      );
    }

    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey),
        SizedBox(height: 8),
        Text('Select Product Photo', style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: _selectedCategoryId,
          items: _categories
              .map(
                (c) =>
                    DropdownMenuItem(value: c['id'], child: Text(c['name']!)),
              )
              .toList(),
          onChanged: (val) => setState(() => _selectedCategoryId = val),
          decoration: const InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Product Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price (UGX)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _unitController,
                decoration: const InputDecoration(
                  labelText: 'Unit (e.g. / Kg)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
