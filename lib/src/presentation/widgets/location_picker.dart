import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ezer_fresh/src/core/services/location_service.dart';
import 'package:google_fonts/google_fonts.dart';

class LocationPicker extends StatefulWidget {
  final Function(LatLng, String) onLocationSelected;

  const LocationPicker({super.key, required this.onLocationSelected});

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  LatLng? _selectedLocation;
  String _address = "Select location on map";
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _getCurrentUserLocation();
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
                initialCameraPosition: const CameraPosition(
                  target: LatLng(0, 0),
                  zoom: 2,
                ),
                onMapCreated: (controller) => _mapController = controller,
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
                        color: Colors.black.withOpacity(0.1),
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
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _selectedLocation != null
                            ? () => widget.onLocationSelected(_selectedLocation!, _address)
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
