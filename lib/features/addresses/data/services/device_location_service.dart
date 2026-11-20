import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../../core/l10n/l10n.dart';
import '../../domain/services/location_service.dart';

/// GPS via `geolocator`, addresses via the native geocoder with an
/// OpenStreetMap Nominatim fallback (the native one is missing on web and on
/// some Android builds).
class DeviceLocationService implements LocationService {
  DeviceLocationService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static Locale get _geocodingLocale => Locale(L10n.localeName, 'EG');
  static const _userAgent = 'SafeerMarket/1.0 (com.example.safeer_market)';

  @override
  Future<LatLng> currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw LocationFailure(
          LocationFailureReason.serviceDisabled,
          L10n.current.locationServiceDisabled,
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      switch (permission) {
        case LocationPermission.denied || LocationPermission.unableToDetermine:
          throw LocationFailure(
            LocationFailureReason.denied,
            L10n.current.locationPermissionDenied,
          );
        case LocationPermission.deniedForever:
          throw LocationFailure(
            LocationFailureReason.deniedForever,
            L10n.current.locationPermissionDeniedForever,
          );
        case LocationPermission.whileInUse || LocationPermission.always:
          break;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } on LocationFailure {
      rethrow;
    } on PermissionDeniedException {
      throw LocationFailure(
        LocationFailureReason.denied,
        L10n.current.locationPermissionDenied,
      );
    } catch (_) {
      throw LocationFailure(
        LocationFailureReason.unavailable,
        L10n.current.currentLocationUnavailable,
      );
    }
  }

  @override
  Future<PickedLocation> reverseGeocode(LatLng point) async {
    if (!kIsWeb) {
      try {
        final placemarks = await Geocoding().placemarkFromCoordinates(
          point.latitude,
          point.longitude,
          locale: _geocodingLocale,
        );
        if (placemarks.isNotEmpty) {
          final mark = placemarks.first;
          final location = PickedLocation(
            point: point,
            area: _firstFilled([
              mark.subLocality,
              mark.locality,
              mark.subAdministrativeArea,
              mark.administrativeArea,
            ]),
            street: _firstFilled([mark.thoroughfare, mark.street]),
          );
          if (location.hasAddress) return location;
        }
      } catch (_) {
        // Fall through to Nominatim.
      }
    }
    return _reverseWithNominatim(point);
  }

  Future<PickedLocation> _reverseWithNominatim(LatLng point) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': '${point.latitude}',
      'lon': '${point.longitude}',
      'zoom': '18',
      'accept-language': L10n.localeName,
    });
    try {
      final response = await _client
          .get(uri, headers: kIsWeb ? null : {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        final address = body is Map ? body['address'] : null;
        if (address is Map) {
          String? field(String key) => address[key] as String?;
          final location = PickedLocation(
            point: point,
            area: _firstFilled([
              field('suburb'),
              field('neighbourhood'),
              field('quarter'),
              field('city_district'),
              field('city'),
              field('town'),
              field('village'),
              field('state'),
            ]),
            street: _firstFilled([
              field('road'),
              field('pedestrian'),
              field('residential'),
            ]),
          );
          if (location.hasAddress) return location;
        }
      }
    } catch (_) {
      // Reported below.
    }
    throw LocationFailure(
      LocationFailureReason.unavailable,
      L10n.current.mapAddressReadFailed,
    );
  }

  @override
  Future<bool> openSettingsFor(LocationFailure failure) async {
    if (kIsWeb) return false;
    return switch (failure.reason) {
      LocationFailureReason.serviceDisabled =>
        Geolocator.openLocationSettings(),
      LocationFailureReason.deniedForever => Geolocator.openAppSettings(),
      _ => Future.value(false),
    };
  }

  static String? _firstFilled(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }
}
