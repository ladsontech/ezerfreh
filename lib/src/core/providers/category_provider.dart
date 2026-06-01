import 'package:ezer_fresh/src/domain/models/category_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final categoriesProvider = Provider<List<Category>>((ref) {
  return const [
    Category(id: '1', name: 'Vegetables', imageUrl: 'assets/vegetables.png'),
    Category(id: '2', name: 'Fruits', imageUrl: 'assets/fruits.png'),
    Category(id: '3', name: 'Herbs', imageUrl: 'assets/herbs.png'),
    Category(id: '4', name: 'Spices', imageUrl: 'assets/spices.png'),
  ];
});
