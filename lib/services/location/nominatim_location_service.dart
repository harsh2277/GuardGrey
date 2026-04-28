import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:guardgrey/modules/location/models/location_search_result.dart';

class NominatimLocationService {
  NominatimLocationService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static const Map<String, String> _headers = {
    'User-Agent': 'GuardPulseAdmin/1.0 (guardpulse-admin-app)',
    'Accept': 'application/json',
  };

  Future<List<LocationSearchResult>> searchLocations(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'json',
      'limit': '6',
      'addressdetails': '1',
    });

    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode == 429) {
      throw Exception('Location search is busy right now. Please try again.');
    }
    if (response.statusCode != 200) {
      throw Exception('Unable to search location right now.');
    }

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) {
          final map = item as Map<String, dynamic>;
          final latitude = double.tryParse(map['lat']?.toString() ?? '');
          final longitude = double.tryParse(map['lon']?.toString() ?? '');
          if (latitude == null || longitude == null) {
            return null;
          }
          return LocationSearchResult(
            displayName: map['display_name'] as String? ?? 'Unknown location',
            latitude: latitude,
            longitude: longitude,
          );
        })
        .whereType<LocationSearchResult>()
        .toList(growable: false);
  }

  Future<String> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'format': 'json',
      'zoom': '18',
      'addressdetails': '1',
    });

    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode == 429) {
      throw Exception('Address lookup is busy right now. Please try again.');
    }
    if (response.statusCode != 200) {
      throw Exception('Unable to fetch address for this location.');
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;
    return data['display_name'] as String? ?? 'Selected location';
  }

  void dispose() {
    _client.close();
  }
}
