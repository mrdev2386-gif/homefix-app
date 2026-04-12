import 'package:flutter/foundation.dart';
import '../models/address.dart';
import 'category_service.dart';
import 'firestore_service.dart';

/// Production-grade Address Service
/// Delegates to FirestoreService for consistency
class AddressService {
  final FirestoreService _firestoreService;
  final CategoryService categoryService;

  AddressService(this.categoryService, {FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  /// Stream user's saved addresses
  Stream<List<Address>> streamAddresses(String userId) {
    return _firestoreService.streamAddresses(userId);
  }

  /// Get a single address by ID
  Future<Address?> getAddress(String userId, String addressId) async {
    if (userId.isEmpty || addressId.isEmpty) {
      debugPrint('[PATH GUARD] blocked empty id in getAddress');
      return null;
    }
    // Delegate to FirestoreService
    final addresses = await _firestoreService.streamAddresses(userId).first;
    return addresses.where((a) => a.id == addressId).firstOrNull;
  }

  /// Save address (add or update) via Cloud Function
  Future<String> saveAddress(String userId, Address address) async {
    if (userId.isEmpty) {
      debugPrint('[PATH GUARD] blocked empty id in saveAddress');
      return '';
    }
    
    final existingAddresses = await _firestoreService.streamAddresses(userId).first;
    final isFirstAddress = existingAddresses.isEmpty;
    
    // Delegate to FirestoreService
    await _firestoreService.saveAddress(userId, address);
    
    if (isFirstAddress && address.id.isNotEmpty) {
      await setPrimaryAddress(userId, address.id);
    }

    categoryService.clearLocationCache();

    return address.id;
  }

  /// Delete address via Cloud Function
  Future<void> deleteAddress(String userId, String addressId) async {
    if (userId.isEmpty || addressId.isEmpty) {
      debugPrint('[PATH GUARD] blocked empty id in deleteAddress');
      return;
    }
    
    final addresses = await _firestoreService.streamAddresses(userId).first;
    final addressToDelete = addresses.where((a) => a.id == addressId).firstOrNull;
    final wasPrimary = addressToDelete?.isDefault ?? false;
    
    // Delegate to FirestoreService
    await _firestoreService.deleteAddress(userId, addressId);
    
    if (wasPrimary) {
      final remainingAddresses = await _firestoreService.streamAddresses(userId).first;
      if (remainingAddresses.isNotEmpty) {
        await setPrimaryAddress(userId, remainingAddresses.first.id);
      }
    }
    
    categoryService.clearLocationCache();
  }

  /// Set primary address with Firestore batch update
  Future<void> setPrimaryAddress(String userId, String addressId) async {
    if (userId.isEmpty || addressId.isEmpty) {
      debugPrint('[PATH GUARD] blocked empty id in setPrimaryAddress');
      return;
    }

    // Delegate to FirestoreService
    await _firestoreService.setDefaultAddress(userId, addressId);
    
    categoryService.clearLocationCache();
  }

  /// Stream primary address
  Stream<Address?> streamPrimaryAddress(String userId) {
    return _firestoreService.streamPrimaryAddress(userId);
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
    
    // Delegate to FirestoreService
    await _firestoreService.updateUserProfile(userId, {'selectedAddressId': addressId});
    
    categoryService.clearLocationCache();
  }

  /// Get selected address ID from user profile
  Future<String?> getSelectedAddressId(String userId) async {
    if (userId.isEmpty) {
      debugPrint('[PATH GUARD] blocked empty id in getSelectedAddressId');
      return null;
    }
    try {
      final userData = await _firestoreService.getUserProfile(userId);
      return userData?['selectedAddressId'] as String?;
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
