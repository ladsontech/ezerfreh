import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ezer_fresh/src/core/services/location_service.dart';
import 'package:google_fonts/google_fonts.dart';

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
  LatLng? _selectedLocation;
  String _address = "Select location on map";
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();
  final TextEditingController _apartmentSuiteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialApartmentSuite != null) {
      _apartmentSuiteController.text = widget.initialApartmentSuite!;
    }
    if (widget.initialLatLng != null) {
      _selectedLocation = widget.initialLatLng;
      _address = widget.initialAddress ?? "Selected Location";
    } else {
      _getCurrentUserLocation();
    }
  }

  @override
  void dispose() {
    _apartmentSuiteController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentUserLocation() async {
    try {
      Position position = await _locationService.getCurrentLocation() ?? 
        Position(
          longitude: 0, 
          latitude: 0, 
          timestamp: DateTime.now(), 
          accuracy: 0, 
          altitude: 0, 
          heading: 0, 
          speed: 0, 
          speedAccuracy: 0, 
          altitudeAccuracy: 0, 
          headingAccuracy: 0
        );
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
      );
      _updateAddress(_selectedLocation!);
    } catch (e) {
      debugPrint("Error getting location: $e");
      // Fallback to a default location (e.g., Kampala, Uganda) if permission fails
      setState(() {
        _selectedLocation = const LatLng(0.3476, 32.5825);
        _address = "Tap map to set delivery location";
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
      );
    }
  }

  Future<void> _updateAddress(LatLng location) async {
    String address = await _locationService.getAddressFromLatLng(location.latitude, location.longitude);
    setState(() {
      _address = address;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _selectedLocation ?? const LatLng(0.3476, 32.5825),
                  zoom: _selectedLocation != null ? 15 : 2,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (_selectedLocation != null) {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
                    );
                  }
                },
                onTap: (location) {
                  setState(() {
                    _selectedLocation = location;
                  });
                  _updateAddress(location);
                },
                markers: _selectedLocation != null
                    ? {
                        Marker(
                          markerId: const MarkerId("selected-location"),
                          position: _selectedLocation!,
                        ),
                      }
                    : {},
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Container(
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
                        "Delivery Address",
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _address,
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _selectedLocation != null
                            ? () => widget.onLocationSelected(
                                  _selectedLocation!,
                                  _address,
                                  _apartmentSuiteController.text,
                                )
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _selectedLocation == null 
                          ? const SizedBox(
                              height: 20, 
                              width: 20, 
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                            )
                          : const Text("Confirm Location"),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
