// ADD TO lib/core/services/functions_service.dart

/// Verify technician bank account using Razorpay Penny Drop
Future<Map<String, dynamic>> verifyBankAccount({
  required String accountHolderName,
  required String accountNumber,
  required String ifscCode,
  required String bankName,
}) async {
  try {
    AppLogger.network(
      'Razorpay penny drop verification triggered',
      data: {'bankName': bankName, 'ifscCode': ifscCode},
    );
    
    HttpsCallable callable = _functions.httpsCallable('verifyTechnicianBankAccount');
    final result = await callable.call({
      'accountHolderName': accountHolderName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode.toUpperCase(),
      'bankName': bankName,
    }).timeout(
      const Duration(seconds: 45),
      onTimeout: () => throw TimeoutException('Bank verification timeout'),
    );
    
    final data = Map<String, dynamic>.from(result.data);
    
    AppLogger.network(
      'Bank verification completed',
      data: {'status': data['status']},
    );
    
    return data;
  } on FirebaseFunctionsException catch (e) {
    AppLogger.error(
      'FUNCTIONS',
      'Bank verification failed',
      data: '${e.code}: ${e.message}',
    );
    rethrow;
  } on TimeoutException catch (e) {
    AppLogger.error('NETWORK', 'Bank verification timeout', data: e);
    rethrow;
  } catch (e) {
    AppLogger.error('FUNCTIONS', 'Unexpected bank verification error', data: e);
    rethrow;
  }
}
