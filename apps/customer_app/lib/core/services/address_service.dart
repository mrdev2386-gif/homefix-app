import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../models/address.dart';

/// Production-grade Address Service
/// Handles all address-related Firestore operations securely
class AddressService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Stream user's saved addresses
  Stream<List<Address>> streamAddresses(String userId) {
    if (userId.isEmpty) {
      debugPrint('[PATH GUARD] blocked empty id in streamAddresses');
      return Stream.value([]);
    }
    return _db
        .collection('customers')
        .doc(userId)
        .collection('addresses')
        .snapshots()
        .map((snapshot) {
      final addresses =
          snapshot.docs.map((doc) => Address.fromFirestore(doc)).toList();
      // Sort by default first, then by creation date
      addresses.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
      return addresses;
    });
  }

  /// Get a single address by ID
  Future<Address?> getAddress(String userId, String addressId) async {
    if (userId.isEmpty || addressId.isEmpty) {
      debugPrint('[PATH GUARD] blocked empty id in getAddress');
      return null;
    }
    final doc = await _db
        .collection('customers')
        .doc(userId)
        .collection('addresses')
        .doc(addressId)
        .get();

    if (!doc.exists) return null;
    return Address.fromFirestore(doc);
  }

  /// Save address (add or update) via Cloud Function
  Future<String> saveAddress(String userId, Address address) async {
    if (userId.isEmpty) {
      debugPrint('[PATH GUARD] blocked empty id in saveAddress');
      return '';
    }
    debugPrint('[WRITE GUARD] Direct write blocked in saveAddress');
    final callable = _functions.httpsCallable('manageAddress');
    final result = await callable.call({
      'action': address.id.isEmpty ? 'add' : 'edit',
      'addressId': address.id.isEmpty ? null : address.id,
      'addressData': address.toMap(),
    });

    return result.data['addressId'] as String? ?? '';
  }

  /// Delete address via Cloud Function
  Future<void> deleteAddress(String userId, String addressId) async {
    if (userId.isEmpty || addressId.isEmpty) {
      debugPrint('[PATH GUARD] blocked empty id in deleteAddress');
      return;
    }
    debugPrint('[WRITE GUARD] Direct write blocked in deleteAddress');
    final callable = _functions.httpsCallable('manageAddress');
    await callable.call({
      'action': 'delete',
      'addressId': addressId,
    });
  }

  /// Set default address via Cloud Function
  Future<void> setDefaultAddress(String userId, String addressId) async {
    if (userId.isEmpty || addressId.isEmpty) {
      debugPrint('[PATH GUARD] blocked empty id in setDefaultAddress');
      return;
    }
    debugPrint('[WRITE GUARD] Direct write blocked in setDefaultAddress');
    final callable = _functions.httpsCallable('manageAddress');
    await callable.call({
      'action': 'setDefault',
      'addressId': addressId,
    });
  }

  /// Save current location as an address
  Future<String> saveCurrentLocationAddress({
    required String userId,
    required double latitude,
    required double longitude,
    required String fullAddress,
    required String city,
    required String district,
    required String state,
    String? landmark,
    String? pincode,
  }) async {
    final address = Address(
      id: '',
      label: 'Current Location',
      name: '', // Will be filled by user later if needed
      phone: '', // Will be filled by user later if needed
      fullAddress: fullAddress,
      landmark: landmark ?? '',
      city: city,
      district: district,
      state: state,
      pincode: pincode ?? '',
      latitude: latitude,
      longitude: longitude,
      isDefault: false,
      createdAt: DateTime.now(),
    );

    return await saveAddress(userId, address);
  }

  /// Update selected address in user profile via Cloud Function
  Future<void> updateSelectedAddress(String userId, String addressId) async {
    if (userId.isEmpty || addressId.isEmpty) {
      debugPrint('[PATH GUARD] blocked empty id in updateSelectedAddress');
      return;
    }
    debugPrint('[WRITE GUARD] Direct write blocked in updateSelectedAddress');
    try {
      final callable = _functions.httpsCallable('updateUserProfile');
      await callable.call({
        'selectedAddressId': addressId,
      });
      debugPrint('✅ [Address] Selected address updated via callable');
    } catch (e) {
      debugPrint('❌ [Address] Update failed: $e');
      rethrow;
    }
  }

  /// Get selected address ID from user profile
  Future<String?> getSelectedAddressId(String userId) async {
    if (userId.isEmpty) {
      debugPrint('[PATH GUARD] blocked empty id in getSelectedAddressId');
      return null;
    }
    try {
      final doc = await _db.collection('customers').doc(userId).get();
      return doc.data()?['selectedAddressId'] as String?;
    } catch (e) {
      debugPrint('❌ [Address] getSelectedAddressId failed: $e');
      return null;
    }
  }

  /// Get the selected address object
  Future<Address?> getSelectedAddress(String userId) async {
    final selectedId = await getSelectedAddressId(userId);
    if (selectedId == null) return null;
    return await getAddress(userId, selectedId);
  }
}
