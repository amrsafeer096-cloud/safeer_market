import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../domain/services/place_search_service.dart';

/// Google Places API (New): Autocomplete for suggestions, Place Details for
/// the chosen one's coordinates. Calls made while one search bar is open
/// share a session token, so Google bills them as one session.
class GooglePlacesSearchService implements PlaceSearchService {
  GooglePlacesSearchService({
    required this.apiKey,
    required this.languageCode,
    http.Client? client,
    Random? random,
  })  : _client = client ?? http.Client(),
        _random = random ?? Random.secure();

  static const _host = 'places.googleapis.com';

  /// Suggestions are biased to this radius around the map.
  static const biasRadiusMeters = 20000.0;

  final String apiKey;
  final String languageCode;
  final http.Client _client;
  final Random _random;
  String? _session;

  String get _sessionToken => _session ??= [
        for (var i = 0; i < 16; i++)
          _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ].join();

  @override
  Future<List<PlaceSuggestion>> suggest(String query, {LatLng? near}) async {
    final input = query.trim();
    if (input.isEmpty) return const [];
    final response = await _send(http.Request(
      'POST',
      Uri.https(_host, '/v1/places:autocomplete'),
    )
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'input': input,
        'languageCode': languageCode,
        'includedRegionCodes': ['eg'],
        'sessionToken': _sessionToken,
        if (near != null)
          'locationBias': {
            'circle': {
              'center': {
                'latitude': near.latitude,
                'longitude': near.longitude,
              },
              'radius': biasRadiusMeters,
            },
          },
      }));

    final suggestions = response['suggestions'];
    return [
      if (suggestions is List)
        for (final item in suggestions)
          if (item is Map && item['placePrediction'] is Map)
            _toSuggestion(item['placePrediction'] as Map),
    ].whereType<PlaceSuggestion>().toList();
  }

  @override
  Future<LatLng> locate(PlaceSuggestion suggestion) async {
    if (suggestion.point case final point?) return point;
    final response = await _send(
      http.Request(
        'GET',
        Uri.https(_host, '/v1/places/${suggestion.id}', {
          'languageCode': languageCode,
          'sessionToken': _sessionToken,
        }),
      )..headers['X-Goog-FieldMask'] = 'location',
    );
    // Details close the billing session; the next search starts a new one.
    _session = null;
    final location = response['location'];
    final latitude = location is Map ? location['latitude'] : null;
    final longitude = location is Map ? location['longitude'] : null;
    if (latitude is! num || longitude is! num) {
      throw PlaceSearchFailure('No location for ${suggestion.title}');
    }
    return LatLng(latitude.toDouble(), longitude.toDouble());
  }

  Future<Map<String, dynamic>> _send(http.Request request) async {
    request.headers['X-Goog-Api-Key'] = apiKey;
    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 10)),
      );
    } catch (error) {
      throw PlaceSearchFailure('$error');
    }
    final body = utf8.decode(response.bodyBytes);
    if (response.statusCode != 200) {
      debugPrint('Places ${request.url.path} → ${response.statusCode}: $body');
      throw PlaceSearchFailure(
          _errorMessage(body) ?? 'HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : const {};
  }

  static String? _errorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      final error = decoded is Map ? decoded['error'] : null;
      return error is Map ? error['message']?.toString() : null;
    } on FormatException {
      return null;
    }
  }

  static PlaceSuggestion? _toSuggestion(Map prediction) {
    final id = prediction['placeId'];
    if (id is! String || id.isEmpty) return null;
    String? text(Object? node) {
      final value = node is Map ? node['text'] : null;
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    final format = prediction['structuredFormat'];
    final main = format is Map ? text(format['mainText']) : null;
    final secondary = format is Map ? text(format['secondaryText']) : null;
    final full = text(prediction['text']);
    final title = main ?? full;
    if (title == null) return null;
    return PlaceSuggestion(id: id, title: title, subtitle: secondary);
  }
}
