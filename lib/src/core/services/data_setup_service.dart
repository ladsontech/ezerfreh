import 'package:cloud_firestore/cloud_firestore.dart';

class DataSetupService {
  static Future<void> initializeInventory() async {
    print('DEBUG: Starting Idempotent Full Initialization...');
    try {
      await uploadVegetables();
      await uploadFruits();
      await forceRepairSpecialized();
      print('DEBUG: Full Initialization Successful!');
    } catch (e) {
      print('DEBUG ERROR in Full Init: $e');
      rethrow;
    }
  }

  static Future<void> cleanupAllDuplicates() async {
    print('DEBUG: Starting Global Atomic Deduplication...');
    final firestore = FirebaseFirestore.instance;
    final collection = firestore.collection('products');
    
    final allProducts = await collection.get();
    final Map<String, String> seenNames = {}; // normalizedName_catId -> docId
    int deletedCount = 0;

    // Use a batch for efficiency
    final batch = firestore.batch();
    int batchCount = 0;

    for (var doc in allProducts.docs) {
      final data = doc.data();
      final name = (data['name'] as String? ?? '').trim().toLowerCase();
      final catId = data['categoryId'] as String? ?? '';
      
      // We ALSO check the Document ID itself. 
      // If it's a random Firebase ID (20 chars, random), we prefer to clean it
      // in favor of our new Deterministic IDs.
      final bool isRandomId = doc.id.length == 20 && !doc.id.contains('-');
      
      final key = '${name}_$catId';

      if (seenNames.containsKey(key) || isRandomId) {
        batch.delete(doc.reference);
        deletedCount++;
        batchCount++;
      } else {
        seenNames[key] = doc.id;
      }
      
      if (batchCount >= 400) { // Firestore batch limit is 500
        await batch.commit();
        batchCount = 0;
      }
    }
    
    if (batchCount > 0) await batch.commit();
    print('DEBUG: Atomic Deduplication Complete. Removed $deletedCount items.');
  }

  static Future<void> uploadVegetables() async {
    final vegetables = [
      {"name": "Cherry tomatoes", "price": 10000.0, "unit": "/ kg"},
      {"name": "Drum stick", "price": 2000.0, "unit": "/ bundle"},
      {"name": "Kale", "price": 4000.0, "unit": "/ kg"},
      {"name": "Okra", "price": 3000.0, "unit": "/ kg"},
      {"name": "Rocket leaves", "price": 5000.0, "unit": "/ bag"},
      {"name": "Radish", "price": 3000.0, "unit": "/ kg"},
      {"name": "Cassava", "price": 2000.0, "unit": "/ kg"},
      {"name": "Sweet potatoes", "price": 2500.0, "unit": "/ kg"},
      {"name": "White cabbage", "price": 2500.0, "unit": "/ piece"},
      {"name": "Beetroot", "price": 4000.0, "unit": "/ kg"},
      {"name": "Lettuce", "price": 3000.0, "unit": "/ piece"},
      {"name": "Iceberg", "price": 3000.0, "unit": "/ piece"},
      {"name": "Yellow bell pepper", "price": 12000.0, "unit": "/ kg"},
      {"name": "Red bell pepper", "price": 12000.0, "unit": "/ kg"},
      {"name": "Irish potato", "price": 2000.0, "unit": "/ kg"},
      {"name": "Zucchini", "price": 4000.0, "unit": "/ kg"},
      {"name": "Tomatoes", "price": 5000.0, "unit": "/ kg"},
      {"name": "Celery", "price": 3000.0, "unit": "/ piece"},
      {"name": "Broccoli", "price": 4000.0, "unit": "/ piece"},
      {"name": "Cucumber", "price": 3000.0, "unit": "/ kg"},
      {"name": "Cauliflower", "price": 4000.0, "unit": "/ kg"},
      {"name": "Carrot", "price": 2500.0, "unit": "/ kg"},
      {"name": "Rosemary", "price": 5000.0, "unit": "/ bundle"},
      {"name": "Mint leaves", "price": 7000.0, "unit": "/ kg"},
      {"name": "Sugarcane", "price": 5000.0, "unit": "/ piece"},
      {"name": "Aloe vera", "price": 2000.0, "unit": "/ piece"},
      {"name": "Fresh Mushroom", "price": 10000.0, "unit": "/ kg"},
      {"name": "Dry mushroom", "price": 15000.0, "unit": "/ kg"},
      {"name": "White onions", "price": 20000.0, "unit": "/ kg"},
      {"name": "Red onions", "price": 3500.0, "unit": "/ kg"},
      {"name": "Local onions", "price": 5000.0, "unit": "/ kg"},
      {"name": "Spring onions", "price": 7000.0, "unit": "/ kg"},
      {"name": "Long beans", "price": 3000.0, "unit": "/ kg"},
      {"name": "Banana leave", "price": 500.0, "unit": "/ piece"},
      {"name": "Mpombo leaf", "price": 2000.0, "unit": "/ pair"},
      {"name": "Tongwa", "price": 5000.0, "unit": "/ piece"},
      {"name": "Egg plant", "price": 2000.0, "unit": "/ kg"},
      {"name": "Nakati", "price": 1000.0, "unit": "/ bundle"},
      {"name": "Bugga", "price": 1500.0, "unit": "/ bundle"},
      {"name": "Hot pepper", "price": 5000.0, "unit": "/ kg"},
      {"name": "Sukuma", "price": 2500.0, "unit": "/ kg"},
      {"name": "Tumeric", "price": 7000.0, "unit": "/ kg"},
      {"name": "Snake guard", "price": 7000.0, "unit": "/ kg"},
      {"name": "Taro roots", "price": 7000.0, "unit": "/ kg"},
      {"name": "Turia", "price": 5000.0, "unit": "/ kg"},
      {"name": "Fresh yam", "price": 4000.0, "unit": "/ kg"},
      {"name": "Pumpkin seeds", "price": 30000.0, "unit": "/ kg"},
      {"name": "Red cabbage", "price": 4500.0, "unit": "/ kg"},
      {"name": "Green pepper", "price": 4000.0, "unit": "/ kg"},
      {"name": "Ground nut powder", "price": 8000.0, "unit": "/ kg"},
      {"name": "Ground nut seeds", "price": 8000.0, "unit": "/ kg"},
      {"name": "Leaks", "price": 6000.0, "unit": "/ kg"},
      {"name": "Matooke", "price": 37500.0, "unit": "/ bunch"},
      {"name": "Pumpkin", "price": 4000.0, "unit": "/ piece"},
      {"name": "Plantain", "price": 3500.0, "unit": "/ kg"},
      {"name": "Green chili", "price": 5000.0, "unit": "/ kg"},
      {"name": "Fresh beans", "price": 5000.0, "unit": "/ kg"},
      {"name": "Fresh peas", "price": 12000.0, "unit": "/ kg"},
      {"name": "Garlic imported", "price": 12000.0, "unit": "/ kg"},
      {"name": "Local garlic", "price": 15000.0, "unit": "/ kg"},
      {"name": "English cucumber", "price": 3000.0, "unit": "/ kg"},
      {"name": "Spinach", "price": 3000.0, "unit": "/ kg"},
      {"name": "Bitter guard", "price": 5000.0, "unit": "/ kg"},
      {"name": "Butter nut", "price": 4500.0, "unit": "/ piece"},
    ];
    await _bulkAddIdempotent(vegetables, '1', 'assets/vegetables.png');
  }

  static Future<void> uploadFruits() async {
    final fruits = [
      {"name": "Blue berry", "price": 15000.0, "unit": "/ packet"},
      {"name": "Dragon fruit", "price": 10000.0, "unit": "/ piece"},
      {"name": "Paw paw", "price": 4500.0, "unit": "/ piece"},
      {"name": "Jack fruits", "price": 10000.0, "unit": "/ piece"},
      {"name": "Guava", "price": 6000.0, "unit": "/ kg"},
      {"name": "Bitter berries", "price": 7000.0, "unit": "/ kg"},
      {"name": "Chayote", "price": 6000.0, "unit": "/ kg"},
      {"name": "Imported lemon", "price": 2500.0, "unit": "/ kg"},
      {"name": "Cocoa", "price": 5000.0, "unit": "/ piece"},
      {"name": "Local lemon", "price": 2000.0, "unit": "/ kg"},
      {"name": "Local orange", "price": 2000.0, "unit": "/ kg"},
      {"name": "Pineapple", "price": 4000.0, "unit": "/ piece"},
      {"name": "Small banana", "price": 3500.0, "unit": "/ cluster"},
      {"name": "Passion fruits", "price": 5000.0, "unit": "/ kg"},
      {"name": "Local tangerine", "price": 2500.0, "unit": "/ kg"},
      {"name": "Mangoes", "price": 3500.0, "unit": "/ kg"},
      {"name": "Soursup", "price": 5000.0, "unit": "/ piece"},
      {"name": "Lime", "price": 5000.0, "unit": "/ kg"},
      {"name": "Water melon", "price": 7500.0, "unit": "/ piece"},
      {"name": "Pomegranate", "price": 10000.0, "unit": "/ piece"},
      {"name": "Pear imported", "price": 2500.0, "unit": "/ piece"},
      {"name": "Plums", "price": 5000.0, "unit": "/ piece"},
      {"name": "Cocoa nut", "price": 3000.0, "unit": "/ piece"},
      {"name": "Tamarind", "price": 5000.0, "unit": "/ kg"},
      {"name": "Goose berry", "price": 6000.0, "unit": "/ packet"},
      {"name": "Mandarine", "price": 15000.0, "unit": "/ kg"},
      {"name": "Orange imported", "price": 10000.0, "unit": "/ kg"},
      {"name": "Strawberry", "price": 15000.0, "unit": "/ packet"},
      {"name": "Grapes", "price": 15000.0, "unit": "/ pack"},
      {"name": "Kiwi", "price": 3000.0, "unit": "/ piece"},
      {"name": "Sweet melon", "price": 6000.0, "unit": "/ piece"},
      {"name": "Apple", "price": 1000.0, "unit": "/ piece"},
      {"name": "Avocado", "price": 1250.0, "unit": "/ piece"},
      {"name": "Bogoya/banana", "price": 6000.0, "unit": "/ cluster"},
    ];
    await _bulkAddIdempotent(fruits, '2', 'assets/fruits.png');
  }

  static Future<void> forceRepairSpecialized() async {
    final herbs = [
      {"name": "Mondia white", "price": 5000.0, "unit": "/ bundle"},
      {"name": "Almond seeds", "price": 60000.0, "unit": "/ kg"},
      {"name": "Cinnamon leaves", "price": 3000.0, "unit": "/ bundle"},
      {"name": "Lemon grass", "price": 2000.0, "unit": "/ bundle"},
      {"name": "Thyme", "price": 3000.0, "unit": "/ bundle"},
      {"name": "Rosemary", "price": 5000.0, "unit": "/ bundle"},
      {"name": "Coriander", "price": 7000.0, "unit": "/ bundle"},
      {"name": "Basil", "price": 3000.0, "unit": "/ bundle"},
      {"name": "Dill", "price": 2000.0, "unit": "/ bundle"},
      {"name": "Mint leaves", "price": 7000.0, "unit": "/ kg"},
      {"name": "Parsley", "price": 2000.0, "unit": "/ bundle"},
      {"name": "Ginger", "price": 3500.0, "unit": "/ kg"},
    ];
    final spices = [
      {"name": "Mustard seeds", "price": 250000.0, "unit": "/ kg"},
      {"name": "Tumeric powder", "price": 25000.0, "unit": "/ kg"},
      {"name": "Black cardamon", "price": 25000.0, "unit": "/ 100g"},
      {"name": "Cardamon", "price": 135000.0, "unit": "/ kg"},
      {"name": "Almond seeds", "price": 60000.0, "unit": "/ kg"},
      {"name": "Hibiscus", "price": 30000.0, "unit": "/ 250g"},
      {"name": "Cinnamon sticks", "price": 45000.0, "unit": "/ kg"},
      {"name": "Black seeds", "price": 25000.0, "unit": "/ kg"},
      {"name": "Cloves", "price": 55000.0, "unit": "/ kg"},
      {"name": "Caraway seeds", "price": 34000.0, "unit": "/ kg"},
      {"name": "Cumin seeds", "price": 30000.0, "unit": "/ kg"},
      {"name": "Black pepper", "price": 35000.0, "unit": "/ kg"},
      {"name": "Pilau masala", "price": 40000.0, "unit": "/ 500g"},
    ];

    print('DEBUG: Syncing Herbs & Spices Idempotently...');
    await _bulkAddIdempotent(herbs, '3', 'assets/herbs.png');
    await _bulkAddIdempotent(spices, '4', 'assets/spices.png');
  }

  static Future<void> _bulkAddIdempotent(List<Map<String, dynamic>> items, String catId, String placeholder) async {
    final firestore = FirebaseFirestore.instance;
    final collection = firestore.collection('products');
    
    // Use a multi-batch approach to handle large datasets
    WriteBatch batch = firestore.batch();
    int batchCount = 0;
    
    for (var item in items) {
      final name = item['name'] as String;
      // SLUGIFY the name for a deterministic ID
      final slug = name.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]'), '-');
      final docId = '$slug-$catId';
      
      final docRef = collection.doc(docId);
      batch.set(docRef, {
        'name': name,
        'price': item['price'],
        'unit': item['unit'] ?? '/ unit',
        'categoryId': catId,
        'imageUrl': placeholder,
        'description': 'Premium $name sourced for Ezer Fresh.',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      batchCount++;
      if (batchCount >= 400) {
        await batch.commit();
        batch = firestore.batch();
        batchCount = 0;
      }
    }
    
    if (batchCount > 0) await batch.commit();
    print('DEBUG: Idempotent sync complete for Category $catId.');
  }

  static Future<void> uploadVegetablesLegacy() async => initializeInventory();
}
