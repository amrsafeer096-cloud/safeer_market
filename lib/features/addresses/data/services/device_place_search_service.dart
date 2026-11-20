import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/l10n/l10n.dart';
import '../../domain/services/place_search_service.dart';

/// The phone's own geocoder: no API key, but no type-ahead ranking either —
/// it resolves what was typed (within Egypt) to a few points and names them.
class DevicePlaceSearchService implements PlaceSearchService {
  const DevicePlaceSearchService();

  static const maxResults = 5;

  static Locale get _locale => Locale(L10n.localeName, 'EG');

  @override
  Future<List<PlaceSuggestion>> suggest(String query, {LatLng? near}) async {
    final input = query.trim();
    if (input.length < 3) return const [];
    final geocoding = Geocoding(locale: _locale);
    final List<Location> locations;
    try {
      locations = await geocoding.locationFromAddress('$input, مصر');
    } on PlatformException catch (error) {
      // What the geocoder answers when nothing matches.
      if (error.code == 'NOT_FOUND') return const [];
      throw PlaceSearchFailure(error.message ?? error.code);
    } catch (error) {
      throw PlaceSearchFailure('$error');
    }

    final suggestions = <PlaceSuggestion>[];
    for (final location in locations.take(maxResults)) {
      final point = LatLng(location.latitude, location.longitude);
      String? subtitle;
      try {
        final marks = await geocoding.placemarkFromCoordinates(
          point.latitude,
          point.longitude,
        );
        if (marks.isNotEmpty) {
          final mark = marks.first;
          subtitle = [
            mark.street,
            mark.subLocality,
            mark.locality,
            mark.administrativeArea,
          ]
              .whereType<String>()
              .map((part) => part.trim())
              .where((part) => part.isNotEmpty)
              .toSet()
              .join('، ');
        }
      } catch (_) {
        // The coordinates alone still let the map jump there.
      }
      suggestions.add(PlaceSuggestion(
        id: '${point.latitude},${point.longitude}',
        title: input,
        subtitle: subtitle == null || subtitle.isEmpty ? null : subtitle,
        point: point,
      ));
    }
    return suggestions;
  }

  @override
  Future<LatLng> locate(PlaceSuggestion suggestion) async =>
      suggestion.point ??
      (throw PlaceSearchFailure('No location for ${suggestion.title}'));
}
