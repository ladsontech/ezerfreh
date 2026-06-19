import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezer_fresh/src/core/providers/product_provider.dart';
import 'package:ezer_fresh/src/domain/models/product_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class UploadProductScreen extends ConsumerStatefulWidget {
  final Product? productToEdit;
  final String? productId;

  const UploadProductScreen({super.key, this.productToEdit, this.productId});

  @override
  ConsumerState<UploadProductScreen> createState() =>
      _UploadProductScreenState();
}

class _UploadProductScreenState extends ConsumerState<UploadProductScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _unitController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String? _selectedCategoryId;

  XFile? _imageFile; // Works on both Web and Mobile
  Uint8List? _previewBytes; // For immediate preview

  final _picker = ImagePicker();
  bool _isLoading = false;
  bool _syncingForm = false;
  String? _existingImageUrl;
  String? _editingProductId;

  @override
  void initState() {
    super.initState();
    _imageUrlController.addListener(() {
      if (_syncingForm) return;
      setState(() {});
    });
    if (widget.productToEdit != null) {
      _populateForm(widget.productToEdit!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  final List<Map<String, String>> _categories = [
    {'id': '1', 'name': 'Vegetables'},
    {'id': '2', 'name': 'Fruits'},
    {'id': '3', 'name': 'Herbs'},
    {'id': '4', 'name': 'Spices'},
  ];

  bool get _isEditing => _editingProductId != null || widget.productId != null;

  void _populateForm(Product product) {
    if (_editingProductId == product.id) return;

    _syncingForm = true;
    _editingProductId = product.id;
    _nameController.text = product.name;
    _descriptionController.text = product.description;
    _priceController.text = product.price.toStringAsFixed(0);
    _unitController.text = product.unit;
    _selectedCategoryId = product.categoryId;
    _existingImageUrl = product.imageUrl;
    _imageUrlController.text = product.imageUrl;
    _syncingForm = false;
  }

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
    final manualUrl = _imageUrlController.text.trim();
    if (_imageFile == null && _existingImageUrl == null && manualUrl.isEmpty) {
      _showError('Please select an image or enter an image URL.');
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

    final price = double.tryParse(
      _priceController.text.trim().replaceAll(',', ''),
    );
    if (price == null || price <= 0) {
      _showError('Please enter a valid price.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String imageUrl = manualUrl.isNotEmpty
          ? manualUrl
          : (_existingImageUrl ?? '');

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

      final selectedCategory = _categories.firstWhere(
        (category) => category['id'] == _selectedCategoryId,
        orElse: () => {'id': _selectedCategoryId ?? '1', 'name': 'Produce'},
      );
      final data = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': price,
        'unit': _unitController.text.trim(),
        'imageUrl': imageUrl,
        'categoryId': _selectedCategoryId,
        'categoryName': selectedCategory['name'],
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_editingProductId != null) {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(_editingProductId)
            .update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('products').add(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Product updated' : 'Product published'),
          ),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.pop(context);
        } else {
          context.go('/admin/products');
        }
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
    final productId = widget.productId;
    if (widget.productToEdit == null && productId != null) {
      final productAsync = ref.watch(productByIdProvider(productId));
      return productAsync.when(
        data: (product) {
          if (product == null) {
            return _buildMessageScaffold(
              title: 'Product unavailable',
              message: 'This product could not be found.',
            );
          }
          _populateForm(product);
          return _buildEditorScaffold();
        },
        loading: () => _buildLoadingScaffold(),
        error: (error, _) => _buildMessageScaffold(
          title: 'Product unavailable',
          message: 'Could not load this product: $error',
        ),
      );
    }

    return _buildEditorScaffold();
  }

  Widget _buildLoadingScaffold() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F3),
      appBar: _buildAppBar(),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildMessageScaffold({
    required String title,
    required String message,
  }) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F3),
      appBar: _buildAppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 42,
                color: Color(0xFF7A7F7A),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => context.go('/admin/products'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Products'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_isEditing ? 'Edit Product' : 'New Product'),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    );
  }

  Widget _buildEditorScaffold() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F3),
      appBar: _buildAppBar(),
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
                              _isEditing
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
                                _isEditing
                                    ? Icons.save_outlined
                                    : Icons.publish_outlined,
                              ),
                              label: Text(
                                _isEditing
                                    ? 'Update Product'
                                    : 'Publish Product',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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
    }

    final urlInput = _imageUrlController.text.trim();
    final url = urlInput.isNotEmpty
        ? urlInput
        : (_existingImageUrl ?? '').trim();

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      );
    } else if (url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.green.shade100),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.green.shade100),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2E7D32)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          decoration: _inputDecoration('Category'),
          dropdownColor: Colors.white,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: _inputDecoration('Product Name'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: _inputDecoration('Description'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Price (UGX)'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _unitController,
                decoration: _inputDecoration('Unit (e.g. / Kg)'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _imageUrlController,
          decoration: _inputDecoration('Image URL (Optional)'),
        ),
      ],
    );
  }
}
