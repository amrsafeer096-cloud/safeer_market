import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted CVV + full PAN storage for saved cards. Never written to
/// SharedPreferences or Supabase — only the device keystore / Keychain.
class SavedCardSecrets {
  SavedCardSecrets([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static String _cvvKey(String userId, String cardId) =>
      'wallet.cvv.$userId.$cardId';

  static String _panKey(String userId, String cardId) =>
      'wallet.pan.$userId.$cardId';

  Future<void> writeCvv({
    required String userId,
    required String cardId,
    required String cvv,
  }) async {
    final trimmed = cvv.trim();
    if (trimmed.isEmpty) return;
    try {
      await _storage.write(key: _cvvKey(userId, cardId), value: trimmed);
    } catch (e, st) {
      debugPrint('Secure CVV write failed: $e\n$st');
    }
  }

  Future<String?> readCvv({
    required String userId,
    required String cardId,
  }) async {
    try {
      return await _storage.read(key: _cvvKey(userId, cardId));
    } catch (e, st) {
      debugPrint('Secure CVV read failed: $e\n$st');
      return null;
    }
  }

  Future<void> deleteCvv({
    required String userId,
    required String cardId,
  }) async {
    try {
      await _storage.delete(key: _cvvKey(userId, cardId));
    } catch (e, st) {
      debugPrint('Secure CVV delete failed: $e\n$st');
    }
  }

  /// Stores the full card number (digits only) for Paymob autofill.
  Future<void> writePan({
    required String userId,
    required String cardId,
    required String pan,
  }) async {
    final digits = pan.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 13) return;
    try {
      await _storage.write(key: _panKey(userId, cardId), value: digits);
    } catch (e, st) {
      debugPrint('Secure PAN write failed: $e\n$st');
    }
  }

  Future<String?> readPan({
    required String userId,
    required String cardId,
  }) async {
    try {
      final value = await _storage.read(key: _panKey(userId, cardId));
      final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
      return digits.length >= 13 ? digits : null;
    } catch (e, st) {
      debugPrint('Secure PAN read failed: $e\n$st');
      return null;
    }
  }

  Future<void> deletePan({
    required String userId,
    required String cardId,
  }) async {
    try {
      await _storage.delete(key: _panKey(userId, cardId));
    } catch (e, st) {
      debugPrint('Secure PAN delete failed: $e\n$st');
    }
  }

  /// Wipes every secure entry on this device (used on account deletion).
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e, st) {
      debugPrint('Secure storage deleteAll failed: $e\n$st');
    }
  }
}
