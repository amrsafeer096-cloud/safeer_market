import '../entities/address.dart';

abstract interface class AddressesRepository {
  /// The user's saved addresses, newest first.
  Future<List<Address>> fetchAddresses(String userId);

  Future<Address> addAddress(String userId, AddressDraft draft);

  Future<void> deleteAddress(String addressId);

  /// Pins an existing address on the map.
  Future<void> updateLocation(
    String addressId, {
    required double latitude,
    required double longitude,
  });
}

class AddressFailure implements Exception {
  const AddressFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
