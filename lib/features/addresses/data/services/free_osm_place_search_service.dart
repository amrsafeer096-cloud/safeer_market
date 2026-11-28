import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../domain/services/place_search_service.dart';

/// Free, no-API-key place search for Egypt: Photon (primary) with Nominatim
/// fallback, plus direct Google Maps URL / raw coordinate parsing.
class FreeOsmPlaceSearchService implements PlaceSearchService {
  FreeOsmPlaceSearchService({http.Client? client})
      : _client = client ?? http.Client();

  static const userAgent = 'SafeerMarketApp/1.0';
  static const maxResults = 8;

  /// Safeer Market — Nasr City (search bias).
  static const biasLat = 30.0561;
  static const biasLon = 31.3301;

  /// Egypt bbox for Photon: minLon,minLat,maxLon,maxLat.
  static const egyptBbox = '24.7,22.0,36.9,31.7';

  final http.Client _client;

  static final _coordPair = RegExp(
    r'^\s*(-?\d{1,2}(?:\.\d+)?)\s*[,،]\s*(-?\d{1,3}(?:\.\d+)?)\s*$',
  );

  /// `@lat,lng` or `@lat,lng,zoom` in Google Maps URLs.
  static final _atCoords = RegExp(
    r'@(-?\d{1,2}(?:\.\d+)?),(-?\d{1,3}(?:\.\d+)?)(?:,|$)',
  );

  /// `?q=lat,lng` / `&q=lat,lng` / `ll=` / `query=`.
  static final _queryCoords = RegExp(
    r'[?&](?:q|query|ll)=(-?\d{1,2}(?:\.\d+)?)[,+\s]+(-?\d{1,3}(?:\.\d+)?)',
    caseSensitive: false,
  );

  @override
  Future<List<PlaceSuggestion>> suggest(String query, {LatLng? near}) async {
    final input = query.trim();
    if (input.isEmpty) return const [];

    final direct = _parseDirectPoint(input);
    if (direct != null) {
      return [
        PlaceSuggestion(
          id: '${direct.latitude},${direct.longitude}',
          title: '${direct.latitude.toStringAsFixed(5)}, '
              '${direct.longitude.toStringAsFixed(5)}',
          subtitle: 'إحداثيات',
          point: direct,
        ),
      ];
    }

    if (input.length < 2) return const [];

    try {
      final photon = await _searchPhoton(input, near: near);
      if (photon.isNotEmpty) return photon;
    } catch (error) {
      debugPrint('Photon search failed: $error');
    }

    try {
      return await _searchNominatim(input);
    } catch (error) {
      throw PlaceSearchFailure('$error');
    }
  }

  @override
  Future<LatLng> locate(PlaceSuggestion suggestion) async {
    final point = suggestion.point;
    if (point != null) return point;
    throw PlaceSearchFailure('No location for ${suggestion.title}');
  }

  Future<List<PlaceSuggestion>> _searchPhoton(
    String query, {
    LatLng? near,
  }) async {
    final lat = near?.latitude ?? biasLat;
    final lon = near?.longitude ?? biasLon;
    final uri = Uri.https('photon.komoot.io', '/api/', {
      'q': query,
      'limit': '$maxResults',
      'lat': '$lat',
      'lon': '$lon',
      'bbox': egyptBbox,
      'lang': 'en',
    });
    final response = await _client
        .get(
          uri,
          headers: {
            'User-Agent': userAgent,
            'Accept': 'application/json',
            'Accept-Language': 'ar,en',
          },
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw PlaceSearchFailure('Photon HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map) return const [];
    final features = decoded['features'];
    if (features is! List) return const [];

    final out = <PlaceSuggestion>[];
    for (var i = 0; i < features.length && out.length < maxResults; i++) {
      final feature = features[i];
      if (feature is! Map) continue;
      final suggestion = _fromPhotonFeature(feature, index: i);
      if (suggestion != null) out.add(suggestion);
    }
    return out;
  }

  Future<List<PlaceSuggestion>> _searchNominatim(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'format': 'jsonv2',
      'countrycodes': 'eg',
      'addressdetails': '1',
      'limit': '$maxResults',
      'q': query,
    });
    final response = await _client
        .get(
          uri,
          headers: {
            'User-Agent': userAgent,
            'Accept': 'application/json',
            'Accept-Language': 'ar,en',
          },
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw PlaceSearchFailure('Nominatim HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) return const [];

    final out = <PlaceSuggestion>[];
    for (var i = 0; i < decoded.length && out.length < maxResults; i++) {
      final item = decoded[i];
      if (item is! Map) continue;
      final suggestion = _fromNominatim(item, index: i);
      if (suggestion != null) out.add(suggestion);
    }
    return out;
  }

  static PlaceSuggestion? _fromPhotonFeature(
    Map<dynamic, dynamic> feature, {
    required int index,
  }) {
    final geometry = feature['geometry'];
    if (geometry is! Map) return null;
    final coords = geometry['coordinates'];
    if (coords is! List || coords.length < 2) return null;
    final lon = _asDouble(coords[0]);
    final lat = _asDouble(coords[1]);
    if (lat == null || lon == null) return null;
    if (!_inEgypt(lat, lon)) return null;

    final props = feature['properties'];
    if (props is! Map) return null;

    String? text(Object? key) {
      final v = props[key];
      if (v is! String) return null;
      final t = v.trim();
      return t.isEmpty ? null : t;
    }

    final name = text('name');
    final street = text('street');
    final house = text('housenumber');
    final district = text('district');
    final city = text('city');
    final state = text('state');
    final locality = text('locality');

    final title = name ?? street ?? city ?? district ?? locality;
    if (title == null) return null;

    final subtitleParts = <String>[
      if (house != null && street != null) '$house $street',
      if (house == null && street != null && street != title) street,
      if (district != null) district,
      if (city != null && city != title) city,
      if (state != null) state,
    ];
    final subtitle = subtitleParts.isEmpty ? null : subtitleParts.join('، ');

    return PlaceSuggestion(
      id: 'photon-$index-$lat,$lon',
      title: title,
      subtitle: subtitle,
      point: LatLng(lat, lon),
    );
  }

  static PlaceSuggestion? _fromNominatim(
    Map<dynamic, dynamic> item, {
    required int index,
  }) {
    final lat = _asDouble(item['lat']);
    final lon = _asDouble(item['lon']);
    if (lat == null || lon == null) return null;
    if (!_inEgypt(lat, lon)) return null;

    final address = item['address'];
    String? field(String key) {
      if (address is! Map) return null;
      final v = address[key];
      if (v is! String) return null;
      final t = v.trim();
      return t.isEmpty ? null : t;
    }

    final display = item['display_name'];
    final displayName = display is String ? display.trim() : '';
    final road = field('road');
    final suburb = field('suburb');
    final neighbourhood = field('neighbourhood');
    final cityDistrict = field('city_district');
    final city = field('city');
    final town = field('town');
    final state = field('state');

    final title = field('name') ??
        field('amenity') ??
        field('shop') ??
        field('building') ??
        road ??
        (displayName.isNotEmpty ? displayName.split(',').first.trim() : null);
    if (title == null || title.isEmpty) return null;

    final subtitleParts = <String>[
      if (road != null && road != title) road,
      if (suburb != null) suburb,
      if (neighbourhood != null) neighbourhood,
      if (cityDistrict != null) cityDistrict,
      if (city != null) city,
      if (town != null) town,
      if (state != null) state,
    ];
    final subtitle = subtitleParts.isEmpty
        ? (displayName.isEmpty ? null : displayName)
        : subtitleParts.toSet().join('، ');

    return PlaceSuggestion(
      id: 'nominatim-$index-$lat,$lon',
      title: title,
      subtitle: subtitle,
      point: LatLng(lat, lon),
    );
  }

  /// Raw `lat,lng`, Google Maps `@lat,lng`, or `?q=lat,lng` links.
  static LatLng? _parseDirectPoint(String raw) {
    final pair = _coordPair.firstMatch(raw);
    if (pair != null) {
      return _validPoint(pair.group(1), pair.group(2));
    }

    final lower = raw.toLowerCase();
    final looksMaps = lower.contains('maps.google') ||
        lower.contains('google.com/maps') ||
        lower.contains('maps.app.goo.gl') ||
        lower.contains('goo.gl/maps');
    if (!looksMaps && !raw.contains('@')) return null;

    final at = _atCoords.firstMatch(raw);
    if (at != null) {
      return _validPoint(at.group(1), at.group(2));
    }
    final q = _queryCoords.firstMatch(raw);
    if (q != null) {
      return _validPoint(q.group(1), q.group(2));
    }
    return null;
  }

  static LatLng? _validPoint(String? a, String? b) {
    final lat = double.tryParse(a ?? '');
    final lon = double.tryParse(b ?? '');
    if (lat == null || lon == null) return null;
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return null;
    // Prefer Egypt-ish ordering; if swapped (lng,lat) for EG, swap back.
    if (_inEgypt(lat, lon)) return LatLng(lat, lon);
    if (_inEgypt(lon, lat)) return LatLng(lon, lat);
    return LatLng(lat, lon);
  }

  static bool _inEgypt(double lat, double lon) =>
      lon >= 24.7 && lon <= 36.9 && lat >= 22.0 && lat <= 31.7;

  static double? _asDouble(Object? value) => switch (value) {
        final num n => n.toDouble(),
        final String s => double.tryParse(s.trim()),
        _ => null,
      };
}
