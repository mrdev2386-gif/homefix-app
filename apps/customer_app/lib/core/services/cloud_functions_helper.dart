import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CloudFunctionsHelper {
  static Future<dynamic> callFunction(String name, Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User not authenticated');
    }

    await user.getIdToken(true);

    final callable = FirebaseFunctions.instance.httpsCallable(name);
    final result = await callable.call(data);

    return result.data;
  }
}
