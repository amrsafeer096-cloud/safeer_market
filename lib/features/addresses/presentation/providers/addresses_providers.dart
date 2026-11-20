import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/supabase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/supabase_addresses_repository.dart';
import '../../data/services/device_location_service.dart';
import '../../data/services/device_place_search_service.dart';
import '../../data/services/google_places_search_service.dart';
import '../../domain/entities/address.dart';
import '../../domain/repositories/addresses_repository.dart';
import '../../domain/services/location_service.dart';
import '../../domain/services/place_search_service.dart';

final addressesRepositoryProvider = Provider<AddressesRepository>((ref) {
  return SupabaseAddressesRepository(ref.watch(supabaseClientProvider));
});

final locationServiceProvider = Provider<LocationService>(
  (ref) => DeviceLocationService(),
);

/// The map's search bar: Google Places when a key is configured, otherwise
/// the device's geocoder.
final placeSearchServiceProvider = Provider<PlaceSearchService>((ref) {
  const key = AppConfig.googlePlacesApiKey;
  if (key.isEmpty) return const DevicePlaceSearchService();
  return GooglePlacesSearchService(
    apiKey: key,
    languageCode: L10n.localeName,
  );
});

/// The signed-in user's saved addresses; empty for guests.
final addressesProvider = FutureProvider<List<Address>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Future.value(const []);
  return ref.watch(addressesRepositoryProvider).fetchAddresses(user.id);
});

final selectedAddressIdProvider = StateProvider<String?>((ref) {
  ref.watch(currentUserProvider);
  return null;
});

/// The address chosen for checkout, if it still exists.
final selectedAddressProvider = Provider<Address?>((ref) {
  final id = ref.watch(selectedAddressIdProvider);
  final addresses = ref.watch(addressesProvider).valueOrNull ?? const [];
  return addresses.where((address) => address.id == id).firstOrNull;
});

final addressesControllerProvider = Provider(AddressesController.new);

class AddressesController {
  const AddressesController(this._ref);

  final Ref _ref;

  Future<Address> add(AddressDraft draft) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      throw AddressFailure(
          _ref.read(appLocalizationsProvider).pleaseSignInFirst);
    }

    final address =
        await _ref.read(addressesRepositoryProvider).addAddress(user.id, draft);
    _ref.invalidate(addressesProvider);
    return address;
  }

  Future<void> setLocation(
    Address address, {
    required double latitude,
    required double longitude,
  }) async {
    await _ref.read(addressesRepositoryProvider).updateLocation(
          address.id,
          latitude: latitude,
          longitude: longitude,
        );
    _ref.invalidate(addressesProvider);
  }

  Future<void> delete(Address address) async {
    await _ref.read(addressesRepositoryProvider).deleteAddress(address.id);
    if (_ref.read(selectedAddressIdProvider) == address.id) {
      _ref.read(selectedAddressIdProvider.notifier).state = null;
    }
    _ref.invalidate(addressesProvider);
  }
}
