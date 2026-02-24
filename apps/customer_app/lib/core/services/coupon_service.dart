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

  // Seed initial coupons
  Future<void> seedCoupons() async {
    final snapshot = await _db.collection('coupons').limit(1).get();
    if (snapshot.docs.isEmpty) {
      final List<Map<String, dynamic>> initialCoupons = [
        {
          'code': 'WELCOME100',
          'discountType': 'flat',
          'value': 100.0,
          'minOrderValue': 400.0,
          'isActive': true,
          'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        },
        {
          'code': 'SAVE20',
          'discountType': 'percent',
          'value': 20.0,
          'minOrderValue': 200.0,
          'isActive': true,
          'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        },
      ];
      for (var coupon in initialCoupons) {
        await _db.collection('coupons').add(coupon);
      }
    }
  }
}
