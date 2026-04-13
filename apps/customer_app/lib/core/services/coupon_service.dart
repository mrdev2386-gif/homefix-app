import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coupon.dart';

class CouponService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Coupon>> getActiveCoupons() {
    return _db
        .collection('coupons')
        .where('isActive', isEqualTo: true)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Coupon.fromFirestore(doc)).toList());
  }

  Future<Coupon?> validateCoupon(String code, double orderValue) async {
    final snapshot = await _db
        .collection('coupons')
        .where('code', isEqualTo: code)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final coupon = Coupon.fromFirestore(snapshot.docs.first);
    if (coupon.expiresAt != null && coupon.expiresAt!.isBefore(DateTime.now())) return null;
    if (orderValue < coupon.minOrderValue) return null;

    return coupon;
  }

  // SECURITY: Coupon creation disabled from client - must be done via admin panel or Cloud Functions
  Future<void> seedCoupons() async {
    throw Exception('Coupon creation is disabled from client for security. Use admin panel or Cloud Functions.');
  }
}
