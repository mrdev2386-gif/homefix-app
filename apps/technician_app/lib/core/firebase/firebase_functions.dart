import 'package:cloud_functions/cloud_functions.dart';

/// Centralized Firebase Functions Service
/// 
/// CRITICAL: Single source of truth for all Cloud Functions calls
/// - Region: asia-south1 (Mumbai)
/// - All httpsCallable calls MUST use this instance
/// - NO other FirebaseFunctions instances should be created
class FirebaseFunctionsService {
  static final FirebaseFunctions instance =
      FirebaseFunctions.instanceFor(region: 'asia-south1');
}
