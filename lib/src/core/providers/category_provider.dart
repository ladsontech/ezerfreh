import 'package:ezer_fresh/src/domain/models/category_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  // For now, we'll use dummy data. Later, this will be replaced with a real API call.
  await Future.delayed(const Duration(seconds: 1));

  return [
    const Category(id: '1', name: 'Vegetables', imageUrl: 'assets/vegetables.png'),
    const Category(id: '2', name: 'Fruits', imageUrl: 'assets/fruits.png'),
    const Category(id: '3', name: 'Herbs', imageUrl: 'assets/herbs.png'),
    const Category(id: '4', name: 'Spices', imageUrl: 'assets/spices.png'),
  ];
});
