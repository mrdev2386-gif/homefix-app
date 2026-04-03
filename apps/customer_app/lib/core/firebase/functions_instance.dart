import 'package:cloud_functions/cloud_functions.dart';

/// CRITICAL: Single global Firebase Functions instance
/// DO NOT create multiple instances - always use FunctionsService.instance
class FunctionsService {
  static final FirebaseFunctions instance = FirebaseFunctions.instanceFor(
    region: 'asia-south1',
  );
}
