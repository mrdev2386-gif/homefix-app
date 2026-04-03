import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/address.dart';
import '../firebase/functions_instance.dart';
import 'address_cache_service.dart';
import 'category_service.dart';

/// Production-grade Address Service
/// Handles all address-related Firestore operations securely
class AddressService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CategoryService categoryService;

  AddressService(this.categoryService);

  /// Stream user's saved addresses
  Stream<List<Address>> streamAddresses(String userId) {
    if (userId.isEmpty) {
      debugPrint('[PATH GUARD] blocked empty id in streamAddresses');
      return Stream.value([]);
    }
    return _db
        .collection('users')
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
        .collection('users')
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
    
    final existingAddresses = await _db
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .get();
    
    final isFirstAddress = existingAddresses.docs.isEmpty;
    
    debugPrint('[WRITE GUARD] Direct write blocked in saveAddress');
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    await user.getIdToken(true);
    
    
    final callable = FunctionsService.instance.httpsCallable('manageAddress');
    final result = await callable.call({
      'action': address.id.isEmpty ? 'add' : 'edit',
      'addressId': address.id.isEmpty ? null : address.id,
      'addressData': address.toMap(),
      'setAsPrimary': isFirstAddress,
    });

    final addressId = result.data['addressId'] as String? ?? '';
    
    if (isFirstAddress && addressId.isNotEmpty) {
      await setPrimaryAddress(userId, addressId);
    }

    categoryService.clearLocationCache();

    return addressId;
  }

  /// Delete address via Cloud Function
  Future<void> deleteAddress(String userId, String addressId) async {
    if (userId.isEmpty || addressId.isEmpty) {
      debugPrint('[PATH GUARD] blocked empty id in deleteAddress');
      return;
    }
    
    final addressDoc = await _db
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc(addressId)
        .get();
    
    final wasPrimary = addressDoc.data()?['isPrimary'] == true;
    
    debugPrint('[WRITE GUARD] Direct write blocked in deleteAddress');
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    await user.getIdToken(true);
    
    
    final callable = FunctionsService.instance.httpsCallable('manageAddress');
    await callable.call({
      'action': 'delete',
      'addressId': addressId,
    });
    
    if (wasPrimary) {
      final remainingAddresses = await _db
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .limit(1)
          .get();
      
      if (remainingAddresses.docs.isNotEmpty) {
        await setPrimaryAddress(userId, remainingAddresses.docs.first.id);
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

    try {
      final batch = _db.batch();
      
      // Get all addresses
      final addressesSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .get();

      // Set all addresses to non-primary
      for (final doc in addressesSnapshot.docs) {
        batch.update(doc.reference, {'isDefault': false, 'isPrimary': false});
      }

      // Set selected address as primary
      final selectedAddressRef = _db
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc(addressId);
      batch.update(selectedAddressRef, {'isDefault': true, 'isPrimary': true});

      // Get selected address data to update user document
      final selectedAddressDoc = await selectedAddressRef.get();
      if (selectedAddressDoc.exists) {
        final addressData = selectedAddressDoc.data() as Map<String, dynamic>;
        final userRef = _db.collection('users').doc(userId);
        batch.update(userRef, {
          'primaryAddressId': addressId,
          'serviceDistrict': addressData['district'] ?? '',
          'serviceState': addressData['state'] ?? '',
        });
        
        // Cache primary address locally
        final area = addressData['landmark']?.toString().isNotEmpty == true 
            ? addressData['landmark'] 
            : addressData['city'] ?? '';
        await AddressCacheService.cachePrimaryAddress(
          addressId: addressId,
          district: addressData['district'] ?? '',
          area: area,
        );
      }

      await batch.commit();
      debugPrint('✅ [Address] Primary address updated successfully');
      
      // Clear location cache after setting primary address
      categoryService.clearLocationCache();
    } catch (e) {
      debugPrint('❌ [Address] setPrimaryAddress failed: $e');
      rethrow;
    }
  }

  /// Stream primary address
  Stream<Address?> streamPrimaryAddress(String userId) {
    if (userId.isEmpty) {
      debugPrint('[PATH GUARD] blocked empty id in streamPrimaryAddress');
      return Stream.value(null);
    }
    return _db
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .where('isPrimary', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return Address.fromFirestore(snapshot.docs.first);
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');
      await user.getIdToken(true);
      
      
      final callable = FunctionsService.instance.httpsCallable('updateUserProfile');
      await callable.call({'selectedAddressId': addressId});
      debugPrint('✅ [Address] Selected address updated via callable');
      
      categoryService.clearLocationCache();
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
      final doc = await _db.collection('users').doc(userId).get();
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
