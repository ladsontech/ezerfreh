import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class PlaceSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  const PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final formatting =
        json['structured_formatting'] as Map<String, dynamic>? ?? {};
    final description = json['description'] as String? ?? '';
    return PlaceSuggestion(
      placeId: json['place_id'] as String? ?? '',
      description: description,
      mainText: formatting['main_text'] as String? ?? description,
      secondaryText: formatting['secondary_text'] as String? ?? '',
    );
  }
}

class PlaceDetails {
  final double latitude;
  final double longitude;
  final String address;

  const PlaceDetails({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class LocationService {
  static const String _googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyDjY0hr4rZtwPas_LAxBbvIBNeL41a5AKQ',
  );

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    return Geolocator.getCurrentPosition();
  }

  Future<List<PlaceSuggestion>> searchPlaces(
    String input, {
    String? sessionToken,
  }) async {
    final query = input.trim();
    if (query.length < 2) return const [];

    final params = <String, String>{
      'input': query,
      'key': _googleMapsApiKey,
      'components': 'country:ug',
    };
    if (sessionToken != null && sessionToken.isNotEmpty) {
      params['sessiontoken'] = sessionToken;
    }

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      params,
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Could not search places. Please try again.');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final status = body['status'] as String? ?? 'UNKNOWN';
    if (status == 'ZERO_RESULTS') return const [];
    if (status != 'OK') {
      final error = body['error_message'] as String? ?? '';
      debugPrint('Places autocomplete failed: $status $error');
      throw Exception('Place search is not available right now.');
    }

    final predictions = body['predictions'] as List<dynamic>? ?? const [];
    return predictions
        .map(
          (prediction) =>
              PlaceSuggestion.fromJson(prediction as Map<String, dynamic>),
        )
        .where((suggestion) => suggestion.placeId.isNotEmpty)
        .toList();
  }

  Future<PlaceDetails?> getPlaceDetails(
    String placeId, {
    String? sessionToken,
  }) async {
    if (placeId.isEmpty) return null;

    final params = <String, String>{
      'place_id': placeId,
      'fields': 'formatted_address,geometry,name',
      'key': _googleMapsApiKey,
    };
    if (sessionToken != null && sessionToken.isNotEmpty) {
      params['sessiontoken'] = sessionToken;
    }

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      params,
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Could not load place details. Please try again.');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final status = body['status'] as String? ?? 'UNKNOWN';
    if (status != 'OK') {
      final error = body['error_message'] as String? ?? '';
      debugPrint('Place details failed: $status $error');
      return null;
    }

    final result = body['result'] as Map<String, dynamic>? ?? {};
    final geometry = result['geometry'] as Map<String, dynamic>? ?? {};
    final location = geometry['location'] as Map<String, dynamic>? ?? {};
    final latitude = (location['lat'] as num?)?.toDouble();
    final longitude = (location['lng'] as num?)?.toDouble();
    if (latitude == null || longitude == null) return null;

    return PlaceDetails(
      latitude: latitude,
      longitude: longitude,
      address: (result['formatted_address'] as String?) ??
          (result['name'] as String?) ??
          'Selected Location',
    );
  }

  Future<PlaceDetails?> getPlaceFromAddress(String address) async {
    final query = address.trim();
    if (query.isEmpty) return null;

    try {
      final locations = await locationFromAddress(query);
      if (locations.isEmpty) return null;
      final location = locations.first;
      return PlaceDetails(
        latitude: location.latitude,
        longitude: location.longitude,
        address: query,
      );
    } catch (e) {
      debugPrint('Address lookup failed: $e');
      return null;
    }
  }

  Future<String> getAddressFromLatLng(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        final parts = [
          place.street,
          place.subLocality,
          place.locality,
          place.country,
        ].whereType<String>().where((part) => part.trim().isNotEmpty);
        if (parts.isNotEmpty) return parts.join(', ');
      }
    } catch (e) {
      debugPrint('$e');
    }
    return 'Selected Location';
  }
}