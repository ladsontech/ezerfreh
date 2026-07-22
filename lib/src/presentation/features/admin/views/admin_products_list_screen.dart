import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezer_fresh/src/core/providers/product_provider.dart';
import 'package:ezer_fresh/src/domain/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AdminProductsListScreen extends ConsumerStatefulWidget {
  final bool isTab;
  const AdminProductsListScreen({super.key, this.isTab = false});

  @override
  ConsumerState<AdminProductsListScreen> createState() =>
      _AdminProductsListScreenState();
}

class _AdminProductsListScreenState
    extends ConsumerState<AdminProductsListScreen> {
  String _query = '';
  String _category = 'All';

  static const _categories = {
    'All': 'All',
    '1': 'Vegetables',
    '2': 'Fruits',
    '3': 'Herbs',
    '4': 'Spices',
  };

  @override
  Widget build(BuildContext context) {
    final productsAsyncValue = ref.watch(adminProductsProvider);

    Widget content = productsAsyncValue.when(
      data: (products) {
        final filtered = products.where((product) {
          final matchesSearch =
              _query.isEmpty ||
              product.name.toLowerCase().contains(_query.toLowerCase()) ||
              product.description.toLowerCase().contains(_query.toLowerCase());
          final matchesCategory =
              _category == 'All' || product.categoryId == _category;
          return matchesSearch && matchesCategory;
        }).toList();

        return Column(
          children: [
            _buildProductToolbar(context, products.length, filtered.length),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No matching products found.'))
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 900;
                        if (isWide) {
                          return _buildDesktopTable(context, filtered);
                        }
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 240,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: 0.58,
                              ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) =>
                              _buildProductCard(context, filtered[index]),
                        );
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('Error: $error')),
    );

    if (widget.isTab) return content;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Products')),
      body: content,
    );
  }

  Widget _buildProductToolbar(
    BuildContext context,
    int totalCount,
    int filteredCount,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final search = SizedBox(
            height: 38,
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.grey,
                  size: 18,
                ),
                hintText: 'Search products',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          );
          final category = SizedBox(
            height: 38,
            child: DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              isDense: true,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              dropdownColor: Colors.white,
              items: _categories.entries
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _category = value ?? 'All'),
            ),
          );

          final count = Text(
            '$filteredCount / $totalCount',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Colors.grey,
            ),
          );
          final addButton = FilledButton.icon(
            onPressed: () => context.push('/admin/upload'),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add', style: TextStyle(fontSize: 13)),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                search,
                const SizedBox(height: 12),
                category,
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: count),
                    addButton,
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              SizedBox(width: 320, child: search),
              const SizedBox(width: 12),
              SizedBox(width: 180, child: category),
              const SizedBox(width: 16),
              Expanded(child: count),
              addButton,
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesktopTable(BuildContext context, List<Product> products) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE8ECE8)),
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF7FAF6)),
            dataRowMinHeight: 72,
            dataRowMaxHeight: 82,
            columns: const [
              DataColumn(label: Text('PRODUCT')),
              DataColumn(label: Text('CATEGORY')),
              DataColumn(label: Text('PRICE')),
              DataColumn(label: Text('UNIT')),
              DataColumn(label: Text('ACTIONS')),
            ],
            rows: products
                .map(
                  (product) => DataRow(
                    cells: [
                      DataCell(_ProductNameCell(product: product)),
                      DataCell(
                        Text(_categories[product.categoryId] ?? 'Other'),
                      ),
                      DataCell(
                        Text(
                          'UGX ${NumberFormat('#,##0').format(product.price)}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      DataCell(Text(product.unit)),
                      DataCell(_ProductActions(product: product)),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8ECE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(aspectRatio: 1.3, child: _ProductImage(product: product)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _categories[product.categoryId] ?? 'Other',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  'UGX ${NumberFormat('#,##0').format(product.price)} ${product.unit}',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                _ProductActions(product: product),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductNameCell extends StatelessWidget {
  final Product product;

  const _ProductNameCell({required this.product});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 54,
          height: 54,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _ProductImage(product: product),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 240,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                product.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductActions extends ConsumerWidget {
  final Product product;

  const _ProductActions({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Edit product',
          child: IconButton.filledTonal(
            onPressed: () => context.push(
              '/admin/products/${Uri.encodeComponent(product.id)}/edit',
            ),
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Delete product',
          child: IconButton(
            onPressed: () => _confirmDelete(context, ref, product),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text('Delete ${product.name} from the shop?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await FirebaseFirestore.instance
        .collection('products')
        .doc(product.id)
        .delete();
    await ref.read(productRepositoryProvider).clearCache();
    ref.invalidate(allProductsProvider);
    ref.invalidate(adminProductsProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${product.name} deleted')));
  }
}

class _ProductImage extends StatelessWidget {
  final Product product;

  const _ProductImage({required this.product});

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl.trim();
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        maxWidthDiskCache: 300,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (context, url, error) => const _ProductImageFallback(),
      );
    }
    if (imageUrl.isNotEmpty && !imageUrl.contains('placeholder')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _ProductImageFallback(),
      );
    }
    return const _ProductImageFallback();
  }
}

class _ProductImageFallback extends StatelessWidget {
  const _ProductImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF2F6F0),
      child: const Icon(Icons.shopping_basket_outlined, color: Colors.grey),
    );
  }
}
