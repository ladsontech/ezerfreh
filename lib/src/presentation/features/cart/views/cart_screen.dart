import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezer_fresh/src/core/providers/providers.dart';
import 'package:ezer_fresh/src/presentation/widgets/location_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class _DeliveryLocation {
  final String address;
  final String apartmentSuite;
  final double latitude;
  final double longitude;

  const _DeliveryLocation({
    required this.address,
    required this.apartmentSuite,
    required this.latitude,
    required this.longitude,
  });
}

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  Future<void> _showCompleteProfileDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.person_outline, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            Text(
              'Profile Required',
              style: GoogleFonts.lato(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Please complete your profile before checking out.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/create-profile');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Complete Profile'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPhoneRequiredDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.phone_outlined, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Phone Number Required',
                style: GoogleFonts.lato(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Please add your phone number to your profile so our rider can contact you about your delivery.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/create-profile');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Add Phone Number'),
          ),
        ],
      ),
    );
  }

  Future<_DeliveryLocation?> _selectDeliveryLocation(
    BuildContext context,
    Map<String, dynamic> profileData,
  ) async {
    final savedAddress = (profileData['address'] as String?)?.trim() ?? '';
    final savedApartmentSuite =
        (profileData['apartmentSuite'] as String?)?.trim() ?? '';
    final savedLatitude = (profileData['latitude'] as num?)?.toDouble();
    final savedLongitude = (profileData['longitude'] as num?)?.toDouble();
    final savedLatLng = savedLatitude != null && savedLongitude != null
        ? LatLng(savedLatitude, savedLongitude)
        : null;

    return showModalBottomSheet<_DeliveryLocation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          height: MediaQuery.sizeOf(sheetContext).height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: LocationPicker(
            initialAddress: savedAddress.isNotEmpty ? savedAddress : null,
            initialLatLng: savedLatLng,
            initialApartmentSuite: savedApartmentSuite.isNotEmpty
                ? savedApartmentSuite
                : null,
            preferCurrentLocation: true,
            confirmButtonLabel: 'Deliver Here',
            onLocationSelected: (latLng, address, apartmentSuite) {
              Navigator.of(sheetContext).pop(
                _DeliveryLocation(
                  address: address,
                  apartmentSuite: apartmentSuite,
                  latitude: latLng.latitude,
                  longitude: latLng.longitude,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _placeOrder(
    BuildContext context,
    WidgetRef ref,
    String userId,
    Map<String, dynamic> profileData,
    _DeliveryLocation deliveryLocation,
    List<CartItem> cartItems,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    // Keep the dialog's own context so we close exactly that route later.
    // Popping via the screen's context pops whatever happens to sit on top
    // of the navigator, which is how a stuck spinner can end up closing the
    // cart screen instead of itself.
    BuildContext? loadingContext;
    var loadingVisible = true;

    void closeLoading() {
      if (!loadingVisible) return;
      loadingVisible = false;
      final dialogContext = loadingContext;
      if (dialogContext != null && dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        loadingContext = dialogContext;
        // canPop: false so the Android back button can't dismiss the spinner
        // behind our back — otherwise closeLoading() would later pop a route
        // that isn't the dialog.
        return const PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator(color: Colors.green)),
        );
      },
    );

    try {
      final firestore = FirebaseFirestore.instance;
      final total = cartItems.fold<double>(
        0,
        (total, item) => total + (item.product.price * item.quantity),
      );

      final itemsMap = cartItems
          .map(
            (item) => {
              'productId': item.product.id,
              'name': item.product.name,
              'quantity': item.quantity,
              'price': item.product.price,
            },
          )
          .toList();

      final orderData = <String, dynamic>{
        'userId': userId,
        'items': itemsMap,
        'totalAmount': total,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'Pending',
        'address': deliveryLocation.address,
        'apartmentSuite': deliveryLocation.apartmentSuite,
        'latitude': deliveryLocation.latitude,
        'longitude': deliveryLocation.longitude,
        // Customer contact info — visible to admin and rider
        'customerName': profileData['name'] ?? '',
        'customerPhone': profileData['contact'] ?? '',
        'customerEmail': profileData['email'] ?? '',
      };

      // Offline persistence is switched on in main.dart, and that changes
      // what this Future means: Firestore commits the order to its local
      // cache straight away (durably — it survives an app restart and syncs
      // by itself), but only completes this Future once the *server* has
      // acknowledged the write. On a dropped or weak connection it simply
      // never completes, which is exactly what left checkout spinning
      // forever even though the order had been captured.
      //
      // So cap the wait. A timeout here means "not yet confirmed by the
      // server", not "failed" — the order is already safe locally.
      var pendingSync = false;
      try {
        await firestore
            .collection('orders')
            .add(orderData)
            .timeout(const Duration(seconds: 12));
      } on TimeoutException {
        pendingSync = true;
      }

      ref.read(cartProvider.notifier).clear();

      closeLoading();
      if (!context.mounted) return;
      _showSuccessDialog(context, pendingSync: pendingSync);
    } catch (e, stackTrace) {
      debugPrint('ERROR PLACING ORDER: $e\n$stackTrace');
      closeLoading();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog(BuildContext context, {bool pendingSync = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              'Order Placed!',
              style: GoogleFonts.lato(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              pendingSync
                  ? 'Your order is saved and will reach our shop automatically as soon as you are back online. You can track it in the Orders tab.'
                  : 'Your fresh produce order has been sent to our shop. You can track its progress in the Orders tab.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/orders');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Track Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The one and only "what happens when Checkout is tapped" flow, shared
  /// by both the narrow (fixed bottom bar) and wide (side summary panel)
  /// layouts below so they never drift out of sync. Guests only ever see
  /// the "Sign In Required" prompt here — at the moment they try to order,
  /// never before.
  Future<void> _handleCheckout(
    BuildContext context,
    WidgetRef ref,
    User? authUser,
    AsyncValue<DocumentSnapshot>? profileAsync,
    List<CartItem> cartItems,
  ) async {
    if (authUser == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.login, color: Color(0xFF2E7D32), size: 28),
              const SizedBox(width: 8),
              Text(
                'Sign In Required',
                style: GoogleFonts.lato(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Please sign in or create an account to place your order. Your cart will be saved.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Sign In'),
            ),
          ],
        ),
      );
      return;
    }

    final profileData = profileAsync?.value?.data() as Map<String, dynamic>?;

    if (profileData == null ||
        profileData['name'] == null ||
        (profileData['name'] as String).trim().isEmpty) {
      _showCompleteProfileDialog(context);
    } else if (profileData['contact'] == null ||
        (profileData['contact'] as String).trim().isEmpty) {
      // Phone number required for delivery coordination
      _showPhoneRequiredDialog(context);
    } else {
      final deliveryLocation = await _selectDeliveryLocation(
        context,
        profileData,
      );
      if (deliveryLocation == null || !context.mounted) return;

      await _placeOrder(
        context,
        ref,
        authUser.uid,
        profileData,
        deliveryLocation,
        cartItems,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authUser = ref.watch(authStateProvider).value;
    final profileAsync = authUser != null
        ? ref.watch(userProfileProvider(authUser.uid))
        : null;
    final total = ref.read(cartProvider.notifier).total;
    final itemCount = cartItems.fold<int>(0, (sum, item) => sum + item.quantity);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                ref.read(cartProvider.notifier).clear();
              },
              tooltip: 'Clear Cart',
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Add some fresh items to get started!'),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;

                if (!wide) {
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) =>
                              _CartItemRow(cartItem: cartItems[index]),
                        ),
                      ),
                      _CheckoutBar(
                        total: total,
                        onCheckout: () => _handleCheckout(
                          context,
                          ref,
                          authUser,
                          profileAsync,
                          cartItems,
                        ),
                      ),
                    ],
                  );
                }

                // Wide/web layout: items list on the left, a non-scrolling
                // order summary docked on the right — proper use of the
                // extra horizontal space instead of one mobile-style
                // column stretched across the whole browser window.
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: ListView.builder(
                              itemCount: cartItems.length,
                              itemBuilder: (context, index) =>
                                  _CartItemRow(cartItem: cartItems[index]),
                            ),
                          ),
                          const SizedBox(width: 24),
                          SizedBox(
                            width: 360,
                            child: _OrderSummaryPanel(
                              total: total,
                              itemCount: itemCount,
                              onCheckout: () => _handleCheckout(
                                context,
                                ref,
                                authUser,
                                profileAsync,
                                cartItems,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// A single cart row — same markup used by both the narrow and wide
/// layouts so the two never look inconsistent with each other.
class _CartItemRow extends ConsumerWidget {
  final CartItem cartItem;

  const _CartItemRow({required this.cartItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = cartItem.product;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.hardEdge,
              child: _cartItemImage(product.imageUrl),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'UGX ${product.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    ref.read(cartProvider.notifier).decrementItem(product.id);
                  },
                ),
                Text(
                  '${cartItem.quantity}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    ref.read(cartProvider.notifier).addItem(product);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _cartItemImage(String url) {
  if (url.isEmpty || url.startsWith('assets/')) {
    return const Icon(Icons.shopping_basket_outlined, color: Colors.grey);
  }
  return CachedNetworkImage(
    imageUrl: url,
    fit: BoxFit.cover,
    placeholder: (context, url) => Container(
      color: Colors.grey[100],
      child: const Center(
        child: SizedBox(
          height: 15,
          width: 15,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
        ),
      ),
    ),
    errorWidget: (context, url, error) =>
        const Icon(Icons.broken_image, color: Colors.grey),
  );
}

/// Fixed bottom checkout bar used on narrow (phone-width) layouts.
class _CheckoutBar extends StatelessWidget {
  final double total;
  final VoidCallback onCheckout;

  const _CheckoutBar({required this.total, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'UGX ${NumberFormat('#,##0').format(total)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onCheckout,
                child: const Text(
                  'Checkout',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Non-scrolling order summary docked on the right of the wide/web layout
/// — the desktop equivalent of [_CheckoutBar], showing the same total and
/// the same Checkout action, just laid out for the extra space instead of
/// pinned to the bottom of a phone screen.
class _OrderSummaryPanel extends StatelessWidget {
  final double total;
  final int itemCount;
  final VoidCallback onCheckout;

  const _OrderSummaryPanel({
    required this.total,
    required this.itemCount,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$itemCount item${itemCount == 1 ? '' : 's'}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              Text(
                'UGX ${NumberFormat('#,##0').format(total)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'UGX ${NumberFormat('#,##0').format(total)}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onCheckout,
              child: const Text(
                'Checkout',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Free delivery details confirmed at checkout',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
