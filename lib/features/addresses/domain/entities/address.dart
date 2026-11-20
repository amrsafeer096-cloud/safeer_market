import '../../../../core/l10n/l10n.dart';

class AddressDraft {
  const AddressDraft({
    required this.title,
    required this.area,
    required this.street,
    required this.building,
    this.floorApt,
    this.landmark,
    this.latitude,
    this.longitude,
  });

  /// Built-in titles; stored in `addresses.title` as-is and translated only
  /// for display.
  static const homeTitle = 'المنزل';
  static const workTitle = 'العمل';
  static const otherTitle = 'أخرى';

  final String title;
  final String area;
  final String street;
  final String building;
  final String? floorApt;
  final String? landmark;

  /// Map pin; the delivery fee is priced from its distance to the store.
  final double? latitude;
  final double? longitude;

  bool get hasLocation => latitude != null && longitude != null;

  String displayTitle(AppLocalizations l10n) => localizedTitle(title, l10n);

  static String localizedTitle(String title, AppLocalizations l10n) =>
      switch (title) {
        homeTitle => l10n.addressLabelHome,
        workTitle => l10n.addressLabelWork,
        otherTitle => l10n.addressLabelOther,
        _ => title,
      };
}

class Address extends AddressDraft {
  const Address({
    required this.id,
    required super.title,
    required super.area,
    required super.street,
    required super.building,
    super.floorApt,
    super.landmark,
    super.latitude,
    super.longitude,
  });

  final String id;

  Address withLocation({required double latitude, required double longitude}) {
    return Address(
      id: id,
      title: title,
      area: area,
      street: street,
      building: building,
      floorApt: floorApt,
      landmark: landmark,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Street-level line for compact display, e.g. in the cart.
  String get streetLine => _streetLine(L10n.current);

  String _streetLine(AppLocalizations l10n) {
    return [
      street,
      if (building.isNotEmpty) l10n.addressBuildingLine(building),
      if (floorApt case final floor? when floor.isNotEmpty)
        l10n.addressFloorAptLine(floor),
    ].join(l10n.listSeparator);
  }

  /// The whole address as one line, as stored in `orders.address_details`.
  String get formatted {
    final l10n = L10n.store;
    return [
      '${displayTitle(l10n)}: ${_streetLine(l10n)}',
      if (area.isNotEmpty) area,
      if (landmark case final mark? when mark.isNotEmpty)
        l10n.addressLandmarkLine(mark),
    ].join(' - ');
  }
}
