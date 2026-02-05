import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> uploadTechnicianDoc({
    required String userId,
    required dynamic file, // Use dynamic to avoid dart:io dependency on web
    required String docType,
  }) async {
    if (kIsWeb) return null; // putFile is not supported on web
    
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_file';
      final Reference ref = _storage.ref().child('technician_docs').child(userId).child(docType).child(fileName);
      
      // We cast to dynamic to avoid compile error but it will only run on mobile where it is a File
      final UploadTask uploadTask = ref.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      
      if (snapshot.state == TaskState.success) {
        return await ref.getDownloadURL();
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading document: $e');
      return null;
    }
  }

  Future<String?> uploadProfilePhoto({
    required String userId,
    required dynamic file,
  }) async {
    if (kIsWeb) return null;

    try {
      final String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child('users').child(userId).child('profile').child(fileName);
      
      final UploadTask uploadTask = ref.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      
      if (snapshot.state == TaskState.success) {
        return await ref.getDownloadURL();
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading profile photo: $e');
      return null;
    }
  }
}
