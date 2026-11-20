import 'package:latlong2/latlong.dart';

/// One match for what the user typed in the map's search bar.
class PlaceSuggestion {
  const PlaceSuggestion({
    required this.id,
    required this.title,
    this.subtitle,
    this.point,
  });

  /// The provider's id for the place (e.g. a Google place id).
  final String id;
  final String title;
  final String? subtitle;

  /// Known up front for some providers; otherwise [PlaceSearchService.locate].
  final LatLng? point;
}

/// «ابحث عن منطقة أو شارع...» on the address map.
abstract interface class PlaceSearchService {
  /// Places matching [query], nearest [near] first where supported.
  Future<List<PlaceSuggestion>> suggest(String query, {LatLng? near});

  /// Where [suggestion] is.
  Future<LatLng> locate(PlaceSuggestion suggestion);
}

class PlaceSearchFailure implements Exception {
  const PlaceSearchFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
