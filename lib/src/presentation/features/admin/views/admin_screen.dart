
import 'package:flutter/material.dart';
import 'package:myapp/src/presentation/features/admin/views/upload_product_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UploadProductScreen()),
            );
          },
          child: const Text('Upload Product'),
        ),
      ),
    );
  }
}
