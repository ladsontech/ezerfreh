import 'dart:async';

import 'package:ezer_fresh/src/core/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPicker extends StatefulWidget {
  final Function(LatLng, String, String) onLocationSelected;
  final String? initialAddress;
  final LatLng? initialLatLng;
  final String? initialApartmentSuite;

  const LocationPicker({
    super.key,
    required this.onLocationSelected,
    this.initialAddress,
    this.initialLatLng,
    this.initialApartmentSuite,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  static const LatLng _defaultLocation = LatLng(0.3476, 32.5825);

  LatLng? _selectedLocation;
  String _address = 'Search for home, office, or landmark';
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _apartmentSuiteController =
      TextEditingController();

  final String _placesSessionToken =
      DateTime.now().microsecondsSinceEpoch.toString();
  Timer? _searchDebounce;
  int _searchRequestId = 0;
  List<PlaceSuggestion> _suggestions = const [];
  String? _searchError;
  bool _isSearching = false;
  bool _isLocating = false;
  bool _isConfirming = false;
  bool _canShowUserLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialApartmentSuite != null) {
      _apartmentSuiteController.text = widget.initialApartmentSuite!;
    }
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _address = widget.initialAddress!;
      _searchController.text = widget.initialAddress!;
    }
    if (widget.initialLatLng != null) {
      _selectedLocation = widget.initialLatLng;
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _mapController?.dispose();
    _searchController.dispose();
    _apartmentSuiteController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final query = value.trim();

    setState(() {
      _searchError = null;
      if (_selectedLocation != null && query != _address.trim()) {
        _selectedLocation = null;
        _address = 'Select a suggestion or confirm typed address';
      }
    });

    if (query.length < 2) {
      setState(() {
        _suggestions = const [];
        _isSearching = false;
      });
      return;
    }

    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _searchPlaces(query),
    );
  }

  Future<void> _searchPlaces(String query) async {
    final requestId = ++_searchRequestId;
    setState(() => _isSearching = true);

    try {
      final results = await _locationService.searchPlaces(
        query,
        sessionToken: _placesSessionToken,
      );
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _suggestions = results;
        _searchError = results.isEmpty ? 'No matching places found.' : null;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Place search error: $e');
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _suggestions = const [];
        _searchError = 'Place search is unavailable. You can type the address.';
        _isSearching = false;
      });
    }
  }

  Future<void> _selectSuggestion(PlaceSuggestion suggestion) async {
    _searchDebounce?.cancel();
    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final details = await _locationService.getPlaceDetails(
        suggestion.placeId,
        sessionToken: _placesSessionToken,
      );
      if (details == null) {
        throw Exception('Missing place coordinates.');
      }

      final location = LatLng(details.latitude, details.longitude);
      if (!mounted) return;
      _searchController.text = details.address;
      setState(() {
        _selectedLocation = location;
        _address = details.address;
        _suggestions = const [];
        _isSearching = false;
      });
      _animateTo(location);
    } catch (e) {
      debugPrint('Place selection error: $e');
      if (!mounted) return;
      setState(() {
        _searchError = 'Could not select that place. Please try another one.';
        _isSearching = false;
      });
    }
  }

  Future<void> _getCurrentUserLocation() async {
    if (_isLocating) return;

    setState(() {
      _isLocating = true;
      _searchError = null;
    });

    try {
      final Position position = await _locationService.getCurrentLocation();
      final location = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _selectedLocation = location;
        _canShowUserLocation = true;
        _address = 'Getting address...';
        _suggestions = const [];
      });
      _animateTo(location);
      await _updateAddress(location);
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not get current location. Search manually instead.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _updateAddress(LatLng location) async {
    final address = await _locationService.getAddressFromLatLng(
      location.latitude,
      location.longitude,
    );
    if (!mounted) return;
    _searchController.text = address;
    setState(() {
      _address = address;
    });
  }

  Future<void> _confirmLocation() async {
    final typedAddress = _searchController.text.trim();
    if (_selectedLocation != null) {
      widget.onLocationSelected(
        _selectedLocation!,
        _address.trim().isNotEmpty ? _address : typedAddress,
        _apartmentSuiteController.text.trim(),
      );
      return;
    }

    if (typedAddress.isEmpty || _isConfirming) return;

    setState(() => _isConfirming = true);
    try {
      final details = await _locationService.getPlaceFromAddress(typedAddress);
      if (details == null) {
        throw Exception('Address could not be resolved.');
      }
      final location = LatLng(details.latitude, details.longitude);
      if (!mounted) return;
      widget.onLocationSelected(
        location,
        details.address,
        _apartmentSuiteController.text.trim(),
      );
    } catch (e) {
      debugPrint('Manual address confirmation failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a suggested place or enter a clearer address.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  void _selectMapLocation(LatLng location) {
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedLocation = location;
      _suggestions = const [];
      _searchError = null;
      _address = 'Getting address...';
    });
    _updateAddress(location);
  }

  void _animateTo(LatLng location) {
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(location, 15));
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = _selectedLocation != null ||
        _searchController.text.trim().isNotEmpty && !_isConfirming;

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _selectedLocation ?? _defaultLocation,
                  zoom: _selectedLocation != null ? 15 : 12,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (_selectedLocation != null) {
                    _animateTo(_selectedLocation!);
                  }
                },
                onTap: _selectMapLocation,
                markers: _selectedLocation != null
                    ? {
                        Marker(
                          markerId: const MarkerId('selected-location'),
                          position: _selectedLocation!,
                        ),
                      }
                    : {},
                myLocationEnabled: _canShowUserLocation,
                myLocationButtonEnabled: false,
              ),
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: SafeArea(
                  bottom: false,
                  child: _buildSearchPanel(),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: _buildConfirmationPanel(canConfirm),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: 'Search home, office, or landmark',
              hintStyle: GoogleFonts.lato(fontSize: 13, color: Colors.grey[500]),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
              filled: true,
              fillColor: const Color(0xFFF8FAF8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _isLocating ? null : _getCurrentUserLocation,
            icon: _isLocating
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location, size: 18),
            label: Text(_isLocating ? 'Finding location...' : 'Use current location'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2E7D32),
              side: const BorderSide(color: Color(0xFF2E7D32)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 210),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFF2E7D32),
                    ),
                    title: Text(
                      suggestion.mainText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: suggestion.secondaryText.isNotEmpty
                        ? Text(
                            suggestion.secondaryText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.lato(fontSize: 12),
                          )
                        : null,
                    onTap: () => _selectSuggestion(suggestion),
                  );
                },
              ),
            ),
          ] else if (_searchError != null) ...[
            const SizedBox(height: 8),
            Text(
              _searchError!,
              style: GoogleFonts.lato(fontSize: 12, color: Colors.red[700]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfirmationPanel(bool canConfirm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Delivery Address',
            style: GoogleFonts.lato(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _selectedLocation == null && _searchController.text.trim().isNotEmpty
                ? _searchController.text.trim()
                : _address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.lato(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apartmentSuiteController,
            style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: 'Apartment, Suite, Plot, or Floor (Optional)',
              labelStyle: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600]),
              hintText: 'e.g. Apt 3B, Plot 14, or Blue gate near shop',
              hintStyle: GoogleFonts.lato(fontSize: 12, color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.apartment_outlined, size: 20),
              filled: true,
              fillColor: const Color(0xFFF8FAF8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: canConfirm ? _confirmLocation : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isConfirming
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Confirm Location'),
          ),
        ],
      ),
    );
  }
}