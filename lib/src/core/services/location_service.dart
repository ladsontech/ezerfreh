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

  // Parses one entry from the Places API (New) autocomplete response:
  // { "suggestions": [ { "placePrediction": { "placeId", "text": {"text"},
  //   "structuredFormat": {"mainText": {"text"}, "secondaryText": {"text"}} } } ] }
  factory PlaceSuggestion.fromPrediction(Map<String, dynamic> json) {
    final prediction =
        json['placePrediction'] as Map<String, dynamic>? ?? {};
    final text = prediction['text'] as Map<String, dynamic>? ?? {};
    final structured =
        prediction['structuredFormat'] as Map<String, dynamic>? ?? {};
    final mainText = structured['mainText'] as Map<String, dynamic>? ?? {};
    final secondaryText =
        structured['secondaryText'] as Map<String, dynamic>? ?? {};
    final description = text['text'] as String? ?? '';
    return PlaceSuggestion(
      placeId: prediction['placeId'] as String? ?? '',
      description: description,
      mainText: mainText['text'] as String? ?? description,
      secondaryText: secondaryText['text'] as String? ?? '',
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
    defaultValue: 'AIzaSyDc_fnt5-ONpX32mhCHK0nIGE0aNCADVVI',
  );

  /// Cleans up an address before it's shown or saved.
  ///
  /// Reverse-geocoding and the Places API both return strings with empty
  /// segments whenever a field is missing for that spot — things like
  /// "Ntinda, , Kampala, , Uganda" — which render in the UI as stray
  /// commas floating with nothing between them. This drops the blank
  /// segments, collapses runs of whitespace, and removes back-to-back
  /// duplicates ("Kampala, Kampala" from areas where the sub-locality and
  /// locality are reported the same).
  static String tidyAddress(String raw) {
    final segments = raw
        .split(',')
        .map((segment) => segment.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((segment) => segment.isNotEmpty && segment != '-')
        .toList();

    final deduped = <String>[];
    for (final segment in segments) {
      if (deduped.isEmpty ||
          deduped.last.toLowerCase() != segment.toLowerCase()) {
        deduped.add(segment);
      }
    }

    return deduped.join(', ');
  }

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

  // Uses Places API (New) — the legacy Places Autocomplete/Details JSON
  // endpoints under maps.googleapis.com/maps/api/place/* return
  // REQUEST_DENIED for any project where only "Places API (New)" is
  // enabled, which is what was silently breaking every search here.
  // Make sure "Places API (New)" is enabled for this API key's project in
  // Google Cloud Console (APIs & Services > Library).
  Future<List<PlaceSuggestion>> searchPlaces(
    String input, {
    String? sessionToken,
    double? latitude,
    double? longitude,
    int radiusMeters = 50000,
  }) async {
    final query = input.trim();
    if (query.length < 2) return const [];

    final requestBody = <String, dynamic>{
      'input': query,
      'includedRegionCodes': ['ug'],
    };
    if (sessionToken != null && sessionToken.isNotEmpty) {
      requestBody['sessionToken'] = sessionToken;
    }
    if (latitude != null && longitude != null) {
      requestBody['locationBias'] = {
        'circle': {
          'center': {'latitude': latitude, 'longitude': longitude},
          'radius': radiusMeters.toDouble(),
        },
      };
    }

    final uri = Uri.https('places.googleapis.com', '/v1/places:autocomplete');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _googleMapsApiKey,
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      debugPrint(
        'Places autocomplete failed: ${response.statusCode} ${response.body}',
      );
      throw Exception('Could not search places. Please try again.');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final suggestions = body['suggestions'] as List<dynamic>? ?? const [];
    return suggestions
        .map(
          (suggestion) => PlaceSuggestion.fromPrediction(
            suggestion as Map<String, dynamic>,
          ),
        )
        .where((suggestion) => suggestion.placeId.isNotEmpty)
        .toList();
  }

  Future<PlaceDetails?> getPlaceDetails(
    String placeId, {
    String? sessionToken,
  }) async {
    if (placeId.isEmpty) return null;

    final params = <String, String>{};
    if (sessionToken != null && sessionToken.isNotEmpty) {
      params['sessionToken'] = sessionToken;
    }

    final uri = Uri.https(
      'places.googleapis.com',
      '/v1/places/$placeId',
      params.isEmpty ? null : params,
    );
    final response = await http.get(
      uri,
      headers: {
        'X-Goog-Api-Key': _googleMapsApiKey,
        'X-Goog-FieldMask': 'id,formattedAddress,location,displayName',
      },
    );

    if (response.statusCode != 200) {
      debugPrint(
        'Place details failed: ${response.statusCode} ${response.body}',
      );
      return null;
    }

    final result = jsonDecode(response.body) as Map<String, dynamic>;
    final location = result['location'] as Map<String, dynamic>? ?? {};
    final latitude = (location['latitude'] as num?)?.toDouble();
    final longitude = (location['longitude'] as num?)?.toDouble();
    if (latitude == null || longitude == null) return null;

    final displayName = result['displayName'] as Map<String, dynamic>?;
    final rawAddress =
        (result['formattedAddress'] as String?) ??
        (displayName?['text'] as String?) ??
        'Selected Location';
    final address = tidyAddress(rawAddress);
    return PlaceDetails(
      latitude: latitude,
      longitude: longitude,
      address: address.isEmpty ? 'Selected Location' : address,
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
        if (parts.isNotEmpty) {
          final address = tidyAddress(parts.join(', '));
          if (address.isNotEmpty) return address;
        }
      }
    } catch (e) {
      debugPrint('$e');
    }
    return 'Selected Location';
  }
}
